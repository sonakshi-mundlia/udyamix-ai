import random
from sqlalchemy.orm import Session
from ..models.inventory_model import Inventory
from ..models.business_model import Business
from ..schemas.dashboard_background_schema import (
    DashboardBackgroundResponse,
    SuggestedProduct
)
from ..utils.translation import translate_text  # <-- you can implement a simple translation util


# --------------------- BUSINESS TYPE DETECTION ---------------------

def detect_business_type(name: str):
    name = name.lower()
    if any(x in name for x in ["grocery", "kirana", "mart", "store", "provision"]):
        return "grocery"
    elif any(x in name for x in ["medical", "pharmacy", "chemist", "clinic"]):
        return "medical"
    elif any(x in name for x in ["electronic", "mobile", "laptop", "tech"]):
        return "electronics"
    elif any(x in name for x in ["cloth", "fashion", "boutique", "garment"]):
        return "clothing"
    elif any(x in name for x in ["hardware", "tools", "construction"]):
        return "hardware"
    elif any(x in name for x in ["restaurant", "cafe", "food", "dhaba", "hotel"]):
        return "restaurant"
    elif any(x in name for x in ["stationery", "book", "school"]):
        return "stationery"
    elif any(x in name for x in ["cosmetic", "beauty", "salon"]):
        return "cosmetics"
    elif any(x in name for x in ["bakery", "cake", "sweet"]):
        return "bakery"
    elif any(x in name for x in ["furniture", "wood", "decor"]):
        return "furniture"
    else:
        return "general"


# --------------------- SUGGESTIONS ---------------------

def get_suggestions_by_type(business_type: str):
    data = {
        "grocery": [
            {"product_name": "Rice", "brand": "India Gate"},
            {"product_name": "Wheat Flour", "brand": "Aashirvaad"},
            {"product_name": "Sugar", "brand": "Madhur"},
            {"product_name": "Salt", "brand": "Tata"},
            {"product_name": "Oil", "brand": "Fortune"},
        ],
        "medical": [
            {"product_name": "Paracetamol", "brand": "Crocin"},
            {"product_name": "Bandage", "brand": "Hansaplast"},
            {"product_name": "Sanitizer", "brand": "Dettol"},
            {"product_name": "Cough Syrup", "brand": "Benadryl"},
        ],
        "electronics": [
            {"product_name": "USB Cable", "brand": "Mi"},
            {"product_name": "Power Bank", "brand": "Ambrane"},
            {"product_name": "Headphones", "brand": "Boat"},
        ],
        "general": [
            {"product_name": "Soap", "brand": "Lux"},
            {"product_name": "Biscuits", "brand": "Britannia"},
        ]
    }
    return data.get(business_type, data["general"])


# --------------------- MAIN SERVICE ---------------------

async def analyze_business(db: Session, business: Business, desired_count: int = 6, lang: str = "en"):
    # -------- GET BUSINESS --------
    business = db.query(Business).filter(Business.id == business.id).first()
    if not business:
        raise ValueError("Business not found")

    # -------- USER INVENTORY --------
    user_inventory = db.query(Inventory).filter(
        Inventory.business_id == business.id
    ).all()

    user_items = {
        i.product_name.strip().lower()
        for i in user_inventory
        if i.product_name
    }

    # -------- BUSINESS TYPE --------
    business_type = detect_business_type(business.business_name)

    # -------- SUGGESTIONS --------
    if len(user_items) >= 1:
        final_suggestions = []
    else:
        suggestions = get_suggestions_by_type(business_type)
        random.shuffle(suggestions)
        final_suggestions = suggestions[:desired_count]

    # -------- TRANSLATE SUGGESTIONS IF LANG != EN --------
    if lang != "en":
        for s in final_suggestions:
            s["product_name"] = translate_text(s["product_name"], lang)
            s["brand"] = translate_text(s["brand"], lang)

    # -------- RESPONSE --------
    return DashboardBackgroundResponse(
        success=True,
        data=[SuggestedProduct(**s) for s in final_suggestions],
        ai_error=False
    )
