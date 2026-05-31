from sqlalchemy import Column, Integer, Float, Date, DateTime, ForeignKey, String
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base

class Profit(Base):
    __tablename__ = "profits"

    id = Column(Integer, primary_key=True)
    business_id = Column(Integer, ForeignKey("businesses.id"), nullable=False, index=True)
    total_sales = Column(Float, nullable=False)
    total_expenses = Column(Float, nullable=False)
    profit_amount = Column(Float, nullable=True)
    loss_amount = Column(Float, nullable=True)
    status = Column(String, nullable=False)
    period_date = Column(Date, nullable=False)
    created_at = Column(DateTime, server_default=func.now())

    business = relationship("Business", back_populates="profits")
