from gtts import gTTS
import base64
import uuid
import os
import asyncio

def text_to_speech_sync(text: str, lang: str = "en"):
    filename = f"temp_{uuid.uuid4().hex}.mp3"

    try:
        # Create speech
        tts = gTTS(text=text, lang=lang)
        tts.save(filename)

        # Read as base64
        with open(filename, "rb") as f:
            audio_base64 = base64.b64encode(f.read()).decode()

        return audio_base64

    except Exception as e:
        print("TTS ERROR:", e)
        return None

    finally:
        # ✅ ALWAYS cleanup file
        if os.path.exists(filename):
            os.remove(filename)

async def text_to_speech_base64(text: str, lang: str = "en"):
    return await asyncio.to_thread(text_to_speech_sync, text, lang)