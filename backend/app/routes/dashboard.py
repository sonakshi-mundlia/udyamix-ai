# app/routers/dashboard.py

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime
from database import get_db
from ..models.business_model import Business
from ..services.dashboard_service import get_dashboard_data
from ..utils.auth_dependency import get_current_business

router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"]
)


def dashboard_response_to_dict(dashboard):
    """Convert DashboardResponse object to dict compatible with Flutter FullDashboardModel."""
    return {
        "sales": dashboard.sales,
        "expenses": dashboard.expenses,
        "cashFlow": dashboard.cashFlow,
        "profit": dashboard.profit,
        "loss": dashboard.loss,
        "pendingCOD": dashboard.pendingCOD,
        "receivables": dashboard.receivables,
        "salesTrend": dashboard.salesTrend,
        "expensesTrend": dashboard.expensesTrend,
        "expenseCategories": dashboard.expenseCategories,
        "date": dashboard.date.isoformat(),
        "startDate": dashboard.startDate.isoformat()
    }


@router.get("/metrics")
def dashboard(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business),
        date: str | None = Query(None, description="Optional date in YYYY-MM-DD format")
):
    """
    Get full dashboard (daily, weekly, monthly)
    Optional query param `date` filters the dashboard for that date.
    """
    try:
        dashboard_date: datetime | None = None

        # ✅ Parse date string safely if provided
        if date:
            try:
                dashboard_date = datetime.fromisoformat(date)
            except ValueError:
                raise HTTPException(
                    status_code=400,
                    detail="Invalid date format. Use YYYY-MM-DD or ISO format."
                )

        # ✅ Call the service with a datetime object
        dashboard_data = get_dashboard_data(
            db,
            business,
            date=dashboard_date
        )

        daily = dashboard_data["daily"]
        weekly = dashboard_data["weekly"]
        monthly = dashboard_data["monthly"]
        total = dashboard_data["total"]

        return {
            "success": True,
            "data": {
                "business_id": business.business_id,
                "business_name": business.business_name,

                "daily": dashboard_response_to_dict(daily),
                "weekly": dashboard_response_to_dict(weekly),
                "monthly": dashboard_response_to_dict(monthly),
                "total": total,

                "hasSales": dashboard_data["hasSales"],
                "hasExpenses": dashboard_data["hasExpenses"],
            }
        }


    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error fetching dashboard data: {str(e)}"
        )
