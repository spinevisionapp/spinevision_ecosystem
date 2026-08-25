import logging
import json
from .ai import model
from .vision_service import generate_json_with_retry, download_image_to_temp
from ..models import schemas

logger = logging.getLogger("spinevision.business")

def get_buy_decision(book_data, user_settings, tier="Hobbyist"):
    prompt = f"Act as SpineVision BuyExpert ({tier} Mode). Analyze: {json.dumps(book_data)}. Settings: {json.dumps(user_settings)}. Return JSON: decision, confidence_score, estimated_profit, roi_percentage, risk_level, reason."
    return generate_json_with_retry(prompt)

def extract_pricing(book_data=None, image_reference=None):
    prompt = "Act as ProfitVision. Estimate market values. Return JSON: original_retail_price, estimated_market_value, comparable_prices, sales_rank, is_bolo."
    contents = [prompt]
    if image_reference:
        # download and add as part
        pass
    if book_data:
        contents.append(f"Book Data: {json.dumps(book_data)}")
    return generate_json_with_retry(contents)

def analyze_set(metadata=None, image_reference=None):
    prompt = "Act as SetVision. Identify if part of a set. Return JSON: is_part_of_set, set_name, missing_volumes, set_completion_value_bonus."
    return generate_json_with_retry([prompt, metadata] if metadata else [prompt])
