from sqlalchemy import Column, Integer, Float, String, Date, DateTime, Boolean, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base

class Sale(Base):
    __tablename__ = "sales"

    id = Column(Integer, primary_key=True)
    business_id = Column(Integer, ForeignKey("businesses.id"), nullable=False, index=True)
    amount = Column(Float, nullable=False)
    customer_name = Column(String, nullable=True)
    category = Column(String, nullable=True)
    description = Column(String, nullable=True)
    sale_date = Column(Date, nullable=False)
    is_paid = Column(Boolean, default=True)
    created_at = Column(DateTime, server_default=func.now())

    business = relationship("Business", back_populates="sales")
    payments = relationship("Payment", back_populates="sales")

