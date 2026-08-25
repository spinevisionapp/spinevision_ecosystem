import logging
import google.generativeai as genai
from .config import settings

logger = logging.getLogger("spinevision.ai")

def initialize_ai():
    if not settings.GEMINI_API_KEY:
        logger.error("GEMINI_API_KEY not found in environment.")
        return None
    genai.configure(api_key=settings.GEMINI_API_KEY)
    return genai.GenerativeModel('gemini-2.0-flash')

model = initialize_ai()
