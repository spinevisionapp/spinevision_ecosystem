import os
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning, module="google._upb._message")

import google.generativeai as genai
from support_vision import FAQS

# This is a real Gemini API call.
def ask_gemini_chatbot(question, user_id=None, db=None):
    """
    Invokes the Gemini API for the chatbot with tool calling support.
    """
    try:
        def get_user_stats():
            """
            Fetches the current user's usage statistics and tier.
            """
            if not db or not user_id or user_id == "anonymous-user":
                return {"error": "User statistics not available for anonymous users or without database connection."}
            
            try:
                user_doc = db.collection('users').document(user_id).get()
                if user_doc.exists:
                    return user_doc.to_dict()
                else:
                    return {"tier": "Hobbyist", "scans_this_month": 0, "listings_created": 0}
            except Exception as e:
                return {"error": f"Error fetching user data: {str(e)}"}

        def search_faqs(query: str):
            """
            Searches the SpineVision FAQ database for relevant information.
            """
            query = query.lower()
            results = []
            for faq in FAQS:
                if query in faq['question'].lower() or query in faq['answer'].lower():
                    results.append(faq)
            return results if results else "No specific FAQ found for this query."

        tools = [get_user_stats, search_faqs]
        
        model = genai.GenerativeModel(
            'gemini-2.0-flash',
            tools=tools
        )
        
        # System instruction to define the chatbot's persona
        system_instruction = f"""
        You are SpineVision Bot, the AI assistant for SpineVision - an advanced ecosystem for book resellers.
        Help users with sourcing strategies, using our tools (OmniVision, ProfitVision, ShelfVision), 
        and understanding their membership tiers (Hobbyist, Pro, Enterprise).
        
        You have access to the user's statistics via the 'get_user_stats' tool.
        The current user ID is: {user_id}
        
        Tone: Professional, helpful, and efficient.
        """
        
        chat = model.start_chat(enable_automatic_function_calling=True)
        response = chat.send_message([system_instruction, question])
        
        return response.text.strip()
    except Exception as e:
        return f"I'm sorry, I'm having trouble connecting to my brain right now. Error: {str(e)}"

if __name__ == '__main__':
    print("Chatbot is running. Type 'quit' to exit.")
    while True:
        user_input = input("> ")
        if user_input.lower() == 'quit':
            break
        response = ask_gemini_chatbot(user_input)
        print(f"SpineVision Bot: {response}")
