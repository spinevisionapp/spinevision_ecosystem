import os
import logging
import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud import storage
from google.oauth2 import service_account
from .config import settings

logger = logging.getLogger("spinevision.firebase")

def initialize_firebase():
    if not firebase_admin._apps:
        if os.path.exists(settings.SERVICE_ACCOUNT_PATH):
            cred = credentials.Certificate(settings.SERVICE_ACCOUNT_PATH)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase initialized with service account.")
        else:
            logger.warning("serviceAccount.json not found. Using Application Default Credentials.")
            firebase_admin.initialize_app()
    return firestore.client()

def get_storage_client():
    if os.path.exists(settings.SERVICE_ACCOUNT_PATH):
        creds = service_account.Credentials.from_service_account_file(settings.SERVICE_ACCOUNT_PATH)
        return storage.Client(credentials=creds, project=settings.PROJECT_ID)
    return storage.Client(project=settings.PROJECT_ID)

db = initialize_firebase()
storage_client = get_storage_client()
