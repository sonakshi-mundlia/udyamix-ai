from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey, Date, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base

class Expense(Base):
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True)
    business_id = Column(Integer, ForeignKey("businesses.id"), nullable=False, index=True)
    category = Column(String)
    vendor_name = Column(String, nullable=True)
    amount = Column(Float)
    description = Column(String, nullable=True)
    expense_date = Column(Date, nullable=False)
    is_paid = Column(Boolean, default=True)
    created_at = Column(DateTime, server_default=func.now())

    business = relationship("Business", back_populates="expenses")
    payments = relationship("Payment", back_populates="expenses")

