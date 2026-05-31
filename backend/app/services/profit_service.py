from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date

from ..models.profit_model import Profit
from ..models.sales_model import Sale
from ..models.expense_model import Expense
from ..models.business_model import Business
from ..schemas.profit_schema import ProfitResponse

# ----------------------------
# Calculate and store profit
# ----------------------------
def calculate_and_store_profit(db: Session, business: Business) -> ProfitResponse:
    """
    Calculate total sales, total expenses, and profit/loss for a business.
    Stores the record in the Profit table and returns a Pydantic response.
    """

    # 1️⃣ Calculate totals using UUID business_id
    total_sales = db.query(func.coalesce(func.sum(Sale.amount), 0)) \
        .filter(Sale.business_id == business.id).scalar()

    total_expenses = db.query(func.coalesce(func.sum(Expense.amount), 0)) \
        .filter(Expense.business_id == business.id).scalar()

    # 2️⃣ Compute net profit/loss
    net = total_sales - total_expenses

    if net > 0:
        profit_amount = net
        loss_amount = None
        status = "profit"
    elif net < 0:
        profit_amount = None
        loss_amount = abs(net)
        status = "loss"
    else:
        profit_amount = 0.0
        loss_amount = None
        status = "break_even"

    # 3️⃣ Store in DB
    profit_record = Profit(
        business_id=business.id,
        total_sales=total_sales,
        total_expenses=total_expenses,
        profit_amount=profit_amount,
        loss_amount=loss_amount,
        status=status,
        period_date=date.today()
    )

    db.add(profit_record)
    db.commit()
    db.refresh(profit_record)

    # 4️⃣ Return structured Pydantic schema
    return ProfitResponse.from_orm(profit_record)

