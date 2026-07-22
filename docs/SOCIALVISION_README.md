# SocialVision: Marketing Automation Module

SocialVision is the integrated marketing automation suite for SpineVision, designed to help resellers build their brand and drive sales with minimal manual effort.

## Overview
SocialVision uses Gemini 2.0 to analyze a user's inventory, success stories, and market trends to generate high-quality, engaging social media content.

## Key Features
*   **AI Content Generation:** Automatically generates 7 weekly posts across three categories:
    *   **Success Stories:** Highlighting recent high-ROI flips.
    *   **ROI Tips:** Sharing sourcing knowledge to build authority.
    *   **BOLO Alerts:** (Be On the Look-Out) Teasing trending books to attract buyers.
*   **Multi-Platform Integration:** Support for Instagram, TikTok, and Facebook.
*   **Automated Scheduling:** Set-and-forget posting schedule via Firestore-linked triggers.
*   **Asset Management:** Automatically pulls photos from `listings` and `scans` to create visual posts.

## Technical Implementation
*   **Prompting Engine:** Custom Gemini prompts specialized for reseller marketing.
*   **Social APIs:** Skeletons implemented in `social_media_manager.py` for integration with official SDKs.
*   **Firestore Integration:** Stores generated posts in the `social` collection for review and scheduling.

## Workflow
1.  **Analyze:** System scans the `sales` and `VisionHub` collections for interesting data points.
2.  **Generate:** Gemini creates captions and suggests image pairings.
3.  **Approve:** User reviews generated posts in the SpineVision mobile app.
4.  **Publish:** System handles API uploads at optimal engagement times.

---
**Maintained by the SpineVision Marketing Team.**
