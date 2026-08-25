import logging
import datetime
from .ai import model
from .vision_service import generate_json_with_retry
from .social_service import social_service

logger = logging.getLogger("spinevision.marketing")

SOCIAL_MEDIA_PROMPT = """
You are "VisionAI", the creative engine behind SpineVision.
Generate 7 engaging social media posts (Monday-Sunday) for book resellers.
Mix of success stories, ROI tips, and BOLO alerts.
Return JSON: {"Monday": "...", "Tuesday": "...", ...}
"""

def generate_weekly_content(analytics_context=None):
    logger.info("Generating weekly social content.")
    prompt = SOCIAL_MEDIA_PROMPT
    if analytics_context:
        prompt += f"\nContext: {analytics_context}"
    return generate_json_with_retry(prompt)

async def run_daily_automation(day, db=None, analytics_data=None):
    logger.info(f"Running daily automation for {day}")
    
    # 1. Generate/Fetch the content for the day
    content = generate_weekly_content(analytics_data)
    
    if content and day in content:
        post_text = content[day]
        logger.info(f"Automated post for {day}: {post_text}")
        
        # 2. Trigger multi-platform broadcast (SocialVision Beta)
        broadcast_results = await social_service.broadcast_content({"general": post_text})
        
        # 3. Log results or update Firestore status
        if all(broadcast_results.values()):
            return True
            
    return False
