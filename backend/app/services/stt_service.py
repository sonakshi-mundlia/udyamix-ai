import asyncio
import whisper

model = whisper.load_model("base")


def _speech_to_text_sync(audio_path: str, lang: str = None):
    result = model.transcribe(
        audio_path,
        language=lang,
        temperature=0
    )
    return result["text"]


async def speech_to_text_whisper(audio_path: str, lang: str = None):
    return await asyncio.to_thread(
        _speech_to_text_sync,
        audio_path,
        lang
    )