from sqlalchemy import Column, Integer, String, Float, Date, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base
class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True)

    business_id = Column(Integer, ForeignKey("businesses.id"), index=True, nullable=False)
    sale_id = Column(Integer, ForeignKey("sales.id"), nullable=True, index=True)
    expense_id = Column(Integer, ForeignKey("expenses.id"), nullable=True, index=True)
    amount = Column(Float, nullable=False)
    payment_id = Column(String, unique=True, index=True, nullable=True)
    order_id = Column(String, index=True, nullable=True)
    payment_mode = Column(String, nullable=False)
    status = Column(String, nullable=False)
    direction = Column(String, nullable=False)
    payment_date = Column(Date, nullable=False, index=True)
    created_at = Column(DateTime, server_default=func.now())


    business = relationship("Business", back_populates="payments")
    sales = relationship("Sale", back_populates="payments")
    expenses = relationship("Expense", back_populates="payments")
