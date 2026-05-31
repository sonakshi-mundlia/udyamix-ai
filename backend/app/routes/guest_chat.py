from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends
import asyncio
import os
import uuid
from ..services.stt_service import speech_to_text_whisper
from ..services.tts_service import text_to_speech_base64
from ..services.chat_service import chat_service
from ..utils.auth_dependency import get_current_language

router = APIRouter(
    prefix="/guest-chat",
    tags=["Guest-Chat"]
)

@router.post("/")
async def guest_chat(
        query: str = Form(None),
        file: UploadFile = File(None),
        session_id: str = Form(None),
        lang: str = Depends(get_current_language)
):

    # 📝 TEXT INPUT
    if query:
        text_input = query

    # 🎤 VOICE INPUT
    elif file:
        temp_file = f"temp_{uuid.uuid4().hex}.wav"

        try:
            with open(temp_file, "wb") as f:
                f.write(await file.read())

            text_input = await speech_to_text_whisper(temp_file, lang)

        finally:
            if os.path.exists(temp_file):
                os.remove(temp_file)

    else:
        raise HTTPException(status_code=400, detail="No input provided")

    # 🧠 AI RESPONSE (NO DB, NO AUTH)
    answer = await chat_service(None, text_input, lang)

    # 🔊 TTS
    audio_base64 = await text_to_speech_base64(answer, lang)

    # 🆔 Generate session if not provided
    session_id = session_id or str(uuid.uuid4())

    return {
        "session_id": session_id,
        "query": text_input,
        "answer": answer,
        "audio": audio_base64
    }

