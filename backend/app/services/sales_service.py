from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date
from typing import List, Dict

from ..models.sales_model import Sale
from ..models.business_model import Business
from ..schemas.sales_schema import SaleCreate, SaleResponse

# ----------------------------
# Create Sale
# ----------------------------
def create_sale(db: Session, business: Business, data: SaleCreate) -> SaleResponse:
    """
    Create a sale for the given business_id
    and return a structured Pydantic response.
    """
    sale = Sale(
        business_id=business.id,
        amount=data.amount,
        customer_name=data.customer_name,
        category=data.category,
        description=data.description,
        sale_date=data.sale_date,
        is_paid=data.is_paid
    )

    db.add(sale)
    db.commit()
    db.refresh(sale)

    return SaleResponse.from_orm(sale)


# ----------------------------
# Get all Sales
# ----------------------------
def get_sales(db: Session, business: Business) -> List[SaleResponse]:
    sales = (
        db.query(Sale)
        .filter(Sale.business_id == business.id)
        .order_by(Sale.sale_date.desc())
        .all()
    )
    return [SaleResponse.from_orm(s) for s in sales]


# ----------------------------
# Get Paid Sales
# ----------------------------
def get_paid_sales(db: Session, business: Business) -> List[SaleResponse]:
    sales = (
        db.query(Sale)
        .filter(Sale.business_id == business.id, Sale.is_paid == True)
        .order_by(Sale.sale_date.desc())
        .all()
    )
    return [SaleResponse.from_orm(s) for s in sales]


# ----------------------------
# Get Unpaid Sales
# ----------------------------
def get_unpaid_sales(db: Session, business: Business) -> List[SaleResponse]:
    sales = (
        db.query(Sale)
        .filter(Sale.business_id == business.id, Sale.is_paid == False)
        .order_by(Sale.sale_date.desc())
        .all()
    )
    return [SaleResponse.from_orm(s) for s in sales]


# ----------------------------
# Sales Summary (Total + Paid/Unpaid + Today)
# ----------------------------
def get_sales_summary(db: Session, business: Business) -> Dict[str, float]:
    # Total sales (all)
    total_sales = db.query(func.coalesce(func.sum(Sale.amount), 0)) \
        .filter(Sale.business_id == business.id) \
        .scalar()

    # Today's sales (all)
    today_sales = db.query(func.coalesce(func.sum(Sale.amount), 0)) \
        .filter(Sale.business_id == business.id,
                Sale.sale_date == date.today()) \
        .scalar()

    # Paid sales
    total_paid = db.query(func.coalesce(func.sum(Sale.amount), 0)) \
        .filter(Sale.business_id == business.id, Sale.is_paid == True) \
        .scalar()

    today_paid = db.query(func.coalesce(func.sum(Sale.amount), 0)) \
        .filter(Sale.business_id == business.id, Sale.is_paid == True,
                Sale.sale_date == date.today()) \
        .scalar()

    # Unpaid sales
    total_unpaid = db.query(func.coalesce(func.sum(Sale.amount), 0)) \
        .filter(Sale.business_id == business.id, Sale.is_paid == False) \
        .scalar()

    today_unpaid = db.query(func.coalesce(func.sum(Sale.amount), 0)) \
        .filter(Sale.business_id == business.id, Sale.is_paid == False,
                Sale.sale_date == date.today()) \
        .scalar()

    return {
        "total_sales": float(total_sales),
        "today_sales": float(today_sales),
        "total_paid": float(total_paid),
        "today_paid": float(today_paid),
        "total_unpaid": float(total_unpaid),
        "today_unpaid": float(today_unpaid)
    }



