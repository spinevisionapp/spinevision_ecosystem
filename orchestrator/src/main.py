import os
import json
import shutil
import time
import logging
import re
import httpx
from typing import List, Optional, Tuple
from fastapi import FastAPI, HTTPException, UploadFile, File, BackgroundTasks, Request
from pydantic import BaseModel, Field
import vertexai
from vertexai.generative_models import GenerativeModel, Part, Image
from google.cloud import storage, firestore

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("orchestrator")

app = FastAPI(title="SpineVision Orchestrator", version="1.0.0")

# --- Configuration ---
import os

PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID", "spinevision-6abad")
LOCATION = "us-central1"
KEEPA_API_KEY = os.getenv("KEEPA_API_KEY")  # Add this to your env
vertexai.init(project=PROJECT_ID, location=LOCATION)
db = firestore.Client(project=PROJECT_ID)
vision_model = GenerativeModel("gemini-2.0-flash-001")

# --- Schemas (Prompt 31) ---

class MetadataHint(BaseModel):
    title: Optional[str] = None
    author: Optional[str] = None

class AnalyzeSpineRequest(BaseModel):
    user_id: str
    image_uri: str
    metadata_hint: Optional[MetadataHint] = None

class BookMetadata(BaseModel):
    isbn13: Optional[str] = None
    title: str
    author: str
    confidence: float
    condition: str = "Good"
    defects: List[str] = []
    weight_lbs: float = 1.2
    sales_rank: int = 50000
    sales_velocity: int = 150  # Days with sales in last 180
    used_count: int = 12
    new_count: int = 3
    keepa_insight: Optional[str] = None
    is_set_piece: bool = False
    series_name: Optional[str] = None
    refurbish_guide: Optional[str] = None

class AnalyzeSpineResponse(BaseModel):
    task_id: str
    metadata: BookMetadata
    decision: str  # BUY, PASS, REVIEW, UNGATE, SET_PIECE, REFURBISH
    is_duplicate: bool = False
    is_restricted: bool = False
    fba_fees: float = 0.0
    net_payout: float = 0.0
    rationale: Optional[str] = None
    fallback_applied: bool = False

class PricingRequest(BaseModel):
    image_uri: Optional[str] = None
    book_data: Optional[dict] = None

class CatalogRequest(BaseModel):
    image_uri: str

class MarketingRequest(BaseModel):
    analytics_data: dict

class ReceiptRequest(BaseModel):
    image_uri: str

class ShelfScanRequest(BaseModel):
    image_uri: str

class TicketCreate(BaseModel):
    subject: str
    message: str

class ChatRequest(BaseModel):
    question: str
    user_id: Optional[str] = "anonymous"

# --- Helpers ---

def perform_storage_cleanup(directory: str = "/tmp/spinevision", max_age_hours: int = 24):
    """Deletes files older than a certain age to free up space."""
    if not os.path.exists(directory):
        return
    
    now = time.time()
    cutoff = now - (max_age_hours * 3600)
    
    for filename in os.listdir(directory):
        filepath = os.path.join(directory, filename)
        if os.path.getmtime(filepath) < cutoff:
            try:
                if os.path.isfile(filepath) or os.path.islink(filepath):
                    os.unlink(filepath)
                elif os.path.isdir(filepath):
                    shutil.rmtree(filepath)
            except Exception as e:
                logger.error(f"Failed to delete {filepath}: {e}")

def sanitize_ai_json(text: str) -> dict:
    """Strips markdown and parses JSON from AI response."""
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r'^```(?:json)?\n?|```$', '', text, flags=re.MULTILINE).strip()
    return json.loads(text)

async def fetch_google_books_metadata(isbn: str) -> Optional[dict]:
    """Fetches free book metadata from Google Books API to validate AI output."""
    if not isbn:
        return None
    try:
        async with httpx.AsyncClient() as client:
            url = f"https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn}"
            response = await client.get(url, timeout=5.0)
            if response.status_code == 200:
                data = response.json()
                if "items" in data:
                    volume_info = data["items"][0].get("volumeInfo", {})
                    return {
                        "title": volume_info.get("title"),
                        "author": ", ".join(volume_info.get("authors", ["Unknown"]))
                    }
    except Exception as e:
        logger.error(f"Google Books API Error: {e}")
    return None

async def fetch_keepa_data(isbn: str) -> Optional[dict]:
    """Fetches real-time market data from Keepa API."""
    if not KEEPA_API_KEY or not isbn:
        logger.warning("Keepa API Key missing or ISBN null. Skipping real-time lookup.")
        return None

    try:
        async with httpx.AsyncClient() as client:
            # Keepa API: domain 1 = Amazon.com
            url = f"https://api.keepa.com/product?key={KEEPA_API_KEY}&domain=1&asin={isbn}&stats=180"
            response = await client.get(url, timeout=5.0)
            if response.status_code == 200:
                data = response.json()
                if "products" in data and len(data["products"]) > 0:
                    product = data["products"][0]
                    stats = product.get("stats", {})
                    return {
                        "rank": stats.get("current", [None]*4)[3], # Sales Rank is usually index 3
                        "avg_price": stats.get("avg", [None]*2)[1] / 100 if stats.get("avg") else 25.0,
                    }
    except Exception as e:
        logger.error(f"Keepa API Error: {e}")
    return None

