import logging
from sqlalchemy.orm import Session
from sqlalchemy import func, case, cast, Date
from datetime import datetime, timedelta

from ..models.sales_model import Sale
from ..models.expense_model import Expense
from ..models.business_model import Business
from ..schemas.dashboard_schema import DashboardResponse

logger = logging.getLogger("dashboard_service")
logger.setLevel(logging.INFO)


def calculate_dashboard(
        db: Session,
        business: Business,
        start_date: datetime,
        end_date: datetime,
        trend_days: int = 7
) -> DashboardResponse:
    """
    Calculate dashboard metrics for a given business_id
    between start_date and end_date.
    """

    # ---------------- SALES ----------------
    sales_query = db.query(
        func.coalesce(func.sum(Sale.amount), 0.0).label("total_sales"),

        func.coalesce(
            func.sum(
                case(
                    (Sale.is_paid == True, Sale.amount),
                    else_=0.0
                )
            ),
            0.0
        ).label("paid_sales"),

        func.coalesce(
            func.sum(
                case(
                    (Sale.is_paid == False, Sale.amount),
                    else_=0.0
                )
            ),
            0.0
        ).label("unpaid_sales"),

    ).filter(
        Sale.business_id == business.id,
        cast(Sale.sale_date, Date) >= start_date.date(),
        cast(Sale.sale_date, Date) < end_date.date()
    ).one()

    total_sales = float(sales_query.total_sales or 0.0)
    paid_sales = float(sales_query.paid_sales or 0.0)
    unpaid_sales = float(sales_query.unpaid_sales or 0.0)

    # ---------------- EXPENSES ----------------
    expenses_query = db.query(
        func.coalesce(
            func.sum(Expense.amount),
            0.0
        ).label("total_expenses"),

        func.coalesce(
            func.sum(
                case(
                    (Expense.is_paid == True, Expense.amount),
                    else_=0.0
                )
            ),
            0.0
        ).label("paid_expenses"),

    ).filter(
        Expense.business_id == business.id,
        cast(Expense.expense_date, Date) >= start_date.date(),
        cast(Expense.expense_date, Date) < end_date.date()
    ).one()

    total_expenses = float(expenses_query.total_expenses or 0.0)
    paid_expenses = float(expenses_query.paid_expenses or 0.0)

    # ---------------- PROFIT / LOSS / CASHFLOW ----------------
    profit = max(paid_sales - paid_expenses, 0.0)

    loss = max(paid_expenses - paid_sales, 0.0)

    cashflow = (
            paid_sales
            - paid_expenses
            + unpaid_sales
    )

    # ---------------- TRENDS ----------------
    trend_start = end_date - timedelta(days=trend_days)

    sales_trend_query = db.query(
        cast(Sale.sale_date, Date).label("date"),

        func.coalesce(
            func.sum(
                case(
                    (Sale.is_paid == True, Sale.amount),
                    else_=0.0
                )
            ),
            0.0
        ).label("total")

    ).filter(
        Sale.business_id == business.id,
        cast(Sale.sale_date, Date) >= trend_start.date(),
        cast(Sale.sale_date, Date) < end_date.date()

    ).group_by(
        cast(Sale.sale_date, Date)
    ).all()

    expenses_trend_query = db.query(
        cast(Expense.expense_date, Date).label("date"),

        func.coalesce(
            func.sum(
                case(
                    (Expense.is_paid == True, Expense.amount),
                    else_=0.0
                )
            ),
            0.0
        ).label("total")

    ).filter(
        Expense.business_id == business.id,
        cast(Expense.expense_date, Date) >= trend_start.date(),
        cast(Expense.expense_date, Date) < end_date.date()

    ).group_by(
        cast(Expense.expense_date, Date)
    ).all()

    sales_trend_map = {
        row.date: float(row.total or 0.0)
        for row in sales_trend_query
    }

    expenses_trend_map = {
        row.date: float(row.total or 0.0)
        for row in expenses_trend_query
    }

    sales_trend = [
        sales_trend_map.get(
            trend_start.date() + timedelta(days=i),
            0.0
        )
        for i in range(trend_days)
    ]

    expenses_trend = [
        expenses_trend_map.get(
            trend_start.date() + timedelta(days=i),
            0.0
        )
        for i in range(trend_days)
    ]

    # ---------------- EXPENSE CATEGORIES ----------------
    try:
        category_query = db.query(
            Expense.category,
            func.coalesce(func.sum(Expense.amount), 0.0)

        ).filter(
            Expense.business_id == business.id,
            cast(Expense.expense_date, Date) >= start_date.date(),
            cast(Expense.expense_date, Date) < end_date.date()

        ).group_by(
            Expense.category
        ).all()

        expense_categories = {
            cat if cat else "Other": float(amount or 0.0)
            for cat, amount in category_query
        }

    except Exception as e:
        logger.warning(f"Error fetching expense categories: {e}")
        expense_categories = {}

    return DashboardResponse(
        sales=total_sales,
        expenses=total_expenses,
        profit=profit,
        loss=loss,
        cashFlow=cashflow,
        pendingCOD=unpaid_sales,
        receivables=unpaid_sales,
        salesTrend=sales_trend,
        expensesTrend=expenses_trend,
        expenseCategories=expense_categories,
        date=end_date,
        startDate=start_date
    )


