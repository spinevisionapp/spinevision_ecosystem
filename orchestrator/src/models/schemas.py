from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime

class BookModel(BaseModel):
    isbn: str
    title: str
    author: str
    publisher: Optional[str] = None
    publication_year: Optional[int] = None
    condition_rating: Optional[str] = "Good"
    acquired_price: float = 0.0
    workflow_status: str = "sourced" # sourced, listed, sold
    location_id: Optional[str] = None
    cover_image_url: Optional[str] = None

class ScanModel(BaseModel):
    id: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.now)
    scan_mode: str = "Thrift" # Thrift, Shelf, Spatial
    isbn_detected: Optional[str] = None
    confidence_score: float = 0.0
    buy_decision: Optional[str] = None # Buy, Pass, Research
    image_ref: Optional[str] = None # GCS Path

class ListingModel(BaseModel):
    book_id: str
    platform: str # Amazon, eBay, FBMarketplace
    list_price: float
    status: str = "draft" # draft, active, ended
    external_id: Optional[str] = None
    date_listed: Optional[datetime] = None

class SaleModel(BaseModel):
    book_id: str
    gross_amount: float
    net_amount: float
    cogs: float
    platform_fees: float = 0.0
    shipping_cost: float = 0.0
    date_sold: datetime = Field(default_factory=datetime.now)
    payment_status: str = "completed"

class AnalyticsSnapshot(BaseModel):
    total_revenue: float = 0.0
    total_profit: float = 0.0
    sell_through_rate: float = 0.0
    inventory_valuation: float = 0.0
    sourcing_recommendations: Optional[str] = None
    market_trends: List[str] = []