async def check_duplicate(user_id: str, isbn13: str) -> bool:
    """Check if the book already exists in the user's library."""
    if not isbn13:
        return False
    
    # Query: /users/{userId}/books where isbn13 == detected_isbn
    docs = db.collection("users").document(user_id).collection("books").where("isbn13", "==", isbn13).limit(1).stream()
    return any(docs)

def get_user_tier(user_id: str) -> str:
    """Fetches the user's membership tier."""
    if not user_id:
        return "Hobbyist"
    try:
        doc = db.collection("users").document(user_id).get()
        if doc.exists:
            return doc.to_dict().get("tier", "Hobbyist")
    except Exception as e:
        logger.error(f"Error fetching tier: {e}")
    return "Hobbyist"

def calculate_fba_decision(metadata: BookMetadata, is_duplicate: bool, is_restricted: bool) -> Tuple[str, str, float, float]:
    """Encapsulates the business logic for buying decisions."""
    fba_fees = 5.50 + (metadata.weight_lbs * 0.50)
    target_price = 25.00
    net_payout = target_price - fba_fees - (target_price * 0.15)
    
    decision = "BUY"
    rationale = f"BSR #{metadata.sales_rank} is strong. Velocity: {metadata.sales_velocity}/180 days."

    if metadata.is_set_piece:
        decision = "SET_PIECE"
        rationale = f"SET PIECE FOUND! Series: {metadata.series_name}. ROI boosted."
        net_payout *= 1.4
        
    elif metadata.refurbish_guide:
        decision = "REFURBISH"
        rationale = f"Refurbish required: {metadata.refurbish_guide}"
        
    elif is_restricted:
        if net_payout > 15.0:
            decision = "UNGATE"
            rationale = "Item is RESTRICTED but highly profitable ($15+ net). Recommend ungating."
        else:
            decision = "PASS"
            rationale = "Restricted category with low margin."
    
    elif is_duplicate:
        if metadata.sales_velocity > 160:
            decision = "BUY"
            rationale = "High-velocity duplicate. Quick flip potential."
        else:
            decision = "PASS"
            rationale = "Duplicate with moderate velocity."
    
    elif metadata.confidence < 0.85:
        decision = "REVIEW"
        rationale = "Low confidence. Please verify ISBN or Cover."

    return decision, rationale, fba_fees, net_payout

# --- Endpoints (Prompt 6) ---

@app.on_event("startup")
async def startup_event():
    perform_storage_cleanup()

@app.get("/health")
async def root():
    return {"status": "online", "service": "SpineVision Orchestrator"}

@app.post("/v1/maintenance/cleanup")
async def trigger_cleanup(background_tasks: BackgroundTasks):
    """Endpoint to manually trigger storage cleanup."""
    background_tasks.add_task(perform_storage_cleanup)
    return {"status": "cleanup_initiated"}

@app.post("/v1/analyze_spine", response_model=AnalyzeSpineResponse)
async def analyze_spine(request: AnalyzeSpineRequest):
    """
    Primary entry point for ThriftVision scans.
    1. Identify book via Gemini Vision.
    2. Check duplicates in Library.
    3. Calculate ROI & Exceptions with Amazon FBA Logic (Prompt 41).
    """
    try:
        # 1. Prepare the OmniVision Prompt
        system_instruction = (
            "Act as OmniVision (SpineVision Image Specialist). Identify the book and evaluate its condition. "
            "Return a JSON object with 'isbn13', 'title', 'author', 'confidence', 'condition', 'defects', "
            "'weight_lbs', 'sales_rank', 'sales_velocity' (0-180), 'is_set_piece' (boolean), 'series_name', and 'refurbish_guide'."
        )
        
        # 2. Reference the image from GCS
        image_part = Part.from_uri(request.image_uri, mime_type="image/jpeg")
        
        # 3. Generate Content
        response = vision_model.generate_content(
            [system_instruction, image_part],
            generation_config={"response_mime_type": "application/json"}
        )
        
        # 4. Parse AI Result
        ai_data = sanitize_ai_json(response.text)
        metadata = BookMetadata(**ai_data)

        # 5. Free Metadata Validation (Google Books)
        gb_metadata = await fetch_google_books_metadata(metadata.isbn13)
        if gb_metadata:
            metadata.title = gb_metadata["title"] or metadata.title
            metadata.author = gb_metadata["author"] or metadata.author

        # 6. Real-time Market Intelligence (Keepa)
        keepa_info = await fetch_keepa_data(metadata.isbn13)
        if keepa_info:
            metadata.sales_rank = keepa_info.get("rank") or metadata.sales_rank
            metadata.keepa_insight = f"Verified Rank: {metadata.sales_rank}. Avg Price: ${keepa_info.get('avg_price')}"

        # 6. Intelligence & Gating Logic
        is_duplicate = await check_duplicate(request.user_id, metadata.isbn13)
        is_restricted = metadata.sales_rank < 10000  # Mock restriction logic
        
        # 7. Business Logic Calculation
        decision, rationale, fba_fees, net_payout = calculate_fba_decision(
            metadata, is_duplicate, is_restricted
        )

        return AnalyzeSpineResponse(
            task_id="task-" + request.user_id[:5],
            metadata=metadata,
            decision=decision,
            is_duplicate=is_duplicate,
            is_restricted=is_restricted,
            fba_fees=fba_fees,
            net_payout=net_payout,
            rationale=rationale
        )
        
    except Exception as e:
        logger.exception(f"System Error during spine analysis: {e}")
        return AnalyzeSpineResponse(
            task_id="task-mock-" + request.user_id[:5],
            metadata=BookMetadata(
                isbn13="9780143105954",
                title="Meditations (Fallback)",
                author="Marcus Aurelius",
                confidence=0.50
            ),
            decision="REVIEW",
            rationale="System error occurred. Manual review required.",
            fallback_applied=True
        )

