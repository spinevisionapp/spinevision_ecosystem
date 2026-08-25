import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import datetime

import os

# Initialize Firebase Admin SDK
# Cloud Shell automatically provides credentials, so we don't need a service account key file
if not firebase_admin._apps:
    cred = credentials.ApplicationDefault()
    project_id = os.getenv("FIREBASE_PROJECT_ID", "spinevision-6abad")
    firebase_admin.initialize_app(cred, {
        'projectId': project_id,
    })

db = firestore.client()

print("Starting to add seed documents...")

# --- Add seed documents to 'users' collection ---
users = [
    {"uid": "hobbyist-user", "tier": "Hobbyist", "scans_this_month": 5, "listings_created": 2},
    {"uid": "pro-user", "tier": "Pro", "scans_this_month": 51, "listings_created": 10},
    {"uid": "enterprise-user", "tier": "Enterprise", "scans_this_month": 150, "listings_created": 60},
]

for u in users:
    user_ref = db.collection('users').document(u['uid'])
    user_ref.set({
        "tier": u['tier'],
        "scans_this_month": u['scans_this_month'],
        "listings_created": u['listings_created']
    })
    print(f"Seeded user: {u['uid']} as {u['tier']}")

    # --- Add inventory books to the subcollection ---
    inventory = [
        {
            'isbn': '978-0743273565',
            'title': 'The Great Gatsby',
            'author': 'F. Scott Fitzgerald',
            'purchase_price': 2.00,
            'estimated_value': 15.00,
            'ai_grade': 85,
            'status': 'sourced',
            'dateSourced': firestore.SERVER_TIMESTAMP
        },
        {
            'isbn': '978-0451524935',
            'title': '1984',
            'author': 'George Orwell',
            'purchase_price': 1.50,
            'estimated_value': 12.00,
            'ai_grade': 90,
            'status': 'listed',
            'dateSourced': firestore.SERVER_TIMESTAMP
        }
    ]
    
    if u['tier'] in ['Pro', 'Enterprise']:
        inventory.append({
            'isbn': '978-0547928227',
            'title': 'The Hobbit',
            'author': 'J.R.R. Tolkien',
            'purchase_price': 5.00,
            'estimated_value': 45.00,
            'ai_grade': 95,
            'status': 'sold',
            'dateSourced': firestore.SERVER_TIMESTAMP
        })

    for book in inventory:
        book_id = f"book_{book['isbn']}"
        user_ref.collection('inventory').document(book_id).set(book)
        print(f"  Added book '{book['title']}' to {u['uid']}'s inventory.")

# --- Add seed document to 'Library' collection (legacy/root if still needed) ---
# NOTE: The app currently uses users/{uid}/inventory. 
# We'll keep this one entry for backward compatibility if any backend tools expect it.
library_doc_ref = db.collection('Library').document('legacy_ Gatsby')
library_doc_ref.set({
    'user_id': 'enterprise-user',
    'isbn': '978-0743273565',
    'title': 'The Great Gatsby (Legacy)',
    'author': 'F. Scott Fitzgerald',
    'purchase_price': 15.99,
    'ai_grade': 88,
    'status': 'sourced',
    'timestamp': firestore.SERVER_TIMESTAMP
})
print(f"Added legacy Library document.")

# --- Add seed document to 'Market_Data' collection ---
market_data_doc_ref = db.collection('Market_Data').document() # Let Firestore auto-generate ID
market_data_doc_ref.set({
    'isbn': '978-0743273565',
    'ebay_low': 20.00,
    'ebay_high': 45.50,
    'demand_score': 7.5,
    'is_bolo': True
})
print(f"Added Market_Data document with ID: {market_data_doc_ref.id}")

# --- Add seed document to 'Orders' collection ---
orders_doc_ref = db.collection('Orders').document() # Let Firestore auto-generate ID
orders_doc_ref.set({
    'user_id': 'enterprise-user',
    'order_id': 'SV-ORD-001',
    'profit_margin': 12.30,
    'return_shield_link': 'https://example.com/return/SV-ORD-001'
})
print(f"Added Orders document with ID: {orders_doc_ref.id}")

# --- Add seed document to 'Tickets' collection ---
tickets_doc_ref = db.collection('Tickets').document() # Let Firestore auto-generate ID
tickets_doc_ref.set({
    'user_id': 'enterprise-user',
    'subject': 'Issue with Batch Scanning',
    'message': 'When I try to scan a shelf of books, the app crashes. This is happening on an iPhone 14 Pro.',
    'status': 'Open',
    'created_at': firestore.SERVER_TIMESTAMP,
    'updated_at': firestore.SERVER_TIMESTAMP
})
print(f"Added Tickets document with ID: {tickets_doc_ref.id}")

print("All seed documents added successfully. Collections created implicitly.")
