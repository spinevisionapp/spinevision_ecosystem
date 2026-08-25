import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    PROJECT_NAME: str = "SpineVision Orchestrator"
    PROJECT_ID: str = os.getenv("FIREBASE_PROJECT_ID", "spinevision-6abad")
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY")
    SERVICE_ACCOUNT_PATH: str = "serviceAccount.json"
    STORAGE_BUCKET: str = os.getenv("STORAGE_BUCKET")

settings = Settings()
