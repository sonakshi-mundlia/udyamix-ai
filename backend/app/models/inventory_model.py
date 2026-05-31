from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class Inventory(Base):
    __tablename__ = "inventories"

    id = Column(Integer, primary_key=True, index=True)
    business_id = Column(Integer, ForeignKey("businesses.id"))
    product_name = Column(String, nullable=False)
    brand = Column(String, nullable=True)
    quantity = Column(Float, nullable=False)
    unit = Column(String, nullable=False)
    stock_quantity = Column(Integer, nullable=False, default=0)
    price_per_unit = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    business = relationship("Business", back_populates="inventories")