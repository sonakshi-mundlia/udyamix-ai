from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base

class OCRResult(Base):
    __tablename__ = "ocr_results"

    id = Column(Integer, primary_key=True)
    business_id = Column(Integer, ForeignKey("businesses.id"), nullable=False, index=True)
    document_id = Column(Integer, ForeignKey("documents.id"), nullable=False, index=True)
    detected_type = Column(String)   # sale | expense
    detected_amount = Column(Float, nullable=True)
    detected_party = Column(String, nullable=True)
    detected_category = Column(String, nullable=True)
    detected_date = Column(String, nullable=True)
    raw_text = Column(String)
    confidence = Column(Float)
    created_at = Column(DateTime, server_default=func.now())

    business = relationship("Business", back_populates="ocr_results")
