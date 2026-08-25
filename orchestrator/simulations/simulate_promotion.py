
import logging
from promotion_engine import track_usage, check_user_milestones, MOCK_USER_DATA

def run_promotion_simulation():
    # Setup logging
    logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
    
    print("\n--- 🎟️ SPINEVISION PROMOTION ENGINE SIMULATION ---")
    
    # 1. Initialize a new Hobbyist user
    user_id = "new_hobbyist_001"
    MOCK_USER_DATA[user_id] = {
        "tier": "Hobbyist", 
        "scans_this_month": 0, 
        "listings_created": 0
    }
    
    print(f"\n[Step 1]: User '{user_id}' starts as a {MOCK_USER_DATA[user_id]['tier']}.")
    print(f"Current Stats: {MOCK_USER_DATA[user_id]['scans_this_month']} scans.")

    # 2. Simulate scanning books
    scan_count = 100
    print(f"\n[Step 2]: User goes on a major sourcing trip and scans {scan_count} books...")
    
    # In a real app, track_usage would be called for every scan
    track_usage(user_id, "scan", count=scan_count)
    
    current_scans = MOCK_USER_DATA[user_id]['scans_this_month']
    print(f"Updated Stats: {current_scans} scans this month.")

    # 3. Check for milestones
    print("\n[Step 3]: AI Orchestrator checks for milestone achievements...")
    promo_result = check_user_milestones(user_id)
    
    print(f"\nEngine Result: {promo_result}")
    
    # 4. Final verification
    new_tier = MOCK_USER_DATA[user_id]['tier']
    print(f"\n[Step 4]: User '{user_id}' now has access to {new_tier} features!")
    print(f"Unlocked: ShelfVision (Bulk Scan) and SetVision (Series Tracker) are now active.")

    print("\n✅ Simulation Complete. The user has been successfully 'leveled up' by their activity.")

if __name__ == "__main__":
    run_promotion_simulation()
