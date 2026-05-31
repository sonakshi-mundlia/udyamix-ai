# app/routers/expense_router.py

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from ..schemas.expense_schema import ExpenseCreate, ExpenseResponse
from ..models.business_model import Business
from ..services.expense_service import (
    create_expense,
    get_expenses,
    get_paid_expenses,
    get_unpaid_expenses,
    get_expense_summary
)
from ..utils.auth_dependency import get_current_business

router = APIRouter(prefix="/expenses", tags=["Expenses"])


@router.post("/", response_model=ExpenseResponse)
def add_expense(
        data: ExpenseCreate,
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """
    Add an expense for the selected business
    """
    return create_expense(db, business, data)


@router.get("/record", response_model=List[ExpenseResponse])
def list_expenses(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """
    Get all expenses of selected business
    """
    return get_expenses(db, business)


@router.get("/paid", response_model=List[ExpenseResponse])
def paid_expenses(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """Get all paid expenses"""
    return get_paid_expenses(db, business)


@router.get("/unpaid", response_model=List[ExpenseResponse])
def unpaid_expenses(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """Get all unpaid expenses"""
    return get_unpaid_expenses(db, business)


@router.get("/summary")
def expense_summary(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    """Get expense summary split by paid/unpaid and total/today"""
    return get_expense_summary(db, business)