import logging
import json
import re
import google.generativeai as genai
from marketing_prompts import SOCIAL_MEDIA_PROMPT

"""
This module handles the interaction with the Gemini AI to generate
social media content for the SpineVision ecosystem.
"""

# Initialize the Gemini model. 
# The simulation script patches this object during testing.
logger = logging.getLogger("social_media_manager")
model = genai.GenerativeModel('gemini-1.5-flash')

def generate_weekly_posts(analytics_context=None):
    """
    Sends the SOCIAL_MEDIA_PROMPT to Gemini and parses the JSON response.
    """
    prompt = SOCIAL_MEDIA_PROMPT
    if analytics_context:
        prompt += f"\n\n**Current Business Analytics Context for AI Sourcing:**\n{json.dumps(analytics_context, indent=2)}"

    response = model.generate_content(prompt)
    
    try:
        text = response.text.strip()
        # Handle potential markdown code blocks in Gemini response
        if text.startswith("```"):
            text = re.sub(r'^```(?:json)?\n?|```$', '', text, flags=re.MULTILINE).strip()
            
        return json.loads(text)
    except (json.JSONDecodeError, AttributeError) as e:
        logger.error(f"Failed to parse social media content: {e}")
        return {"error": "Could not parse AI response into JSON."}

def run_daily_automation(day_of_week, db=None, analytics_data=None):
    """
    Orchestrates the daily social media upload based on the weekly plan.
    """
    logger.info(f"Triggering daily social media automation for: {day_of_week}")
    
    # 1. Fetch or generate posts
    # Note: In production, we'd cache the weekly plan in Firestore to ensure consistency.
    posts = generate_weekly_posts(analytics_context=analytics_data)
    
    if "error" in posts:
        logger.error("Automation failed: Could not obtain post schedule.")
        return False
        
    post_content = posts.get(day_of_week)
    if not post_content:
        logger.warning(f"No post content found for day: {day_of_week}")
        return False

    # 2. Sequential upload to connected platforms (Skeletons for API integration)
    results = {
        "Instagram": _upload_to_instagram(post_content),
        "Facebook": _upload_to_facebook(post_content),
        "TikTok": _upload_to_tiktok(post_content)
    }
    
    logger.info(f"Automation finished for {day_of_week}. Summary: {results}")
    return all(results.values())

def _upload_to_instagram(content):
    """
    Integration skeleton for Instagram Graph API.
    """
    logger.info(f"[INSTAGRAM] Simulating upload: {content[:40]}...")
    return True

def _upload_to_facebook(content):
    """
    Integration skeleton for Facebook Pages API.
    """
    logger.info(f"[FACEBOOK] Simulating upload: {content[:40]}...")
    return True

def _upload_to_tiktok(content):
    """
    Integration skeleton for TikTok Video API.
    """
    logger.info(f"[TIKTOK] Simulating upload: {content[:40]}...")
    return True