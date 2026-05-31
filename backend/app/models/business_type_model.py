from sqlalchemy import Column, Integer, String, Text
from database import Base
import json


class BusinessType(Base):
    __tablename__ = "business_types"

    id = Column(Integer, primary_key=True, index=True)

    # Example: "kiryana store", "pharmacy"
    type_name = Column(String, unique=True, nullable=False)

    # AI suggested inventory
    suggested_inventory = Column(Text, nullable=True)

    # --------------------------
    # Helpers
    # --------------------------
    def get_suggested_inventory(self):
        try:
            return json.loads(self.suggested_inventory or "[]")
        except Exception:
            return []

