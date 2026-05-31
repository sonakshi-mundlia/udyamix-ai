from fastapi import APIRouter, UploadFile, File, Form, Depends, HTTPException
from sqlalchemy.orm import Session
import uuid
import os

from database import get_db
from ..services.chat_service import (
    chat_service,
    chat_service_business,
    fetch_user_chat_history,
    delete_all_user_history
)
from ..services.stt_service import speech_to_text_whisper
from ..services.tts_service import text_to_speech_base64
from ..utils.auth_dependency import (
    get_current_language,
    get_current_user,
    get_current_business
)

from ..models.business_model import Business
from ..models.user_model import User

router = APIRouter(
    prefix="/chat",
    tags=["Chat"]
)

# =====================================================
# 🔹 COMMON INPUT HANDLER (Reusable)
# =====================================================
async def process_input(query: str, file: UploadFile, lang: str):
    if query:
        return query

    if file:
        temp_file = f"temp_{uuid.uuid4().hex}.wav"

        try:
            with open(temp_file, "wb") as f:
                f.write(await file.read())

            text_input = await speech_to_text_whisper(temp_file, lang)

        finally:
            if os.path.exists(temp_file):
                os.remove(temp_file)

        return text_input

    raise HTTPException(status_code=400, detail="No input provided")


# =====================================================
# 🔹 GUEST CHAT
# =====================================================
@router.post("/guest")
async def guest_chat(
        query: str = Form(None),
        file: UploadFile = File(None),
        lang: str = Depends(get_current_language),
):
    text_input = await process_input(query, file, lang)

    answer = await chat_service(
        db=None,
        query=text_input,
        lang=lang
    )

    audio_base64 = await text_to_speech_base64(answer, lang)

    return {
        "query": text_input,
        "answer": answer,
        "audio": audio_base64
    }


# =====================================================
# 🔐 BUSINESS CHAT (Logged-in)
# =====================================================
@router.post("/business")
async def business_chat(
        db: Session = Depends(get_db),
        query: str = Form(None),
        file: UploadFile = File(None),
        business: Business = Depends(get_current_business),
        user: User = Depends(get_current_user),
        lang: str = Depends(get_current_language),
):
    text_input = await process_input(query, file, lang)

    if business.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Unauthorized")

    answer = await chat_service_business(
        db=db,
        business=business,
        user=user,
        query=text_input,
        lang=lang
    )

    audio_base64 = await text_to_speech_base64(answer, lang)

    return {
        "query": text_input,
        "answer": answer,
        "audio": audio_base64
    }


# =====================================================
# 🔹 FETCH FULL CHAT HISTORY
# =====================================================
@router.get("/get-history")
async def get_chat_history(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business),
        user: User = Depends(get_current_user),
):
    if business.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Unauthorized")

    history = fetch_user_chat_history(db, business, user)
    return {"history": history}


# =====================================================
# 🔹 DELETE ALL CHAT HISTORY
# =====================================================
@router.delete("/delete-history")
async def delete_chat_history(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business),
        user: User = Depends(get_current_user),
):
    if business.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Unauthorized")

    delete_all_user_history(db, business, user)
    return {"detail": "All chat history deleted successfully"}