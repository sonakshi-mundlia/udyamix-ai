from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base
from app.routes import ai_insight, dashboard_background, auth_routes, business, business_history, cash_flow, chat, guest_chat, dashboard, document, expenses, inventory, ocr_result, payment, profit, sales

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Multi-Business Auth Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_routes.router, tags=["Auth"])
app.include_router(ai_insight.router, tags=["AI Insights"])
app.include_router(dashboard.router, tags=["Dashboard"])
app.include_router(dashboard_background.router, tags=["Dashboard-background"])
app.include_router(business.router, tags=["Business"])
app.include_router(business_history.router, tags=["Business History"])
app.include_router(cash_flow.router, tags=["Cash Flow"])
app.include_router(chat.router, tags=["Chat"])
app.include_router(guest_chat.router, tags=["Guest-Chat"])
app.include_router(dashboard.router, tags=["Dashboard AI"])
app.include_router(document.router, tags=["Documents"])
app.include_router(expenses.router, tags=["Expenses"])
app.include_router(inventory.router, tags=["Inventory"])
app.include_router(ocr_result.router, tags=["OCR"])
app.include_router(payment.router, tags=["Payments"])
app.include_router(profit.router, tags=["Profit"])
app.include_router(sales.router, tags=["Sales"])