def get_dashboard_data(
        db: Session,
        business: Business,
        date: str | datetime | None = None
):
    """
    Get dashboard for:
    - Daily
    - Weekly
    - Monthly
    - Total
    """

    # ---------------- REFERENCE DATE ----------------
    if isinstance(date, str):
        try:
            ref_date = datetime.strptime(date, "%Y-%m-%d")
        except ValueError:
            ref_date = datetime.utcnow()

    elif isinstance(date, datetime):
        ref_date = date

    else:
        ref_date = datetime.utcnow()

    # =========================================================
    # DAILY
    # =========================================================
    start_day = datetime(
        ref_date.year,
        ref_date.month,
        ref_date.day
    )

    end_day = start_day + timedelta(days=1)

    daily = calculate_dashboard(
        db,
        business,
        start_day,
        end_day,
        trend_days=1
    )

    daily.date = end_day
    daily.startDate = start_day

    # =========================================================
    # WEEKLY
    # =========================================================
    start_week = start_day - timedelta(days=start_day.weekday())

    end_week = start_week + timedelta(days=7)

    weekly = calculate_dashboard(
        db,
        business,
        start_week,
        end_week,
        trend_days=7
    )

    weekly.date = end_week
    weekly.startDate = start_week

    # =========================================================
    # MONTHLY
    # =========================================================
    start_month = datetime(
        ref_date.year,
        ref_date.month,
        1
    )

    if ref_date.month == 12:
        next_month = datetime(ref_date.year + 1, 1, 1)
    else:
        next_month = datetime(ref_date.year, ref_date.month + 1, 1)

    monthly = calculate_dashboard(
        db,
        business,
        start_month,
        next_month,
        trend_days=30
    )

    monthly.date = next_month
    monthly.startDate = start_month

    # =========================================================
    # TOTAL / LIFETIME
    # =========================================================
    start_total = datetime(2000, 1, 1)

    end_total = datetime.utcnow() + timedelta(days=1)

    total = calculate_dashboard(
        db,
        business,
        start_total,
        end_total,
        trend_days=12
    )

    total.date = end_total
    total.startDate = start_total

    # =========================================================
    # RESPONSE
    # =========================================================
    return {
        "daily": daily,
        "weekly": weekly,
        "monthly": monthly,
        "total": total,

        "hasSales": (
                daily.sales > 0 or
                weekly.sales > 0 or
                monthly.sales > 0 or
                total.sales > 0
        ),

        "hasExpenses": (
                daily.expenses > 0 or
                weekly.expenses > 0 or
                monthly.expenses > 0 or
                total.expenses > 0
        ),
    }