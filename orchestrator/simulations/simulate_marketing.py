
import json
import unittest
from unittest.mock import MagicMock, patch
import sys
import os

# Ensure the root directory is in the path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from social_media_manager import generate_weekly_posts

def run_marketing_simulation():
    print("\n--- 📣 SPINEVISION SOCIAL MEDIA AUTOMATION SIMULATION ---")
    
    # Mock data for the weekly posts
    mock_posts = {
        "Monday": "🚀 Kickstart your week with #SpineVision! Our AI just helped a user find a first edition for $2 that sold for $150. #ResellerLife #MondayMotivation",
        "Tuesday": "📈 ROI Tip: Always check the binding. Our ConditionVision module identifies spine wear that others miss, saving you from bad buys. #ProfitVision #BookReselling",
        "Wednesday": "🚨 BOLO ALERT! Vintage technical manuals from the 1970s are trending. Scan them with ShelfVision to find the hidden gems in bulk lots. #BOLO #SpineVision",
        "Thursday": "🤖 AskVisionAI: 'Is this ISBN-10 rare?' Our Chatbot is ready to help you navigate tricky sourcing decisions in real-time. #AI #SourcingSupport",
        "Friday": "📦 Friday FBA Prep? Use the AmazonVision Box Builder to stay organized and ensure your manifests are 100% accurate. #FBA #AmazonSeller",
        "Saturday": "📍 Sourcing Trip Saturday! Start your GPS tracker in ProfitVision to automatically log your sourcing mileage for tax season. #TaxTips #Reseller",
        "Sunday": "📊 Week in Review: Users at the Enterprise tier saw a 22% increase in average profit per book this month. Ready to upgrade? #ScaleYourBusiness #SpineVision"
    }

    # Patch the model.generate_content call inside generate_weekly_posts
    with patch('social_media_manager.model') as mock_model:
        # Create a mock response object
        mock_response = MagicMock()
        mock_response.text = json.dumps(mock_posts)
        mock_model.generate_content.return_value = mock_response

        print("\n[AI Orchestrator]: Generating high-engagement posts for the week...")
        posts = generate_weekly_posts()

        print("\n--- 📅 WEEKLY CONTENT SCHEDULE ---")
        for day, post in posts.items():
            print(f"\n[{day}]:")
            print(f"Content: {post}")
            print("-" * 30)

    print("\n✅ Simulation Complete. All posts generated and ready for automated upload to Instagram, Facebook, and TikTok.")

if __name__ == "__main__":
    run_marketing_simulation()
