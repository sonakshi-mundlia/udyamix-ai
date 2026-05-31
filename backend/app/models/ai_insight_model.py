from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base

class AIInsight(Base):
    __tablename__ = "ai_insights"

    id = Column(Integer, primary_key=True)
    business_id = Column(Integer, ForeignKey("businesses.id"), nullable=False, index=True)
    insight_type = Column(String, nullable=False)
    title = Column(String, nullable=False)
    detail = Column(String, nullable=True)
    score = Column(Float, nullable=True)
    extra_data = Column(JSON, nullable=True)
    expanded_detail = Column(JSON, nullable=True)
    language = Column(String, default="en", index=True)
    created_at = Column(DateTime, server_default=func.now())

    business = relationship("Business", back_populates="ai_insights")
