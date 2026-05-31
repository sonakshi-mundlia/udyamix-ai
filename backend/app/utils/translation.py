import requests

def translate_text(text: str, target_lang: str = "en") -> str:
    try:
        if not text:
            return ""

        response = requests.post(
            "https://libretranslate.de/translate",
            data={
                "q": text,
                "source": "auto",
                "target": target_lang,
                "format": "text"
            },
            timeout=5
        )

        return response.json()["translatedText"]

    except Exception as e:
        print("Translation error:", e)
        return text