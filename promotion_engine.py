"""
This file contains the logic for the Promotion Engine, which grants temporary
Pro/Enterprise access to users based on usage milestones.
"""
from datetime import datetime, timedelta
import logging
from firebase_admin import firestore

logger = logging.getLogger("promotion_engine")

# Fictional user database for fallback.
MOCK_USER_DATA = {
    "user_123": {"tier": "Hobbyist", "scans_this_month": 5, "listings_created": 2},
    "user_456": {"tier": "Hobbyist", "scans_this_month": 51, "listings_created": 10},
    "user_789": {"tier": "Pro", "scans_this_month": 200, "listings_created": 50},
}

# --- Promotion Tier Definitions ---
PROMOTION_TIERS = {
    "Pro_Trial": {"duration_days": 14, "target_tier": "Pro"},
    "Enterprise_Trial": {"duration_days": 7, "target_tier": "Enterprise"},
}

# --- Milestone Definitions ---
MILESTONES = {
    "SCANS_FOR_PRO_TRIAL": 50,
    "LISTINGS_FOR_PRO_TRIAL": 20,
    "SCANS_FOR_ENTERPRISE_TRIAL": 500, # Only for Pro users
}

def check_user_milestones(user_id, db=None):
    """
    Checks a user's usage against milestones and grants promotions.
    """
    if db:
        try:
            user_doc_ref = db.collection('users').document(user_id)
            user_doc = user_doc_ref.get()
            if not user_doc.exists:
                # Initialize new user if they don't exist
                user_data = {"tier": "Hobbyist", "scans_this_month": 0, "listings_created": 0}
                user_doc_ref.set(user_data)
            else:
                user_data = user_doc.to_dict()
        except Exception as e:
            logger.warning(f"Firestore error in promotion engine: {e}")
            return f"Error checking milestones for {user_id}"
    else:
        user_data = MOCK_USER_DATA.get(user_id)
        if not user_data:
            return f"User {user_id} not found."

    logger.info(f"Checking milestones for {user_id} (Current Tier: {user_data.get('tier')})...")

    # --- Pro Trial for Hobbyists ---
    if user_data.get("tier") == "Hobbyist":
        if user_data.get("scans_this_month", 0) >= MILESTONES["SCANS_FOR_PRO_TRIAL"]:
            return _grant_promotion(user_id, "Pro_Trial", db)

        if user_data.get("listings_created", 0) >= MILESTONES["LISTINGS_FOR_PRO_TRIAL"]:
            return _grant_promotion(user_id, "Pro_Trial", db)

    # --- Enterprise Trial for Pro Users ---
    if user_data.get("tier") == "Pro":
        if user_data.get("scans_this_month", 0) >= MILESTONES["SCANS_FOR_ENTERPRISE_TRIAL"]:
            return _grant_promotion(user_id, "Enterprise_Trial", db)
            
    return f"No new promotions for {user_id}."

def _grant_promotion(user_id, promotion_tier_key, db=None):
    """
    Grants a promotional tier to a user.
    """
    promotion = PROMOTION_TIERS[promotion_tier_key]
    duration = promotion['duration_days']
    target_tier = promotion['target_tier']
    
    msg = f"GRANTING PROMOTION: User {user_id} gets '{promotion_tier_key}' for {duration} days."
    logger.info(msg)
    
    if db:
        try:
            expiration_date = datetime.now() + timedelta(days=duration)
            db.collection('users').document(user_id).update({
                "tier": target_tier,
                "promo_tier": promotion_tier_key,
                "promo_expires": expiration_date
            })
        except Exception as e:
            logger.warning(f"Failed to update user promotion in Firestore: {e}")
            return f"Failed to grant promotion to {user_id}"
    else:
        # Update mock data for local testing
        if user_id in MOCK_USER_DATA:
            MOCK_USER_DATA[user_id]["tier"] = target_tier
            
    return msg

def track_usage(user_id, usage_type, db=None, count=1):
    """
    Increments the user's usage count (scans or listings) in Firestore.
    """
    if not user_id:
        return
        
    field_map = {
        "scan": "scans_this_month",
        "listing": "listings_created"
    }
    field_name = field_map.get(usage_type)
    if not field_name:
        logger.warning(f"Invalid usage type: {usage_type}")
        return

    if db:
        try:
            user_ref = db.collection('users').document(user_id)
            user_doc = user_ref.get()
            if user_doc.exists:
                user_ref.update({field_name: firestore.Increment(count)})
            else:
                user_data = {
                    "tier": "Hobbyist",
                    "scans_this_month": 0,
                    "listings_created": 0
                }
                user_data[field_name] = count
                user_ref.set(user_data)
        except Exception as e:
            logger.warning(f"Failed to increment {usage_type} for {user_id}: {e}")
    else:
        if user_id in MOCK_USER_DATA:
            MOCK_USER_DATA[user_id][field_name] += count

# Example Usage:
if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    print("--- Running Promotion Engine ---")
    print(check_user_milestones("user_123")) # Should not get a promotion
    print(check_user_milestones("user_456")) # Should get a Pro trial
    
    # Simulate a Pro user hitting an Enterprise milestone
    MOCK_USER_DATA["user_789"]["scans_this_month"] = 501
    print(check_user_milestones("user_789"))
    print("----------------------------")
