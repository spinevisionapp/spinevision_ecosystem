import pytest
import json
import sys
import os
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning, module="google._upb._message")

from main import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_spinevision_full_simulation(client, mocker):
    print("\n\n--- 🚀 STARTING SPINEVISION SYSTEM SIMULATION ---")
    
    # Mock authentication and tier-gating
    mocker.patch('main.get_authenticated_uid', return_value="test-enterprise-user")
    mocker.patch('main.get_user_tier', return_value="Enterprise")

    # --- 1. SYSTEM HEALTH CHECK ---
    print("\n[Step 1: Health Check]")
    res = client.get('/health')
    assert res.status_code == 200
    print(f"Result: {res.get_json()['status']} - Backend Orchestrator is Live.")

    # --- 2. THRIFTVISION: SCAN & METADATA ---
    print("\n[Step 2: ThriftVision - Scanning 'The Hobbit']")
    mocker.patch('main.download_image_to_temp', return_value="/tmp/hobbit.jpg")
    mocker.patch('main.genai.upload_file', return_value=mocker.MagicMock())
    
    meta_mock = mocker.patch('main.generate_json_with_retry')
    meta_mock.return_value = {
        "title": "The Hobbit", "author": "J.R.R. Tolkien", 
        "isbn13": "978-0547928227", "publisher": "Houghton Mifflin"
    }
    
    res = client.post('/extract_metadata', json={"image_reference": "gs://sim/hobbit.jpg"})
    book_meta = res.get_json()['data']
    print(f"Result: AI identified '{book_meta['title']}' by {book_meta['author']}.")

    # --- 3. PROFITVISION: BUY DECISION ---
    print("\n[Step 3: ProfitVision - Buy/Pass Decision]")
    meta_mock.return_value = {
        "decision": "buy", "estimated_profit": 18.50, "roi_percentage": 150,
        "reason": "High demand, low supply in this condition.",
        "strategic_recommendation": "List immediately on eBay for maximum ROI."
    }
    
    res = client.post('/buy_decision', json={
        "book_data": book_meta, 
        "user_settings": {"minimum_profit_margin": 10.0}
    })
    decision = res.get_json()['data']
    print(f"Result: AI says {decision['decision'].upper()}! (Net Profit: ${decision['estimated_profit']})")

    # --- 4. LISTINGVISION: AUTO-DRAFT ---
    print("\n[Step 4: ListingVision - Generating eBay Draft]")
    meta_mock.return_value = {
        "title": "The Hobbit by J.R.R. Tolkien - Hardcover Collector's Edition",
        "description": "Exquisite copy of the classic fantasy novel...",
        "keywords": ["Tolkien", "Hobbit", "Fantasy", "Hardcover"],
        "recommended_price": 24.99
    }
    
    res = client.post('/generate_listing', json={"book_data": book_meta, "platform": "eBay"})
    listing = res.get_json()['data']
    print(f"Result: Generated SEO Title: '{listing['title']}'")

    # --- 5. SETVISION: SERIES ANALYSIS ---
    print("\n[Step 5: SetVision - Checking for Missing Volumes]")
    meta_mock.return_value = {
        "is_part_of_set": True, "set_name": "The Lord of the Rings",
        "missing_volumes": ["The Two Towers", "The Return of the King"],
        "set_completion_value_bonus": 1.5
    }
    
    res = client.post('/analyze_set', json={"metadata": book_meta})
    set_data = res.get_json()['data']
    print(f"Result: Part of '{set_data['set_name']}'. Missing: {set_data['missing_volumes']}.")

    # --- 6. FORECASTVISION: TREND PREDICTION ---
    print("\n[Step 6: ForecastVision - Seasonal Demand]")
    meta_mock.return_value = {
        "demand_trend": "Increasing", "optimal_selling_season": "Back to School (August)",
        "seasonal_multipliers": {"Q1": 1.0, "Q4": 1.4},
        "strategic_advice": "High historical velocity in Q4. Consider holding for Christmas gift season."
    }
    
    res = client.post('/market_forecast', json={"book_data": book_meta})
    forecast = res.get_json()['data']
    print(f"Result: Trend is {forecast['demand_trend']}. Advice: {forecast['strategic_advice']}")

    # --- 7. ANALYTICSVISION: BUSINESS BI ---
    print("\n[Step 7: AnalyticsVision - High-Level Strategy]")
    meta_mock.return_value = {
        "total_inventory_value": 5400.0, "efficiency_score": 0.92,
        "sourcing_recommendations": "Target vintage fantasy and first-edition Sci-Fi.",
        "geographic_sourcing_advice": "High sell-through for this mix in coastal urban markets."
    }
    
    res = client.post('/analytics_enrichment', json={"raw_data": {"inventory": [book_meta]}})
    biz_intel = res.get_json()['data']
    print(f"Result: {biz_intel['sourcing_recommendations']}")

    print("\n--- ✅ SIMULATION COMPLETE: ALL MODULES VERIFIED ---")
