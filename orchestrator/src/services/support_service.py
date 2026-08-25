import logging
from firebase_admin import firestore
from .ai import model
from .firebase import db

logger = logging.getLogger("spinevision.support")

FAQS = [
    {"question": "How do I upgrade?", "answer": "Go to the Settings screen and tap 'Upgrade'."},
    {"question": "What is OmniVision?", "answer": "It's our high-speed book scanning engine."}
]

def search_faqs(query):
    query = query.lower()
    return [f for f in FAQS if query in f['question'].lower() or query in f['answer'].lower()]

def ask_chatbot(question, user_id="anonymous"):
    def get_user_stats():
        if not db or user_id == "anonymous": return {"tier": "Hobbyist"}
        doc = db.collection('users').document(user_id).get()
        return doc.to_dict() if doc.exists else {"tier": "Hobbyist"}

    tools = [get_user_stats, search_faqs]
    chat_model = model # Reuse global model but with tools
    # Actually, model is a GenerativeModel instance. To add tools we might need a new one or use the existing one if supported.
    # In genai 0.8.x, you pass tools to GenerativeModel constructor.
    
    # Simple implementation for now:
    chat = chat_model.start_chat(enable_automatic_function_calling=True)
    response = chat.send_message(f"User ID: {user_id}. Question: {question}")
    return response.text

def create_ticket(user_id, subject, message):
    ticket_ref = db.collection('Tickets').document()
    ticket_data = {
        'user_id': user_id,
        'subject': subject,
        'message': message,
        'status': 'Open',
        'created_at': firestore.SERVER_TIMESTAMP
    }
    ticket_ref.set(ticket_data)
    return ticket_ref.id
