import logging
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date

from ..models.sales_model import Sale
from ..models.expense_model import Expense
from ..models.cash_flow_model import CashFlow
from ..models.business_model import Business
from ..schemas.cash_flow_schema import CashFlowResponse

logger = logging.getLogger("cash_flow_service")
logger.setLevel(logging.INFO)


def calculate_cashflow(db: Session, business: Business) -> CashFlowResponse:
    """
    Calculate cashflow for a business using business_id.
    Saves a snapshot and returns structured response.
    """

    # ----------------------------
    # Cash IN
    # ----------------------------
    cash_in_total = db.query(
        func.coalesce(func.sum(Sale.amount), 0)
    ).filter(
        Sale.business_id == business.id,
        Sale.is_paid.is_(True)
    ).scalar() or 0

    # ----------------------------
    # Cash OUT
    # ----------------------------
    cash_out_total = db.query(
        func.coalesce(func.sum(Expense.amount), 0)
    ).filter(
        Expense.business_id == business.id,
        Expense.is_paid.is_(True)
    ).scalar() or 0

    # ----------------------------
    # Net cashflow
    # ----------------------------
    net = float(cash_in_total) - float(cash_out_total)

    # ----------------------------
    # Status
    # ----------------------------
    if net > 0:
        status = "positive"
    elif net < 0:
        status = "negative"
    else:
        status = "neutral"

    # ----------------------------
    # Save snapshot
    # ----------------------------
    cashflow = CashFlow(
        business_id=business.id,
        cash_in=float(cash_in_total),
        cash_out=float(cash_out_total),
        net_cashflow=net,
        status=status,
        period_date=date.today()
    )

    try:
        db.add(cashflow)
        db.commit()
        db.refresh(cashflow)


    except Exception as e:
        db.rollback()
        logger.error(f"Cashflow save failed | error={e}")
        raise

    return CashFlowResponse.model_validate(cashflow)


