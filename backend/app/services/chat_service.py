import os
import httpx
from dotenv import load_dotenv
from sqlalchemy import text
from datetime import datetime, timedelta

from ..models.business_model import Business
from ..models.user_model import User

load_dotenv()

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")

# ----------------------------
# Language mapping
# ----------------------------
LANGUAGE_MAP = {
    "en": "English",
    "hi": "Hindi",
    "ta": "Tamil",
    "te": "Telugu",
}

# =====================================================
# 🔹 GUEST CHAT
# =====================================================
async def chat_service(db, query: str, lang: str = "en"):

    language_name = LANGUAGE_MAP.get(lang, "English")

    context = "No relevant context found."

    # Simple RAG (no fake embedding)
    if db is not None:
        result = db.execute(
            text("""
            SELECT content
            FROM documents
            LIMIT 5
            """)
        )
        context_docs = [row[0] for row in result]
        if context_docs:
            context = "\n".join(context_docs)[:2000]

    # Prompt
    messages = [
        {
            "role": "system",
            "content": f"""
You are an expert AI assistant.

- Respond ONLY in {language_name}
- Use context if available
- Be concise and helpful
"""
        },
        {
            "role": "user",
            "content": f"Question:\n{query}\n\nContext:\n{context}"
        }
    ]

    async with httpx.AsyncClient(timeout=60) as client:
        response = await client.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": "openai/gpt-4o-mini",
                "messages": messages,
                "temperature": 0.3,
                "max_tokens": 500,
            }
        )

    if response.status_code != 200:
        return "AI service is temporarily unavailable."

    data = response.json()
    return data.get("choices", [{}])[0].get("message", {}).get("content", "Error occurred")


# =====================================================
# 🔹 BUSINESS CHAT (Logged-in)
# =====================================================
async def chat_service_business(
        db,
        business: Business,
        user: User,
        query: str,
        lang: str = "en"
):
    # -------------------------
    # 1️⃣ Delete chats older than 15 days (auto cleanup)
    # -------------------------
    cutoff = datetime.utcnow() - timedelta(days=15)
    db.execute(
        text("""
        DELETE FROM chat_history
        WHERE business_id = :business_id
        AND user_id = :user_id
        AND created_at < :cutoff
        """),
        {"business_id": business.id, "user_id": user.id, "cutoff": cutoff}
    )
    db.commit()

    # -------------------------
    # 2️⃣ Fetch full chat history (for context)
    # -------------------------
    history_rows = db.execute(
        text("""
        SELECT message, response
        FROM chat_history
        WHERE business_id = :business_id
        AND user_id = :user_id
        ORDER BY created_at ASC
        """),
        {"business_id": business.id, "user_id": user.id}
    ).fetchall()

    history_messages = []
    for msg, res in history_rows:
        history_messages.append({"role": "user", "content": msg})
        history_messages.append({"role": "assistant", "content": res})

    # -------------------------
    # 3️⃣ Business-specific context
    # -------------------------
    context = "No relevant context found."
    result = db.execute(
        text("""
        SELECT content
        FROM documents
        WHERE business_id = :business_id
        LIMIT 3
        """),
        {"business_id": business.id}
    )
    context_docs = [row[0] for row in result]
    if context_docs:
        context = "\n".join(context_docs)[:2000]

    language_name = LANGUAGE_MAP.get(lang, "English")

    # -------------------------
    # 4️⃣ Build messages for AI
    # -------------------------
    messages = [
        {
            "role": "system",
            "content": f"""
You are an expert AI assistant for this business.

- Respond ONLY in {language_name}
- Use chat history if useful
- Use business context
- Be practical and concise
"""
        }
    ]

    messages += history_messages

    messages.append({
        "role": "user",
        "content": f"Question:\n{query}\n\nBusiness Context:\n{context}"
    })

    # -------------------------
    # 5️⃣ Call AI
    # -------------------------
    async with httpx.AsyncClient(timeout=60) as client:
        response = await client.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": "openai/gpt-4o-mini",
                "messages": messages,
                "temperature": 0.3,
                "max_tokens": 500,
            }
        )

    if response.status_code != 200:
        return "AI service is temporarily unavailable."

    data = response.json()
    answer = data.get("choices", [{}])[0].get("message", {}).get("content", "Error occurred")

    # -------------------------
    # 6️⃣ Save chat
    # -------------------------
    db.execute(
        text("""
        INSERT INTO chat_history (user_id, business_id, message, response, created_at)
        VALUES (:user_id, :business_id, :message, :response, :created_at)
        """),
        {
            "user_id": user.id,
            "business_id": business.id,
            "message": query,
            "response": answer,
            "created_at": datetime.utcnow()
        }
    )
    db.commit()

    return answer


# =====================================================
# 🔹 FETCH FULL CHAT HISTORY
# =====================================================
def fetch_user_chat_history(db, business: Business, user: User):
    rows = db.execute(
        text("""
        SELECT message, response, created_at
        FROM chat_history
        WHERE business_id = :business_id
        AND user_id = :user_id
        ORDER BY created_at ASC
        """),
        {"business_id": business.id, "user_id": user.id}
    ).fetchall()

    return [{"message": msg, "response": res, "created_at": created_at} for msg, res, created_at in rows]


# =====================================================
# 🔹 DELETE ALL CHAT HISTORY (User-triggered)
# =====================================================
def delete_all_user_history(db, business: Business, user: User):
    db.execute(
        text("""
        DELETE FROM chat_history
        WHERE business_id = :business_id
        AND user_id = :user_id
        """),
        {"business_id": business.id, "user_id": user.id}
    )
    db.commit()