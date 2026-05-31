from sqlalchemy import Column, Integer, String, ForeignKey, Boolean
from database import Base
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.dialects.postgresql import JSON
import uuid

class Business(Base):
    __tablename__ = "businesses"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    business_id = Column(UUID(as_uuid=True), unique=True, default=uuid.uuid4)
    business_name = Column(String, nullable=False)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    is_selected = Column(Boolean, default=False, nullable=False)

    suggested_inventory = Column(JSON, nullable=True)

    ai_insights = relationship("AIInsight", back_populates="business")
    documents = relationship("Document", back_populates="business", cascade="all, delete-orphan")
    sales = relationship("Sale", back_populates="business", cascade="all, delete-orphan")
    expenses = relationship("Expense", back_populates="business", cascade="all, delete-orphan")
    inventories = relationship("Inventory", back_populates="business", cascade="all, delete-orphan")
    ocr_results = relationship("OCRResult", back_populates="business", cascade="all, delete-orphan")
    profits = relationship("Profit", back_populates="business", cascade="all, delete-orphan")
    cashflows = relationship("CashFlow", back_populates="business", cascade="all, delete-orphan")
    payments = relationship("Payment", back_populates="business")

    chat_history = relationship("ChatHistory", back_populates="business",cascade="all, delete-orphan")

