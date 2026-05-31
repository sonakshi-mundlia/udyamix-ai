from sqlalchemy.sql import func
from datetime import date
from sqlalchemy.orm import Session
from typing import List, Dict
from ..models.expense_model import Expense
from ..models.business_model import Business
from ..schemas.expense_schema import ExpenseCreate, ExpenseResponse

# ----------------------------
# Create an expense
# ----------------------------
def create_expense(
        db: Session,
        business: Business,
        data: ExpenseCreate
) -> ExpenseResponse:
    """
    Create an expense for the selected business.
    """
    expense = Expense(
        business_id=business.id,
        amount=data.amount,
        category=data.category,
        vendor_name=data.vendor_name,
        description=data.description,
        expense_date=data.expense_date,
        is_paid=data.is_paid
    )

    db.add(expense)
    db.commit()
    db.refresh(expense)

    return ExpenseResponse.from_orm(expense)


# ----------------------------
# Get all expenses
# ----------------------------
def get_expenses(db: Session, business: Business) -> List[ExpenseResponse]:
    expenses = (
        db.query(Expense)
        .filter(Expense.business_id == business.id)
        .order_by(Expense.expense_date.desc())
        .all()
    )
    return [ExpenseResponse.from_orm(e) for e in expenses]


# ----------------------------
# Get paid expenses
# ----------------------------
def get_paid_expenses(db: Session, business: Business) -> List[ExpenseResponse]:
    expenses = (
        db.query(Expense)
        .filter(Expense.business_id == business.id, Expense.is_paid == True)
        .order_by(Expense.expense_date.desc())
        .all()
    )
    return [ExpenseResponse.from_orm(e) for e in expenses]


# ----------------------------
# Get unpaid expenses
# ----------------------------
def get_unpaid_expenses(db: Session, business: Business) -> List[ExpenseResponse]:
    expenses = (
        db.query(Expense)
        .filter(Expense.business_id == business.id, Expense.is_paid == False)
        .order_by(Expense.expense_date.desc())
        .all()
    )
    return [ExpenseResponse.from_orm(e) for e in expenses]


# ----------------------------
# Expense summary (total + paid/unpaid + today)
# ----------------------------
def get_expense_summary(db: Session, business: Business) -> Dict[str, float]:
    # Total expenses
    total_expense = db.query(func.coalesce(func.sum(Expense.amount), 0)) \
        .filter(Expense.business_id == business.id) \
        .scalar()

    # Today's expenses
    today_expense = db.query(func.coalesce(func.sum(Expense.amount), 0)) \
        .filter(Expense.business_id == business.id,
                Expense.expense_date == date.today()) \
        .scalar()

    # Paid expenses
    total_paid = db.query(func.coalesce(func.sum(Expense.amount), 0)) \
        .filter(Expense.business_id == business.id, Expense.is_paid == True) \
        .scalar()

    today_paid = db.query(func.coalesce(func.sum(Expense.amount), 0)) \
        .filter(Expense.business_id == business.id, Expense.is_paid == True,
                Expense.expense_date == date.today()) \
        .scalar()

    # Unpaid expenses
    total_unpaid = db.query(func.coalesce(func.sum(Expense.amount), 0)) \
        .filter(Expense.business_id == business.id, Expense.is_paid == False) \
        .scalar()

    today_unpaid = db.query(func.coalesce(func.sum(Expense.amount), 0)) \
        .filter(Expense.business_id == business.id, Expense.is_paid == False,
                Expense.expense_date == date.today()) \
        .scalar()

    return {
        "total_expense": float(total_expense),
        "today_expense": float(today_expense),
        "total_paid": float(total_paid),
        "today_paid": float(today_paid),
        "total_unpaid": float(total_unpaid),
        "today_unpaid": float(today_unpaid)
    }
