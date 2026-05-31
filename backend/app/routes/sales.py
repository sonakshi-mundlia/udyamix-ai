from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from ..schemas.sales_schema import SaleCreate, SaleResponse
from ..models.business_model import Business
from ..services.sales_service import create_sale, get_sales, get_paid_sales, get_unpaid_sales, get_sales_summary
from ..utils.auth_dependency import get_current_business

router = APIRouter(prefix="/sales", tags=["Sales"])

@router.post("/", response_model=SaleResponse)
def add_sale(
        data: SaleCreate,
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """
    Add a sale for the selected business
    """
    return create_sale(db, business, data)


@router.get("/record", response_model=List[SaleResponse])
def list_sales(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """
    Get all sales of selected business
    """
    return get_sales(db, business)

@router.get("/paid", response_model=List[SaleResponse])
def paid_sales(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """Get all paid sales"""
    return get_paid_sales(db, business)


@router.get("/unpaid", response_model=List[SaleResponse])
def unpaid_sales(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """Get all unpaid sales"""
    return get_unpaid_sales(db, business)


@router.get("/summary")
def sales_summary(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """Get sales summary split by paid/unpaid"""
    return get_sales_summary(db, business)

