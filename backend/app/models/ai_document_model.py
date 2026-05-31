from sqlalchemy import Column, Integer, Text
from pgvector.sqlalchemy import Vector
from database import Base


class Document(Base):
    __tablename__ = "ai_documents"

    id = Column(Integer, primary_key=True, index=True)
    content = Column(Text)
    embedding = Column(Vector(1536))