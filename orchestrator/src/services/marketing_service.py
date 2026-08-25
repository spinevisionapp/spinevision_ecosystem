import logging
import datetime
from .ai import model
from .vision_service import generate_json_with_retry

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

def run_daily_automation(day, db=None, analytics_data=None):
    logger.info(f"Running daily automation for {day}")
    # Logic to post to social media would go here.
    # For now, we generate the content and log it.
    content = generate_weekly_content(analytics_data)
    if content and day in content:
        logger.info(f"Automated post for {day}: {content[day]}")
        return True
    return False
