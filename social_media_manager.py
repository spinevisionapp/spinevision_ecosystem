import os
import json
import logging
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning, module="google._upb._message")

import google.generativeai as genai
from marketing_prompts import SOCIAL_MEDIA_PROMPT
from dotenv import load_dotenv

load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("social_media_manager")

# Configure Gemini
api_key = os.getenv("GEMINI_API_KEY")
if api_key:
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel('gemini-1.5-flash')
else:
    logger.warning("GEMINI_API_KEY not found. Social media generation will use fallback.")
    model = None

def generate_weekly_posts():
    """
    Generates a week's worth of social media posts using Gemini.
    """
    logger.info("Generating weekly social media posts...")
    
    if not model:
        return {
            "Monday": "Fallback Monday post #SpineVision",
            "Tuesday": "Fallback Tuesday post #ProfitVision",
            "Wednesday": "Fallback Wednesday post #BOLO",
            "Thursday": "Fallback Thursday post #AskVisionAI",
            "Friday": "Fallback Friday post #ListingVision",
            "Saturday": "Fallback Saturday post #Sourcing",
            "Sunday": "Fallback Sunday post #VisionHub"
        }

    try:
        response = model.generate_content(
            SOCIAL_MEDIA_PROMPT,
            generation_config={"response_mime_type": "application/json"}
        )
        return json.loads(response.text)
    except Exception as e:
        logger.error(f"Error generating posts with Gemini: {e}")
        return {}

def upload_to_instagram(post_text, image_url=None):
    """
    Skeleton for Instagram API integration.
    """
    logger.info(f"Uploading to Instagram: {post_text[:50]}...")
    # Placeholder for real API call
    # response = requests.post("https://graph.facebook.com/v18.0/{ig-user-id}/media", ...)
    return True

def upload_to_facebook(post_text, image_url=None):
    """
    Skeleton for Facebook API integration.
    """
    logger.info(f"Uploading to Facebook: {post_text[:50]}...")
    # Placeholder for real API call
    return True

def upload_to_tiktok(post_text, video_url=None):
    """
    Skeleton for TikTok API integration.
    """
    logger.info(f"Uploading to TikTok: {post_text[:50]}...")
    # Placeholder for real API call
    return True

def run_daily_automation(day_of_week):
    """
    Runs the daily automated upload for all configured platforms.
    """
    logger.info(f"Running daily automation for {day_of_week}...")
    
    # In a real app, we might store the weekly posts in Firestore and pull today's.
    posts = generate_weekly_posts()
    post_text = posts.get(day_of_week)
    
    if post_text:
        upload_to_instagram(post_text)
        upload_to_facebook(post_text)
        upload_to_tiktok(post_text)
        return True
    else:
        logger.warning(f"No post found for {day_of_week}")
        return False

if __name__ == "__main__":
    import datetime
    today = datetime.datetime.now().strftime("%A")
    run_daily_automation(today)
