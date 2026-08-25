import logging
from datetime import datetime, timedelta
from firebase_admin import firestore
from .firebase import db

logger = logging.getLogger("spinevision.membership")

MILESTONES = {
    "SCANS_FOR_PRO_TRIAL": 50,
    "LISTINGS_FOR_PRO_TRIAL": 20,
    "SCANS_FOR_ENTERPRISE_TRIAL": 500,
}

def get_user_tier(user_id):
    if not db or not user_id: return "Hobbyist"
    doc = db.collection('users').document(user_id).get()
    return doc.to_dict().get('tier', 'Hobbyist') if doc.exists else "Hobbyist"

def track_usage(user_id, usage_type, count=1):
    field_map = {"scan": "scans_this_month", "listing": "listings_created"}
    field_name = field_map.get(usage_type)
    if not field_name or not user_id: return
    
    user_ref = db.collection('users').document(user_id)
    user_doc = user_ref.get()
    if user_doc.exists:
        user_ref.update({field_name: firestore.Increment(count)})
    else:
        user_ref.set({field_name: count, "tier": "Hobbyist"})

def check_milestones(user_id):
    user_doc = db.collection('users').document(user_id).get()
    if not user_doc.exists: return "User not found."
    
    data = user_doc.to_dict()
    tier = data.get('tier', 'Hobbyist')
    
    if tier == "Hobbyist":
        if data.get("scans_this_month", 0) >= MILESTONES["SCANS_FOR_PRO_TRIAL"] or \
           data.get("listings_created", 0) >= MILESTONES["LISTINGS_FOR_PRO_TRIAL"]:
            return grant_promotion(user_id, "Pro_Trial", "Pro", 14)
            
    return "No new promotions."

def grant_promotion(user_id, promo_key, target_tier, duration):
    expires = datetime.now() + timedelta(days=duration)
    db.collection('users').document(user_id).update({
        "tier": target_tier,
        "promo_tier": promo_key,
        "promo_expires": expires
    })
    return f"GRANTED: {target_tier} trial for {duration} days."