@app.post("/v1/profit/pricing", tags=["ProfitVision"])
async def extract_pricing(request: PricingRequest):
    """Estimates market value and ROI (ProfitVision)."""
    prompt = f"Act as ProfitVision. Analyze this data and provide market values: {json.dumps(request.book_data)}"
    contents = [prompt]
    if request.image_uri:
        contents.append(Part.from_uri(request.image_uri, mime_type="image/jpeg"))
    
    response = vision_model.generate_content(contents, generation_config={"response_mime_type": "application/json"})
    return sanitize_ai_json(response.text)

@app.post("/v1/ledger/receipt", tags=["LedgerVision"])
async def analyze_receipt(request: ReceiptRequest):
    """Extracts financial data from receipts (LedgerVision)."""
    prompt = "Act as LedgerVision. Extract merchant, date, total_amount, tax, and category (COGS/Supplies) from this receipt."
    image_part = Part.from_uri(request.image_uri, mime_type="image/jpeg")
    response = vision_model.generate_content([prompt, image_part], generation_config={"response_mime_type": "application/json"})
    return sanitize_ai_json(response.text)

@app.post("/v1/shelf/batch", tags=["ShelfVision"])
async def batch_scan(request: ShelfScanRequest):
    """Digitizes an entire shelf of books (ShelfVision)."""
    prompt = "Act as ShelfVision. Extract metadata for EVERY book visible on this shelf. Return a list of books with title, author, and condition."
    image_part = Part.from_uri(request.image_uri, mime_type="image/jpeg")
    response = vision_model.generate_content([prompt, image_part], generation_config={"response_mime_type": "application/json"})
    return sanitize_ai_json(response.text)

@app.post("/v1/marketing/generate", tags=["MarketingVision"])
async def generate_marketing(request: MarketingRequest):
    """Generates social media content based on sales data (MarketingVision)."""
    prompt = f"Act as MarketingVision. Generate 3 social media posts (IG, X, FB) using these brand colors: Teal, Purple. Data: {json.dumps(request.analytics_data)}"
    response = vision_model.generate_content(prompt, generation_config={"response_mime_type": "application/json"})
    return sanitize_ai_json(response.text)

@app.post("/v1/support/chat", tags=["SupportVision"])
async def support_chat(request: ChatRequest):
    """AI Chatbot for user support."""
    tier = get_user_tier(request.user_id)
    prompt = f"User Tier: {tier}. Question: {request.question}. Provide helpful SpineVision support."
    response = vision_model.generate_content(prompt)
    return {"answer": response.text}

@app.post("/v1/support/tickets", tags=["SupportVision"])
async def create_ticket(request: TicketCreate, user_id: str = "anonymous"):
    """Creates a manual support ticket in Firestore."""
    ticket_data = {
        "user_id": user_id,
        "subject": request.subject,
        "message": request.message,
        "status": "Open",
        "created_at": firestore.SERVER_TIMESTAMP
    }
    doc_ref = db.collection("Tickets").document()
    doc_ref.set(ticket_data)
    return {"status": "success", "ticket_id": doc_ref.id}

# --- Background Tasks (Eventarc) ---

@app.post("/v1/eventarc/firestore_queue")
async def firestore_queue_trigger(request: Request):
    """Handles asynchronous tasks triggered by Firestore document creation."""
    event_data = await request.json()
    fields = event_data.get("value", {}).get("fields", {})
    
    task_type = fields.get("task_type", {}).get("stringValue")
    image_uri = fields.get("image_uri", {}).get("stringValue")
    
    if not task_type:
        return {"status": "ignored"}

    # Routing logic for background tasks
    if task_type == "shelf_scan" and image_uri:
        # Call internal batch logic
        await batch_scan(ShelfScanRequest(image_uri=image_uri))
    elif task_type == "generate_marketing":
        analytics = fields.get("analytics_data", {}).get("mapValue", {}).get("fields", {})
        await generate_marketing(MarketingRequest(analytics_data=analytics))

    return {"status": "processed"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
