from sqlalchemy import Column, Integer, Float, Date, DateTime, ForeignKey, String
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base

class CashFlow(Base):
    __tablename__ = "cashflows"

    id = Column(Integer, primary_key=True)
    business_id = Column(Integer, ForeignKey("businesses.id"), nullable=False, index=True)
    cash_in = Column(Float, nullable=False)
    cash_out = Column(Float, nullable=False)
    net_cashflow = Column(Float, nullable=False)
    status = Column(String, nullable=False)
    period_date = Column(Date, nullable=False)
    created_at = Column(DateTime, server_default=func.now())

    business = relationship("Business", back_populates="cashflows")
