# config.py
import os

# Directory to save uploaded files inside the app folder
UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "uploads")

# Make sure the folder exists
os.makedirs(UPLOAD_DIR, exist_ok=True)
