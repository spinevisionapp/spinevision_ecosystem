import os
import logging
import base64
import json
from typing import Optional, List
from fastapi import FastAPI, Request, HTTPException, Depends, BackgroundTasks, Form
from fastapi.responses import JSONResponse, RedirectResponse, HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel

from .core.config import settings
from .core.firebase import db
from .models import schemas
from .services import (
    vision_service, 
    marketing_service, 
    support_service, 
    business_service, 
    membership_service
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("spinevision.orchestrator")

app = FastAPI(title=settings.PROJECT_NAME)

# Templates and Static Files
templates = Jinja2Templates(directory="templates")
if os.path.exists("static"):
    app.mount("/static", StaticFiles(directory="static"), name="static")

# --- Security & Auth Helper ---
def get_user_id(request: Request) -> str:
    encoded_info = request.headers.get('X-Apigateway-Api-Userinfo')
    if not encoded_info:
        return "anonymous-user"
    try:
        padding = '=' * (4 - len(encoded_info) % 4)
        decoded_bytes = base64.urlsafe_b64decode(encoded_info + padding)
        user_info = json.loads(decoded_bytes)
        return user_info.get('user_id') or user_info.get('sub', "anonymous-user")
    except Exception:
        return "anonymous-user"

# --- Request Models (Specific to API) ---
class ImageRequest(BaseModel):
    image_reference: str

class PricingRequest(BaseModel):
    image_reference: Optional[str] = None
    book_data: Optional[schemas.BookModel] = None

class BuyDecisionRequest(BaseModel):
    book_data: schemas.BookModel
    user_settings: dict

class ChatRequest(BaseModel):
    question: str

# --- Endpoints ---

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "spinevision-orchestrator"}

@app.post("/extract_metadata", response_model=schemas.BookModel)
async def extract_metadata(req: ImageRequest, user_id: str = Depends(get_user_id)):
    result = vision_service.extract_metadata(req.image_reference)
    if result and user_id != "anonymous-user":
        membership_service.track_usage(user_id, "scan")
    return result

@app.post("/analyze_condition")
async def analyze_condition(req: ImageRequest):
    return vision_service.analyze_condition(req.image_reference)

@app.post("/batch_process_shelf")
async def batch_process_shelf(req: ImageRequest, user_id: str = Depends(get_user_id)):
    tier = membership_service.get_user_tier(user_id)
    if tier == "Hobbyist" and user_id != "anonymous-user":
        raise HTTPException(status_code=403, detail="Restricted to Pro and Enterprise.")
    
    result = vision_service.batch_shelf_scan(req.image_reference)
    if result and user_id != "anonymous-user":
        count = result.get('total_detected', 1)
        membership_service.track_usage(user_id, "scan", count=count)
    return result

@app.post("/extract_pricing")
async def extract_pricing(req: PricingRequest):
    book_dict = req.book_data.dict() if req.book_data else None
    return business_service.extract_pricing(book_dict, req.image_reference)

@app.post("/buy_decision")
async def buy_decision(req: BuyDecisionRequest, user_id: str = Depends(get_user_id)):
    tier = membership_service.get_user_tier(user_id)
    return business_service.get_buy_decision(req.book_data.dict(), req.user_settings, tier=tier)

@app.post("/generate_social_content")
async def generate_social(user_id: str = Depends(get_user_id)):
    tier = membership_service.get_user_tier(user_id)
    if tier == "Hobbyist" and user_id != "anonymous-user":
        raise HTTPException(status_code=403, detail="Restricted to Pro and Enterprise.")
    return marketing_service.generate_weekly_content()

@app.post("/chatbot")
async def chatbot(req: ChatRequest, user_id: str = Depends(get_user_id)):
    answer = support_service.ask_chatbot(req.question, user_id=user_id)
    return {"answer": answer}

@app.get("/check_promotions")
async def check_promotions(user_id: str = Depends(get_user_id)):
    if user_id == "anonymous-user":
        return {"status": "skipped", "reason": "No user ID provided."}
    result = membership_service.check_milestones(user_id)
    return {"status": "checked", "result": result}

# --- Support Portal (HTML) ---
@app.get("/faq", response_class=HTMLResponse)
async def faq_page(request: Request):
    return templates.TemplateResponse("faq.html", {"request": request, "faqs": support_service.FAQS})

@app.get("/tickets", response_class=HTMLResponse)
async def view_tickets(request: Request):
    from firebase_admin import firestore
    tickets_ref = db.collection('Tickets').order_by('created_at', direction=firestore.Query.DESCENDING).stream()
    tickets = [{"id": t.id, **t.to_dict()} for t in tickets_ref]
    return templates.TemplateResponse("view_tickets.html", {"request": request, "tickets": tickets})

@app.post("/create_ticket")
async def handle_create_ticket(subject: str = Form(...), message: str = Form(...), user_id: str = Depends(get_user_id)):
    support_service.create_ticket(user_id, subject, message)
    return RedirectResponse(url="/tickets", status_code=303)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", 5000)))
