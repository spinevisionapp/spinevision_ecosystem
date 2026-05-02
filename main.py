import os
import re
import logging
import json
import base64
import shutil
import time
import hashlib
import tempfile
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning, module="google._upb._message")

from flask import Flask, request, jsonify, render_template, redirect
import google.generativeai as genai
from google.cloud import storage
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import firestore
from support_vision import FAQS
from chatbot import ask_gemini_chatbot
import promotion_engine
import social_media_manager

# Load environment variables for local development
load_dotenv()

# Initialize Flask application
app = Flask(__name__)

# Configure structured logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("spinevision-orchestrator")

# Configure Gemini API
api_key = os.getenv("GEMINI_API_KEY")
genai.configure(api_key=api_key)

# Global resource initialization for efficiency
storage_client = storage.Client()
vision_model = genai.GenerativeModel('gemini-2.0-flash')

# Initialize Firestore for caching
try:
    if not firebase_admin._apps:
        # Use the environment variable for portability
        project_id = os.getenv("FIREBASE_PROJECT_ID", "spinevision-6abad")
        firebase_admin.initialize_app(options={'projectId': project_id})
    db = firestore.client()
except Exception as e:
    logger.warning(f"Failed to initialize Firestore: {e}")
    db = None

def download_image_to_temp(gs_uri):
    """Downloads an image from GCS to a temporary file and returns the path."""
    match = re.match(r'^gs://([^/]+)/(.*)$', gs_uri)
    if not match:
        raise ValueError(f"Invalid gs:// URI format: {gs_uri}")
    bucket_name, blob_name = match.groups()
    
    # Create a unique temp file
    temp_dir = "/tmp/spinevision"
    if not os.path.exists(temp_dir):
        os.makedirs(temp_dir, exist_ok=True)
        
    _, temp_local_path = tempfile.mkstemp(suffix=".jpg", dir=temp_dir)
    
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.download_to_filename(temp_local_path)
    return temp_local_path

def get_authenticated_uid():
    """Extracts the Firebase UID from the API Gateway user info header."""
    # API Gateway passes the decoded JWT payload in this header
    encoded_info = request.headers.get('X-Apigateway-Api-Userinfo')
    if not encoded_info:
        return None
        
    try:
        # Base64url decode the payload (adding padding if necessary)
        padding = '=' * (4 - len(encoded_info) % 4)
        decoded_bytes = base64.urlsafe_b64decode(encoded_info + padding)
        user_info = json.loads(decoded_bytes)
        
        # The Firebase UID is stored in the 'user_id' or 'sub' claim
        return user_info.get('user_id') or user_info.get('sub')
    except Exception as e:
        logger.warning(f"Failed to decode API Gateway user info: {e}")
        return None

def _extract_firestore_value(field_data):
    """Safely extracts a value from a Firestore field dictionary."""
    if not field_data or not isinstance(field_data, dict):
        return None
    return next(iter(field_data.values()))

def _map_firestore_fields(fields_dict):
    """Converts a Firestore mapValue fields dict to a standard Python dict."""
    return {k: _extract_firestore_value(v) for k, v in fields_dict.items()}

def generate_json_with_retry(model, contents, max_retries=2, backoff_factor=1.0):
    """Helper to invoke Gemini with retries and return parsed JSON."""
    generation_config = {"response_mime_type": "application/json"}
    last_err = None
    
    for attempt in range(max_retries + 1):
        try:
            response = model.generate_content(contents, generation_config=generation_config)
            text = response.text.strip()
            
            # Remove Markdown JSON blocks if the model included them
            if text.startswith("```"):
                text = re.sub(r'^```(?:json)?\n?|```$', '', text, flags=re.MULTILINE).strip()
                
            return json.loads(text)
        except json.JSONDecodeError as e:
            logger.warning(f"JSON parsing failed on attempt {attempt + 1}: {e}")
            last_err = e
        except Exception as e:
            logger.warning(f"Gemini API invocation failed on attempt {attempt + 1}: {e}")
            last_err = e
            
        if attempt < max_retries:
            time.sleep(backoff_factor * (2 ** attempt)) # Exponential backoff: 1s, 2s...
            
    raise last_err

def get_user_tier(user_id):
    """Fetches the user's membership tier from Firestore."""
    if not db or not user_id:
        return "Hobbyist"
    try:
        user_doc = db.collection('users').document(user_id).get()
        if user_doc.exists:
            return user_doc.to_dict().get('tier', 'Hobbyist')
    except Exception as e:
        logger.warning(f"Error fetching tier: {e}")
    return "Hobbyist"

def track_and_promote(user_id, usage_type, count=1):
    """Helper to track usage and check for promotions."""
    if not user_id:
        return
    promotion_engine.track_usage(user_id, usage_type, db=db, count=count)
    promo_msg = promotion_engine.check_user_milestones(user_id, db=db)
    if "GRANTING PROMOTION" in promo_msg:
        logger.info(f"Promotion triggered for {user_id}: {promo_msg}")

def cleanup_environment(max_age_hours=12):
    """Automates cleanup of temporary files and caches to save space."""
    temp_dir = "/tmp/spinevision"
    now = time.time()
    cutoff = now - (max_age_hours * 3600)

    # 1. Targeted File System Cleanup
    if os.path.exists(temp_dir):
        for filename in os.listdir(temp_dir):
            filepath = os.path.join(temp_dir, filename)
            if os.path.getmtime(filepath) < cutoff:
                try:
                    if os.path.isfile(filepath) or os.path.islink(filepath):
                        os.unlink(filepath)
                    elif os.path.isdir(filepath):
                        shutil.rmtree(filepath)
                except Exception as e:
                    logger.error(f"Failed to delete {filepath}: {e}")

    # 2. Recursive Project Cache Cleanup
    root_dir = os.path.dirname(os.path.abspath(__file__))
    for root, dirs, files in os.walk(root_dir):
        for d in dirs:
            if d in ["__pycache__", ".pytest_cache"]:
                shutil.rmtree(os.path.join(root, d), ignore_errors=True)
        for f in files:
            if f.endswith((".log", ".tmp", ".pyc", ".pyo")):
                try:
                    os.remove(os.path.join(root, f))
                except OSError: pass

def _process_marketing_automation(analytics_data):
    """Core logic for marketing automation, using the social media manager."""
    logger.info("Processing marketing automation request.")
    try:
        import datetime
        today = datetime.datetime.now().strftime("%A")
        success = social_media_manager.run_daily_automation(today)
        if success:
            return {"status": "success", "message": f"Daily automation completed for {today}"}, 200
        else:
            return {
                "error": {
                    "error_type": "MARKETING_AUTOMATION_FAILED",
                    "message": "Failed to run daily automation.",
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 500
    except Exception as e:
        logger.error(f"Marketing automation failed: {e}", exc_info=True)
        return {
            "error": {
                "error_type": "MARKETING_AUTOMATION_ERROR",
                "message": str(e),
                "retryable": True,
                "suggested_action": "RETRY_LATER"
            }
        }, 500

@app.route('/maintenance/cleanup', methods=['POST'])
def trigger_cleanup():
    cleanup_environment()
    return jsonify({"status": "success", "message": "Cleanup completed"}), 200

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for API Gateway and monitoring."""
    return jsonify({"status": "healthy", "service": "spinevision-orchestrator"}), 200

def _process_metadata_extraction(image_reference):
    """Core logic for extracting book metadata, callable internally."""
    if not image_reference:
        return {
            "error": {
                "error_type": "INVALID_INPUT",
                "message": "The provided image reference is missing.",
                "retryable": False,
                "suggested_action": "PROVIDE_VALID_INPUT"
            }
        }, 400

    logger.info(f"Processing metadata extraction for: {image_reference}")

    # 1. Check Firestore Cache
    cache_ref = None
    if db:
        try:
            # Create a safe document ID from the image URI
            cache_key = hashlib.md5(image_reference.encode('utf-8')).hexdigest()
            cache_ref = db.collection('MetadataCache').document(cache_key)
            cached_doc = cache_ref.get()
            
            if cached_doc.exists:
                logger.info(f"Cache hit for {image_reference}. Returning stored metadata.")
                return {"status": "success", "data": cached_doc.to_dict(), "cached": True}, 200
        except Exception as e:
            logger.warning(f"Failed to read from Firestore cache: {e}")

    temp_path = None
    try:
        # Fetch image from Cloud Storage using a temp file to save memory
        try:
            temp_path = download_image_to_temp(image_reference)
            # Use genai.upload_file for efficient handling of large images
            uploaded_file = genai.upload_file(path=temp_path, mime_type="image/jpeg")
        except Exception as gcs_err:
            logger.error(f"Failed to fetch image from GCS: {gcs_err}", exc_info=True)
            return {
                "error": {
                    "error_type": "INVALID_INPUT",
                    "message": "Could not retrieve the image from the provided reference.",
                    "details": {"original_error": str(gcs_err)},
                    "retryable": False,
                    "suggested_action": "VERIFY_RESOURCE_ID"
                }
            }, 400
            
        # Construct the strict JSON schema prompt (PROMPT 5)
        prompt = """
        Act as OmniVision (SpineVision Image Specialist). Analyze this book image and extract its metadata.
        Return ONLY a valid JSON object matching the exact schema below. Do not include markdown formatting like ```json.
        
        {
          "isbn10": "string or null",
          "isbn13": "string or null",
          "title": "string or null",
          "author": "string or null",
          "publisher": "string or null",
          "publication_year": "string or null",
          "confidence_scores": {
            "isbn": 0.0 to 1.0,
            "title": 0.0 to 1.0,
            "author": 0.0 to 1.0
          },
          "error_flags": ["string"]
        }
        """
        
        try:
            ai_metadata = generate_json_with_retry(vision_model, [prompt, uploaded_file])
        except json.JSONDecodeError as parse_err:
            return {
                "error": {
                    "error_type": "AI_RESPONSE_FORMAT_ERROR",
                    "message": "The AI model returned improperly formatted data.",
                    "details": {"parse_error": str(parse_err)},
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 502
        
        # 2. Save extracted data to Firestore Cache
        if cache_ref:
            try:
                cache_ref.set(ai_metadata)
                logger.info(f"Saved metadata to cache for {image_reference}")
            except Exception as e:
                logger.warning(f"Failed to write to Firestore cache: {e}")
                
        return {"status": "success", "data": ai_metadata, "cached": False}, 200
        
    except Exception as e:
        logger.error(f"Gemini API invocation failed: {e}", exc_info=True)
        # Fallback error for downstream service failure (PROMPT 32)
        return {
            "error": {"error_type": "GEMINI_API_ERROR", "message": "The AI model is temporarily unavailable.", "retryable": True, "suggested_action": "RETRY_LATER"}
        }, 503
    finally:
        # Clean up the temp file
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except: pass

@app.route('/extract_metadata', methods=['POST'])
def extract_metadata():
    """Extracts book metadata from an image."""
    user_id = get_authenticated_uid()
    data = request.get_json() or {}
    image_reference = data.get('image_reference')
    
    result, status_code = _process_metadata_extraction(image_reference)
    
    if status_code == 200 and user_id:
        track_and_promote(user_id, "scan")
        
    return jsonify(result), status_code

def _process_extract_pricing(image_reference, book_data=None):
    """Core logic for extracting pricing information, callable internally."""
    if not image_reference and not book_data:
        return {
            "error": {
                "error_type": "INVALID_INPUT",
                "message": "Either 'image_reference' or 'book_data' must be provided.",
                "retryable": False,
                "suggested_action": "PROVIDE_VALID_INPUT"
            }
        }, 400

    logger.info(f"Processing pricing extraction for: {image_reference or book_data.get('title', 'Unknown')}")
    
    temp_path = None
    try:
        contents = []
        if image_reference:
            try:
                temp_path = download_image_to_temp(image_reference)
                uploaded_file = genai.upload_file(path=temp_path, mime_type="image/jpeg")
                contents.append(uploaded_file)
            except Exception as gcs_err:
                logger.error(f"Failed to fetch image from GCS: {gcs_err}")
                # If we have book_data, we can still proceed without the image
                if not book_data:
                    return {
                        "error": {
                            "error_type": "INVALID_INPUT",
                            "message": "Could not retrieve the image and no book data provided.",
                            "retryable": False,
                            "suggested_action": "VERIFY_RESOURCE_ID"
                        }
                    }, 400

        prompt = f"""
        Act as ProfitVision (SpineVision Pricing Expert). Analyze the provided information and estimate real-time market values.
        
        {f"Book Data: {json.dumps(book_data, indent=2)}" if book_data else ""}
        
        Return ONLY a valid JSON object matching the exact schema below. Do not include markdown formatting like ```json.
        
        {{
          "original_retail_price": number or null,
          "estimated_market_value": number or null,
          "comparable_prices": [
            {{ "marketplace": "Amazon", "price": number, "condition": "Good", "url": "string" }},
            {{ "marketplace": "eBay", "price": number, "condition": "Good", "url": "string" }}
          ],
          "sales_rank": number or null,
          "sales_velocity": "High" | "Medium" | "Low",
          "demand_score": 0 to 100,
          "is_bolo": boolean (Be On Look Out - high profit potential)
        }}
        """
        contents.append(prompt)
        
        try:
            pricing_data = generate_json_with_retry(vision_model, contents)
        except json.JSONDecodeError as parse_err:
            return {
                "error": {
                    "error_type": "AI_RESPONSE_FORMAT_ERROR",
                    "message": "The AI model returned improperly formatted data.",
                    "details": {"parse_error": str(parse_err)},
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 502
            
        return {"status": "success", "data": pricing_data}, 200
        
    except Exception as e:
        logger.error(f"Gemini API invocation failed: {e}", exc_info=True)
        return {
            "error": {"error_type": "GEMINI_API_ERROR", "message": "The AI model is temporarily unavailable.", "retryable": True, "suggested_action": "RETRY_LATER"}
        }, 503
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except: pass

@app.route('/extract_pricing', methods=['POST'])
def extract_pricing():
    """Extracts pricing information for a book."""
    data = request.get_json() or {}
    image_reference = data.get('image_reference')
    book_data = data.get('book_data')
    
    result, status_code = _process_extract_pricing(image_reference, book_data)
    return jsonify(result), status_code

def _process_analyze_condition(image_reference):
    """Core logic for analyzing book condition from an image, callable internally."""
    if not image_reference:
        return {
            "error": {
                "error_type": "INVALID_INPUT",
                "message": "The provided image reference is missing.",
                "retryable": False,
                "suggested_action": "PROVIDE_VALID_INPUT"
            }
        }, 400

    logger.info(f"Processing condition analysis request for: {image_reference}")
    
    temp_path = None
    try:
        try:
            temp_path = download_image_to_temp(image_reference)
            uploaded_file = genai.upload_file(path=temp_path, mime_type="image/jpeg")
        except Exception as gcs_err:
            logger.error(f"Failed to fetch image from GCS: {gcs_err}", exc_info=True)
            return {
                "error": {
                    "error_type": "INVALID_INPUT",
                    "message": "Could not retrieve the image from the provided reference.",
                    "details": {"original_error": str(gcs_err)},
                    "retryable": False,
                    "suggested_action": "VERIFY_RESOURCE_ID"
                }
            }, 400
            
        prompt = """
        Act as ConditionVision (SpineVision Condition Analyst). Analyze this book image and evaluate its physical condition.
        Return ONLY a valid JSON object matching the exact schema below. Do not include markdown formatting like ```json.
        
        {
          "condition_grade": "Like New" | "Very Good" | "Good" | "Acceptable" | "Poor",
          "defects": ["string"],
          "confidence_score": 0.0 to 1.0,
          "notes": "string or null"
        }
        """
        
        try:
            condition_data = generate_json_with_retry(vision_model, [prompt, uploaded_file])
        except json.JSONDecodeError as parse_err:
            return {
                "error": {
                    "error_type": "AI_RESPONSE_FORMAT_ERROR",
                    "message": "The AI model returned improperly formatted data.",
                    "details": {"parse_error": str(parse_err)},
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 502
            
        return {"status": "success", "data": condition_data}, 200
        
    except Exception as e:
        logger.error(f"Gemini API invocation failed: {e}", exc_info=True)
        return {
            "error": {"error_type": "GEMINI_API_ERROR", "message": "The AI model is temporarily unavailable.", "retryable": True, "suggested_action": "RETRY_LATER"}
        }, 503
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except: pass

@app.route('/analyze_condition', methods=['POST'])
def analyze_condition():
    """Analyzes the condition of a book from an image."""
    data = request.get_json() or {}
    image_reference = data.get('image_reference')
    
    result, status_code = _process_analyze_condition(image_reference)
    return jsonify(result), status_code

def _process_batch_shelf(image_reference):
    """Core logic for bulk inventory digitization from a shelf image."""
    if not image_reference:
        return {
            "error": {
                "error_type": "INVALID_INPUT",
                "message": "The provided image reference is missing.",
                "retryable": False,
                "suggested_action": "PROVIDE_VALID_INPUT"
            }
        }, 400

    logger.info(f"Processing batch shelf scan for: {image_reference}")
    
    temp_path = None
    try:
        try:
            temp_path = download_image_to_temp(image_reference)
            uploaded_file = genai.upload_file(path=temp_path, mime_type="image/jpeg")
        except Exception as gcs_err:
            logger.error(f"Failed to fetch image from GCS: {gcs_err}")
            return {
                "error": {
                    "error_type": "INVALID_INPUT",
                    "message": "Could not retrieve the image from the provided reference.",
                    "details": {"original_error": str(gcs_err)},
                    "retryable": False,
                    "suggested_action": "VERIFY_RESOURCE_ID"
                }
            }, 400
            
        prompt = """
        Act as ShelfVision (SpineVision Bulk Scanner). Analyze this image of a bookshelf and extract metadata for EVERY book visible.
        Return ONLY a valid JSON object matching the exact schema below. Do not include markdown formatting like ```json.
        
        {
          "batch_id": "string (unique)",
          "books": [
            {
              "title": "string or null",
              "author": "string or null",
              "isbn": "string or null",
              "condition_estimate": "Good" | "Acceptable" | "Poor",
              "confidence_score": 0.0 to 1.0
            }
          ],
          "total_detected": number
        }
        """
        
        try:
            batch_data = generate_json_with_retry(vision_model, [prompt, uploaded_file])
        except json.JSONDecodeError as parse_err:
            return {
                "error": {
                    "error_type": "AI_RESPONSE_FORMAT_ERROR",
                    "message": "The AI model returned improperly formatted data.",
                    "details": {"parse_error": str(parse_err)},
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 502
            
        return {"status": "success", "data": batch_data}, 200
        
    except Exception as e:
        logger.error(f"Gemini API invocation failed: {e}", exc_info=True)
        return {
            "error": {"error_type": "GEMINI_API_ERROR", "message": "The AI model is temporarily unavailable.", "retryable": True, "suggested_action": "RETRY_LATER"}
        }, 503
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except: pass

@app.route('/batch_process_shelf', methods=['POST'])
def batch_process_shelf():
    """Processes a batch of book spines from an image."""
    user_id = get_authenticated_uid()
    user_tier = get_user_tier(user_id)
    
    # ShelfVision restricted to Mid Tier and above
    if user_tier == "Hobbyist" and user_id != "anonymous-user":
        return jsonify({"error": "This feature is restricted to Pro and Enterprise users."}), 403
        
    data = request.get_json() or {}
    image_reference = data.get('image_reference')
    
    result, status_code = _process_batch_shelf(image_reference)
    
    if status_code == 200 and user_id:
        count = result.get('data', {}).get('total_detected', 1)
        track_and_promote(user_id, "scan", count=count)
        
    return jsonify(result), status_code

def _process_listing_generation(book_data, platform):
    """Core logic for generating a marketplace listing, callable internally."""
    if not book_data or not platform:
        return {
            "error": {
                "error_type": "INVALID_INPUT",
                "message": "Both 'book_data' and 'platform' are required.",
                "retryable": False,
                "suggested_action": "PROVIDE_VALID_INPUT"
            }
        }, 400

    logger.info(f"Processing listing generation for: {book_data.get('title', 'Unknown')} on {platform}")
    
    try:
        prompt = f"""
        Act as ListVision (SpineVision Ecommerce Expert) on {platform}. Create a highly optimized product listing.
        
        Book Data:
        {json.dumps(book_data, indent=2)}
        
        Return ONLY a valid JSON object matching the exact schema below. Do not include markdown formatting like ```json.
        
        {{
          "title": "string (optimized listing title)",
          "description": "string (detailed and engaging description)",
          "keywords": ["string"],
          "recommended_price": number or null
        }}
        """
        
        try:
            listing_data = generate_json_with_retry(vision_model, prompt)
        except json.JSONDecodeError as parse_err:
            return {
                "error": {
                    "error_type": "AI_RESPONSE_FORMAT_ERROR",
                    "message": "The AI model returned improperly formatted data.",
                    "details": {"parse_error": str(parse_err)},
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 502
            
        return {"status": "success", "data": listing_data}, 200
        
    except Exception as e:
        logger.error(f"Gemini API invocation failed: {e}", exc_info=True)
        return {
            "error": {"error_type": "GEMINI_API_ERROR", "message": "The AI model is temporarily unavailable.", "retryable": True, "suggested_action": "RETRY_LATER"}
        }, 503

@app.route('/generate_listing', methods=['POST'])
def generate_listing():
    """Generates a marketplace listing for a book."""
    user_id = get_authenticated_uid()
    data = request.get_json() or {}
    book_data = data.get('book_data')
    platform = data.get('platform')
    
    result, status_code = _process_listing_generation(book_data, platform)
    
    if status_code == 200 and user_id:
        track_and_promote(user_id, "listing")
        
    return jsonify(result), status_code

def _process_library_catalog(image_reference):
    """Core logic for cataloging a book into the library, callable internally."""
    if not image_reference:
        return {
            "error": {
                "error_type": "INVALID_INPUT",
                "message": "The provided image reference is missing.",
                "retryable": False,
                "suggested_action": "PROVIDE_VALID_INPUT"
            }
        }, 400

    logger.info(f"Processing library catalog request for: {image_reference}")
    
    temp_path = None
    try:
        try:
            temp_path = download_image_to_temp(image_reference)
            uploaded_file = genai.upload_file(path=temp_path, mime_type="image/jpeg")
        except Exception as gcs_err:
            logger.error(f"Failed to fetch image from GCS: {gcs_err}", exc_info=True)
            return {
                "error": {
                    "error_type": "INVALID_INPUT",
                    "message": "Could not retrieve the image from the provided reference.",
                    "details": {"original_error": str(gcs_err)},
                    "retryable": False,
                    "suggested_action": "VERIFY_RESOURCE_ID"
                }
            }, 400
            
        prompt = """
        Act as CatalogVision (SpineVision Librarian). Analyze this book image and extract its metadata for a library catalog.
        Return ONLY a valid JSON object matching the exact schema below. Do not include markdown formatting like ```json.
        
        {
          "isbn": "string or null",
          "title": "string or null",
          "author": "string or null",
          "publisher": "string or null",
          "publication_year": "string or null",
          "binding_type": "string or null",
          "condition": "string or null",
          "confidence_score": 0.0 to 1.0
        }
        """
        
        try:
            catalog_data = generate_json_with_retry(vision_model, [prompt, uploaded_file])
        except json.JSONDecodeError as parse_err:
            return {
                "error": {
                    "error_type": "AI_RESPONSE_FORMAT_ERROR",
                    "message": "The AI model returned improperly formatted data.",
                    "details": {"parse_error": str(parse_err)},
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 502
            
        return {"status": "success", "data": catalog_data}, 200
        
    except Exception as e:
        logger.error(f"Gemini API invocation failed: {e}", exc_info=True)
        return {
            "error": {"error_type": "GEMINI_API_ERROR", "message": "The AI model is temporarily unavailable.", "retryable": True, "suggested_action": "RETRY_LATER"}
        }, 503
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except: pass

@app.route('/library_catalog', methods=['POST'])
def library_catalog():
    """Catalogs a book into the user's library from an image."""
    data = request.get_json() or {}
    image_reference = data.get('image_reference')
    
    result, status_code = _process_library_catalog(image_reference)
    return jsonify(result), status_code

def _process_buy_decision(book_data, user_settings):
    """Core logic for providing a buy/no-buy recommendation, callable internally."""
    if not book_data or not user_settings:
        return {
            "error": {
                "error_type": "INVALID_INPUT",
                "message": "Both 'book_data' and 'user_settings' are required.",
                "retryable": False,
                "suggested_action": "PROVIDE_VALID_INPUT"
            }
        }, 400

    # Default settings for Hobbyist if none provided
    settings = user_settings or {"minimum_profit_margin": 10.0}
    user_id = book_data.get('user_id', 'anonymous')
    tier = get_user_tier(user_id)

    logger.info(f"Received buy decision request for book: {book_data.get('title', 'Unknown')}")
    
    try:
        # Tier-based persona adjustment
        system_role = "SpineVision BuyExpert (Enterprise Strategic Mode)" if tier in ["Pro", "Enterprise"] else "SpineVision BuyExpert (Hobbyist Mode)"
        
        if tier == "Hobbyist":
            prompt_instruction = "Provide a simple buy/pass decision based on basic ROI and minimum profit thresholds."
        else:
            prompt_instruction = """
            Provide a deep-dive strategic analysis. Evaluate:
            1. Long-tail vs. short-tail ROI.
            2. Storage cost impact vs. expected sell-through rate.
            3. Seasonal demand peaks (is this a 'hold' for a specific month?).
            4. Comparative rarity across multiple marketplaces.
            """

        prompt = f"""
        Act as {system_role}. {prompt_instruction}
        
        Book Data:
        {json.dumps(book_data, indent=2)}
        
        User Settings (Thresholds):
        {json.dumps(settings, indent=2)}
        
        Return ONLY a valid JSON object matching the exact schema below. Do not include markdown formatting like ```json.
        
        {{
          "decision": "buy" | "pass",
          "confidence_score": 0.0 to 1.0,
          "estimated_profit": number or null,
          "roi_percentage": number,
          "risk_level": "Low" | "Medium" | "High",
          "reason": "string (A short explanation of why to buy or pass based on data and thresholds.)",
          "strategic_recommendation": "string (e.g. 'List immediately on eBay' or 'Hold for Q4 textbook season')"
        }}
        """
        
        try:
            ai_decision = generate_json_with_retry(vision_model, prompt)
        except json.JSONDecodeError as parse_err:
            return {
                "error": {
                    "error_type": "AI_RESPONSE_FORMAT_ERROR",
                    "message": "The AI model returned improperly formatted data.",
                    "details": {"parse_error": str(parse_err)},
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 502
            
        return {"status": "success", "data": ai_decision}, 200
        
    except Exception as e:
        logger.error(f"Gemini API invocation failed: {e}", exc_info=True)
        return {
            "error": {"error_type": "GEMINI_API_ERROR", "message": "The AI model is temporarily unavailable.", "retryable": True, "suggested_action": "RETRY_LATER"}
        }, 503

@app.route('/buy_decision', methods=['POST'])
def buy_decision():
    """Provides a buy/no-buy recommendation for a scanned book."""
    data = request.get_json() or {}
    book_data = data.get('book_data')
    user_settings = data.get('user_settings')
    
    result, status_code = _process_buy_decision(book_data, user_settings)
    return jsonify(result), status_code

def _process_analytics_enrichment(raw_data):
    """Core logic for enriching analytics with AI-driven insights."""
    if not raw_data:
        return {
            "error": {
                "error_type": "INVALID_INPUT",
                "message": "The provided raw data is missing.",
                "retryable": False,
                "suggested_action": "PROVIDE_VALID_INPUT"
            }
        }, 400

    logger.info("Processing analytics enrichment request.")
    
    try:
        prompt = f"""
        Act as AnalyticsVision (SpineVision Strategic BI Lead). 
        Analyze the following raw inventory and sales data to provide high-level strategic intelligence.
        
        Raw Data:
        {json.dumps(raw_data, indent=2)}
        
        Return ONLY a valid JSON object matching the exact schema below. Do not include markdown formatting like ```json.
        
        {{
          "total_inventory_value": number,
          "projected_profit": number,
          "top_performing_categories": ["string"],
          "sourcing_recommendations": "string (Identify specific niches, authors, or categories to target based on current sales velocity.)",
          "market_trends": ["string (e.g. 'Increasing demand for mid-century design monographs')"],
          "low_stock_alerts": ["string"],
          "efficiency_score": 0.0 to 1.0,
          "geographic_sourcing_advice": "string (Recommend specific store types or regions for sourcing this inventory mix.)"
        }}
        """
        
        try:
            enriched_data = generate_json_with_retry(vision_model, prompt)
        except json.JSONDecodeError as parse_err:
            return {
                "error": {
                    "error_type": "AI_RESPONSE_FORMAT_ERROR",
                    "message": "The AI model returned improperly formatted data.",
                    "details": {"parse_error": str(parse_err)},
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 502
            
        return {"status": "success", "data": enriched_data}, 200
        
    except Exception as e:
        logger.error(f"Gemini API invocation failed: {e}", exc_info=True)
        return {
            "error": {"error_type": "GEMINI_API_ERROR", "message": "The AI model is temporarily unavailable.", "retryable": True, "suggested_action": "RETRY_LATER"}
        }, 503

def _process_bundle_optimizer(books_data):
    """Core logic for optimizing book bundles."""
    if not books_data:
        return {
            "error": {
                "error_type": "INVALID_INPUT",
                "message": "The provided books data is missing.",
                "retryable": False,
                "suggested_action": "PROVIDE_VALID_INPUT"
            }
        }, 400

    logger.info("Processing bundle optimization request.")
    
    try:
        prompt = f"""
        Act as BundleVision (SpineVision Optimization Expert). 
        Analyze the following list of books and provide a strategy for bundling them into a high-value listing.
        
        Books:
        {json.dumps(books_data, indent=2)}
        
        Return ONLY a valid JSON object matching the exact schema below. Do not include markdown formatting like ```json.
        
        {{
          "bundle_title": "string (optimized for SEO)",
          "target_audience": "string",
          "suggested_price": number,
          "roi_improvement_percent": number,
          "marketing_strategy": "string",
          "included_book_ids": ["string"]
        }}
        """
        
        try:
            bundle_advice = generate_json_with_retry(vision_model, prompt)
        except json.JSONDecodeError as parse_err:
            return {
                "error": {
                    "error_type": "AI_RESPONSE_FORMAT_ERROR",
                    "message": "The AI model returned improperly formatted data.",
                    "details": {"parse_error": str(parse_err)},
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 502
            
        return {"status": "success", "data": bundle_advice}, 200
        
    except Exception as e:
        logger.error(f"Gemini API invocation failed: {e}", exc_info=True)
        return {
            "error": {"error_type": "GEMINI_API_ERROR", "message": "The AI model is temporarily unavailable.", "retryable": True, "suggested_action": "RETRY_LATER"}
        }, 503

def _process_box_optimizer(inventory, current_weight, target_weight=45.0, max_weight=50.0):
    """AI logic for FBA box optimization using Gemini."""
    logger.info(f"Processing box optimization request. Current: {current_weight}, Target: {target_weight}")
    
    try:
        prompt = f"""
        Act as LogisticsVision (SpineVision FBA Expert). 
        Help the user optimize an FBA shipping box. 
        Target weight: {target_weight} lbs. Maximum weight: {max_weight} lbs.
        Current box weight: {current_weight} lbs.
        
        Inventory available:
        {json.dumps(inventory[:30], indent=2)}
        
        Suggest the BEST combination of items to add to the box to reach the target weight exactly without exceeding the maximum.
        Prioritize items with higher 'estimated_market_value' if available.
        
        Return ONLY a valid JSON object matching the exact schema below:
        
        {{
          "suggested_item_ids": ["string"],
          "projected_final_weight": number,
          "logistics_advice": "string (e.g. 'This mix balances the box well. Place heavier items at the bottom.')",
          "shipping_efficiency_gain": "string (e.g. '+12% margin')"
        }}
        """
        
        try:
            logistics_advice = generate_json_with_retry(vision_model, prompt)
        except json.JSONDecodeError as parse_err:
            return {
                "error": {
                    "error_type": "AI_RESPONSE_FORMAT_ERROR",
                    "message": "The AI model returned improperly formatted data.",
                    "details": {"parse_error": str(parse_err)},
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 502
            
        return {"status": "success", "data": logistics_advice}, 200
        
    except Exception as e:
        logger.error(f"Logistics optimization failed: {e}", exc_info=True)
        return {
            "error": {"error_type": "GEMINI_API_ERROR", "message": "The AI model is temporarily unavailable.", "retryable": True, "suggested_action": "RETRY_LATER"}
        }, 503

def _process_reprice_vision(inventory):
    """AI logic for market repricing alerts."""
    logger.info("Processing repricing analysis for inventory.")
    
    try:
        prompt = f"""
        Act as RepriceVision (SpineVision Market Analyst). 
        Analyze the following inventory and identify books whose market value has significantly increased.
        
        Inventory:
        {json.dumps(inventory[:30], indent=2)}
        
        Compare 'previous_value' (if exists) or 'purchase_price' against current market estimates.
        Return ONLY a valid JSON object matching the schema:
        
        {{
          "alerts": [
            {{
              "id": "string",
              "title": "string",
              "price_delta_percent": number,
              "new_suggested_price": number,
              "action_required": "Increase Price" | "Monitor",
              "reason": "string"
            }}
          ],
          "market_sentiment": "string"
        }}
        """
        
        try:
            repricing_alerts = generate_json_with_retry(vision_model, prompt)
        except json.JSONDecodeError as parse_err:
            return {
                "error": {
                    "error_type": "AI_RESPONSE_FORMAT_ERROR",
                    "message": "The AI model returned improperly formatted data.",
                    "details": {"parse_error": str(parse_err)},
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 502
            
        return {"status": "success", "data": repricing_alerts}, 200
        
    except Exception as e:
        logger.error(f"Repricing analysis failed: {e}", exc_info=True)
        return {
            "error": {"error_type": "GEMINI_API_ERROR", "message": "The AI model is temporarily unavailable.", "retryable": True, "suggested_action": "RETRY_LATER"}
        }, 503

def _process_receipt_extraction(image_reference):
    """Core logic for extracting data from a receipt image."""
    if not image_reference:
        return {
            "error": {
                "error_type": "INVALID_INPUT",
                "message": "The provided image reference is missing.",
                "retryable": False,
                "suggested_action": "PROVIDE_VALID_INPUT"
            }
        }, 400

    logger.info(f"Processing receipt extraction for: {image_reference}")
    
    temp_path = None
    try:
        try:
            temp_path = download_image_to_temp(image_reference)
            uploaded_file = genai.upload_file(path=temp_path, mime_type="image/jpeg")
        except Exception as gcs_err:
            logger.error(f"Failed to fetch image from GCS: {gcs_err}")
            return {
                "error": {
                    "error_type": "INVALID_INPUT",
                    "message": "Could not retrieve the image from the provided reference.",
                    "retryable": False,
                    "suggested_action": "VERIFY_RESOURCE_ID"
                }
            }, 400
            
        prompt = """
        Act as LedgerVision (SpineVision Expense Tracker). Analyze this receipt from a thrift store or bookstore. Extract the financial details.
        Return ONLY a valid JSON object matching the exact schema below. Do not include markdown formatting like ```json.
        
        {
          "merchant_name": "string",
          "date": "YYYY-MM-DD",
          "total_amount": number,
          "tax_amount": number,
          "items_count": number,
          "category": "COGS" | "Supplies" | "Other",
          "currency": "USD"
        }
        """
        
        try:
            receipt_data = generate_json_with_retry(vision_model, [prompt, uploaded_file])
        except json.JSONDecodeError as parse_err:
            return {
                "error": {
                    "error_type": "AI_RESPONSE_FORMAT_ERROR",
                    "message": "The AI model returned improperly formatted data.",
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 502
            
        return {"status": "success", "data": receipt_data}, 200
        
    except Exception as e:
        logger.error(f"Gemini API invocation failed: {e}", exc_info=True)
        return {
            "error": {"error_type": "GEMINI_API_ERROR", "message": "The AI model is temporarily unavailable.", "retryable": True, "suggested_action": "RETRY_LATER"}
        }, 503
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except: pass

@app.route('/extract_receipt', methods=['POST'])
def extract_receipt():
    """Extracts data from a purchase receipt."""
    user_id = get_authenticated_uid()
    user_tier = get_user_tier(user_id)
    
    # TaxVision restricted to Top Tier
    if user_tier in ["Hobbyist", "Pro"] and user_id != "anonymous-user":
        return jsonify({"error": "This feature is restricted to Enterprise users."}), 403
        
    data = request.get_json() or {}
    image_reference = data.get('image_reference')
    
    result, status_code = _process_receipt_extraction(image_reference)
    return jsonify(result), status_code

@app.route('/analytics_enrichment', methods=['POST'])
def analytics_enrichment():
    """Provides AI-driven insights for inventory data."""
    user_id = get_authenticated_uid()
    user_tier = get_user_tier(user_id)
    
    # Analytics/Vision restricted to Mid Tier and above
    if user_tier == "Hobbyist" and user_id != "anonymous-user":
        return jsonify({"error": "This feature is restricted to Pro and Enterprise users."}), 403
        
    data = request.get_json() or {}
    raw_data = data.get('raw_data')
    
    result, status_code = _process_analytics_enrichment(raw_data)
    return jsonify(result), status_code

@app.route('/bundle_optimizer', methods=['POST'])
def bundle_optimizer():
    """Optimizes a bundle of books for resale."""
    user_id = get_authenticated_uid()
    user_tier = get_user_tier(user_id)
    
    # BundleVision restricted to Top Tier
    if user_tier in ["Hobbyist", "Pro"] and user_id != "anonymous-user":
        return jsonify({"error": "This feature is restricted to Enterprise users."}), 403
        
    data = request.get_json() or {}
    books_data = data.get('books')
    
    result, status_code = _process_bundle_optimizer(books_data)
    return jsonify(result), status_code

@app.route('/box_optimizer', methods=['POST'])
def box_optimizer():
    """Optimizes an FBA shipping box weight."""
    user_id = get_authenticated_uid()
    user_tier = get_user_tier(user_id)
    
    # LogisticsVision restricted to Top Tier
    if user_tier in ["Hobbyist", "Pro"] and user_id != "anonymous-user":
        return jsonify({"error": "This feature is restricted to Enterprise users."}), 403
        
    data = request.get_json() or {}
    inventory = data.get('inventory', [])
    current_weight = data.get('current_weight', 0.0)
    
    result, status_code = _process_box_optimizer(inventory, current_weight)
    return jsonify(result), status_code

@app.route('/reprice_vision', methods=['POST'])
def reprice_vision():
    """Analyzes inventory for market price increases."""
    user_id = get_authenticated_uid()
    user_tier = get_user_tier(user_id)
    
    # RepriceVision restricted to Pro and Enterprise
    if user_tier == "Hobbyist" and user_id != "anonymous-user":
        return jsonify({"error": "This feature is restricted to Pro and Enterprise users."}), 403
        
    data = request.get_json() or {}
    inventory = data.get('inventory', [])
    
    result, status_code = _process_reprice_vision(inventory)
    return jsonify(result), status_code

def _extract_task_data(fields):
    """Helper to extract book_data, metadata, and user_settings from Eventarc fields."""
    data = {}
    
    # Check for book_data
    bd_field = fields.get('book_data', {})
    if 'stringValue' in bd_field:
        try:
            data['book_data'] = json.loads(bd_field['stringValue'])
        except: data['book_data'] = {}
    elif 'mapValue' in bd_field:
        data['book_data'] = _map_firestore_fields(bd_field.get('mapValue', {}).get('fields', {}))
        
    # Check for metadata
    meta_field = fields.get('metadata', {})
    if 'stringValue' in meta_field:
        try:
            data['metadata'] = json.loads(meta_field['stringValue'])
        except: data['metadata'] = {}
    elif 'mapValue' in meta_field:
        data['metadata'] = _map_firestore_fields(meta_field.get('mapValue', {}).get('fields', {}))

    # Check for user_settings
    us_field = fields.get('user_settings', {})
    if 'stringValue' in us_field:
        try:
            data['user_settings'] = json.loads(us_field['stringValue'])
        except: data['user_settings'] = {}
    elif 'mapValue' in us_field:
        data['user_settings'] = _map_firestore_fields(us_field.get('mapValue', {}).get('fields', {}))
        
    return data.get('book_data', {}), data.get('metadata', {}), data.get('user_settings', {})

def _process_market_forecast(book_data):
    """Core logic for market trend forecasting and seasonal demand prediction."""
    if not book_data:
        return {
            "error": {
                "error_type": "INVALID_INPUT",
                "message": "Book data is required for forecasting.",
                "retryable": False,
                "suggested_action": "PROVIDE_VALID_INPUT"
            }
        }, 400

    logger.info(f"Processing market forecast for: {book_data.get('title', 'Unknown')}")
    
    try:
        prompt = f"""
        Act as ForecastVision (SpineVision Market Strategist). Analyze the provided book data and predict future market trends.
        
        Book Data:
        {json.dumps(book_data, indent=2)}
        
        Return ONLY a valid JSON object matching the exact schema below. Do not include markdown formatting like ```json.
        
        {{
          "forecast_horizon": "6 months",
          "demand_trend": "Increasing" | "Stable" | "Decreasing",
          "price_volatility": "High" | "Low",
          "optimal_selling_season": "string (e.g., 'Late Summer / Back to School')",
          "seasonal_multipliers": {{
            "Q1": number, "Q2": number, "Q3": number, "Q4": number
          }},
          "market_risk_factors": ["string"],
          "strategic_advice": "string"
        }}
        """
        
        try:
            forecast_data = generate_json_with_retry(vision_model, prompt)
        except json.JSONDecodeError as parse_err:
            return {
                "error": {
                    "error_type": "AI_RESPONSE_FORMAT_ERROR",
                    "message": "The AI model returned improperly formatted data.",
                    "details": {"parse_error": str(parse_err)},
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 502
            
        return {"status": "success", "data": forecast_data}, 200
        
    except Exception as e:
        logger.error(f"Gemini API invocation failed: {e}", exc_info=True)
        return {
            "error": {"error_type": "GEMINI_API_ERROR", "message": "The AI model is temporarily unavailable.", "retryable": True, "suggested_action": "RETRY_LATER"}
        }, 503

@app.route('/market_forecast', methods=['POST'])
def market_forecast():
    """Provides market trend forecasting for a book."""
    user_id = get_authenticated_uid()
    user_tier = get_user_tier(user_id)
    
    # ForecastVision restricted to Top Tier
    if user_tier in ["Hobbyist", "Pro"] and user_id != "anonymous-user":
        return jsonify({"error": "This feature is restricted to Enterprise users."}), 403
        
    data = request.get_json() or {}
    book_data = data.get('book_data')
    
    result, status_code = _process_market_forecast(book_data)
    return jsonify(result), status_code

def _process_set_analysis(image_reference, metadata=None):
    """Core logic for identifying book sets and missing volumes."""
    if not image_reference and not metadata:
        return {
            "error": {
                "error_type": "INVALID_INPUT",
                "message": "Either 'image_reference' or 'metadata' must be provided.",
                "retryable": False,
                "suggested_action": "PROVIDE_VALID_INPUT"
            }
        }, 400

    logger.info(f"Processing set analysis for: {image_reference or metadata.get('title', 'Unknown')}")
    
    temp_path = None
    try:
        contents = []
        if image_reference:
            try:
                temp_path = download_image_to_temp(image_reference)
                uploaded_file = genai.upload_file(path=temp_path, mime_type="image/jpeg")
                contents.append(uploaded_file)
            except Exception as gcs_err:
                logger.error(f"Failed to fetch image from GCS: {gcs_err}")
                if not metadata:
                    return {
                        "error": {
                            "error_type": "INVALID_INPUT",
                            "message": "Could not retrieve the image and no metadata provided.",
                            "retryable": False,
                            "suggested_action": "VERIFY_RESOURCE_ID"
                        }
                    }, 400

        prompt = f"""
        Act as SetVision (SpineVision Series Expert). Analyze the provided information to identify if it belongs to a set or series.
        
        {f"Metadata: {json.dumps(metadata, indent=2)}" if metadata else ""}
        
        Return ONLY a valid JSON object matching the exact schema below. Do not include markdown formatting like ```json.
        
        {{
          "is_part_of_set": boolean,
          "set_name": "string or null",
          "total_volumes_in_set": number or null,
          "current_volume_number": number or null,
          "missing_volumes": ["string"],
          "set_completion_value_bonus": number (multiplier, e.g., 1.5),
          "rarity_score": 0 to 100,
          "notes": "string or null"
        }}
        """
        contents.append(prompt)
        
        try:
            set_data = generate_json_with_retry(vision_model, contents)
        except json.JSONDecodeError as parse_err:
            return {
                "error": {
                    "error_type": "AI_RESPONSE_FORMAT_ERROR",
                    "message": "The AI model returned improperly formatted data.",
                    "details": {"parse_error": str(parse_err)},
                    "retryable": True,
                    "suggested_action": "RETRY"
                }
            }, 502
            
        return {"status": "success", "data": set_data}, 200
        
    except Exception as e:
        logger.error(f"Gemini API invocation failed: {e}", exc_info=True)
        return {
            "error": {"error_type": "GEMINI_API_ERROR", "message": "The AI model is temporarily unavailable.", "retryable": True, "suggested_action": "RETRY_LATER"}
        }, 503
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except: pass

@app.route('/analyze_set', methods=['POST'])
def analyze_set():
    """Analyzes a book to see if it is part of a set or series."""
    user_id = get_authenticated_uid()
    user_tier = get_user_tier(user_id)
    
    # SetVision restricted to Mid Tier and above
    if user_tier == "Hobbyist" and user_id != "anonymous-user":
        return jsonify({"error": "This feature is restricted to Pro and Enterprise users."}), 403
        
    data = request.get_json() or {}
    image_reference = data.get('image_reference')
    metadata = data.get('metadata')
    
    result, status_code = _process_set_analysis(image_reference, metadata)
    return jsonify(result), status_code

@app.route('/eventarc/firestore_queue', methods=['POST'])
def process_firestore_queue():
    """Eventarc trigger endpoint for Firestore queue updates."""
    event_type = request.headers.get('ce-type')
    
    if not event_type:
        return jsonify({"status": "ignored", "reason": "Missing CloudEvent headers"}), 400

    # We only care about new documents added to the queue
    if event_type not in ['google.cloud.firestore.document.v1.created', 'google.cloud.firestore.document.v1.written']:
        return jsonify({"status": "ignored", "reason": f"Unhandled event type: {event_type}"}), 200

    try:
        event_data = request.get_json() or {}
        document_name = event_data.get('value', {}).get('name', 'Unknown')
        logger.info(f"Eventarc triggered for Firestore document: {document_name}")

        # Extract fields from the structured Firestore Document format
        fields = event_data.get('value', {}).get('fields', {})
        image_reference = fields.get('image_reference', {}).get('stringValue')
        task_type = fields.get('task_type', {}).get('stringValue')

        if task_type == 'extract_metadata' and image_reference:
            logger.info(f"Routing background task to metadata extraction for {image_reference}")
            result, status_code = _process_metadata_extraction(image_reference)
            
            if status_code >= 400:
                logger.error(f"Background metadata extraction failed: {result}")
                # If error is retryable, return a 5xx code to signal Eventarc to retry
                if result.get('error', {}).get('retryable', False):
                    return jsonify({"error": "Transient failure, signaling Eventarc to retry."}), 503
                # Otherwise, fall through to 200 OK so Eventarc safely discards the unrecoverable event

        elif task_type == 'generate_listing':
            platform = fields.get('platform', {}).get('stringValue')
            book_data, _, _ = _extract_task_data(fields)
            
            if book_data and platform:
                logger.info(f"Routing background task to listing generation for {book_data.get('title', 'Unknown')} on {platform}")
                result, status_code = _process_listing_generation(book_data, platform)
                
                if status_code >= 400:
                    logger.error(f"Background listing generation failed: {result}")
                    if result.get('error', {}).get('retryable', False):
                        return jsonify({"error": "Transient failure, signaling Eventarc to retry."}), 503

        elif task_type == 'library_catalog' and image_reference:
            logger.info(f"Routing background task to library cataloging for {image_reference}")
            result, status_code = _process_library_catalog(image_reference)
            
            if status_code >= 400:
                logger.error(f"Background library cataloging failed: {result}")
                if result.get('error', {}).get('retryable', False):
                    return jsonify({"error": "Transient failure, signaling Eventarc to retry."}), 503
                    
        elif task_type == 'buy_decision':
            book_data, _, user_settings = _extract_task_data(fields)
                    
            if book_data and user_settings:
                logger.info(f"Routing background task to buy decision for {book_data.get('title', 'Unknown')}")
                result, status_code = _process_buy_decision(book_data, user_settings)
                
                if status_code >= 400:
                    logger.error(f"Background buy decision failed: {result}")
                    if result.get('error', {}).get('retryable', False):
                        return jsonify({"error": "Transient failure, signaling Eventarc to retry."}), 503

        elif task_type == 'marketing_automation':
            analytics_data, _, _ = _extract_task_data(fields)
            if analytics_data:
                result, status_code = _process_marketing_automation(analytics_data)
                if status_code >= 400 and result.get('error', {}).get('retryable'):
                    return jsonify({"error": "Retryable marketing error"}), 503

        elif task_type == 'extract_receipt' and image_reference:
            logger.info(f"Routing background task to LedgerVision for {image_reference}")
            result, status_code = _process_receipt_extraction(image_reference)
            if status_code >= 400 and result.get('error', {}).get('retryable'):
                return jsonify({"error": "Retryable LedgerVision error"}), 503

        elif task_type == 'analyze_condition' and image_reference:
            logger.info(f"Routing background task to condition analysis for {image_reference}")
            result, status_code = _process_analyze_condition(image_reference)
            
            if status_code >= 400:
                logger.error(f"Background condition analysis failed: {result}")
                if result.get('error', {}).get('retryable', False):
                    return jsonify({"error": "Transient failure, signaling Eventarc to retry."}), 503

        elif task_type == 'analyze_set' and (image_reference or fields.get('metadata')):
            _, metadata, _ = _extract_task_data(fields)
            logger.info(f"Routing background task to set analysis for {image_reference or 'metadata'}")
            result, status_code = _process_set_analysis(image_reference, metadata)
            if status_code >= 400 and result.get('error', {}).get('retryable'):
                return jsonify({"error": "Retryable set analysis error"}), 503

        elif task_type == 'market_forecast':
            book_data, _, _ = _extract_task_data(fields)
            if book_data:
                logger.info(f"Routing background task to market forecast for {book_data.get('title', 'Unknown')}")
                result, status_code = _process_market_forecast(book_data)
                if status_code >= 400 and result.get('error', {}).get('retryable'):
                    return jsonify({"error": "Retryable market forecast error"}), 503

        return jsonify({"status": "success", "processed": document_name}), 200
    except Exception as e:
        logger.error(f"Failed to process Firestore queue event: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500

# Standardized Error Handler (Based on PROMPT 32 Blueprint)
@app.errorhandler(Exception)
def handle_exception(e):
    logger.error(f"Unhandled exception: {e}", exc_info=True)
    error_response = {
        "error": {
            "error_type": "ORCHESTRATOR_INTERNAL_ERROR",
            "message": "An unexpected error occurred while processing your request.",
            "details": {"original_error": str(e)},
            "retryable": False,
            "suggested_action": "CONTACT_SUPPORT"
        }
    }
    # In a real app, you might want to return 400 for specific validation errors
    return jsonify(error_response), 500

@app.route('/faq', methods=['GET'])
def faq():
    """Renders the FAQ page."""
    return render_template('faq.html', faqs=FAQS)

@app.route('/chatbot_page', methods=['GET'])
def chatbot_page():
    """Renders the chatbot page."""
    return render_template('chatbot.html')

@app.route('/chatbot', methods=['POST'])
def chatbot():
    """Handles chatbot requests."""
    user_id = get_authenticated_uid() or "anonymous-user"
    user_tier = get_user_tier(user_id)
    
    # ChatVision restricted to Top Tier
    if user_tier in ["Hobbyist", "Pro"] and user_id != "anonymous-user":
        return jsonify({"error": "This feature is restricted to Enterprise users."}), 403
        
    data = request.get_json() or {}
    question = data.get('question')
    if not question:
        return jsonify({"error": "Question not provided."}), 400
    
    answer = ask_gemini_chatbot(question, user_id=user_id, db=db)
    return jsonify({"answer": answer})

@app.route('/create_ticket_page', methods=['GET'])
def create_ticket_page():
    """Renders the create ticket page."""
    return render_template('create_ticket.html')

@app.route('/create_ticket', methods=['POST'])
def create_ticket():
    """Creates a new ticket."""
    if not db:
        return jsonify({"error": "Firestore not available."}), 500
    
    user_id = get_authenticated_uid() or "anonymous-user"
    user_tier = get_user_tier(user_id)
    
    # SupportVision (Live Agent) restricted to Mid Tier and above
    if user_tier not in ["Pro", "Enterprise"] and user_id != "anonymous-user":
        return jsonify({"error": "This feature is restricted to Mid-Tier and Top-Tier users."}), 403
    
    ticket_ref = db.collection('Tickets').document()
    ticket_ref.set({
        'user_id': user_id,
        'subject': request.form['subject'],
        'message': request.form['message'],
        'status': 'Open',
        'created_at': firestore.SERVER_TIMESTAMP,
        'updated_at': firestore.SERVER_TIMESTAMP
    })
    return redirect('/tickets')

@app.route('/tickets', methods=['GET'])
def view_tickets():
    """Displays a list of all tickets."""
    if not db:
        return jsonify({"error": "Firestore not available."}), 500

    tickets_ref = db.collection('Tickets').order_by('updated_at', direction=firestore.Query.DESCENDING).stream()
    tickets = []
    for ticket in tickets_ref:
        ticket_data = ticket.to_dict()
        ticket_data['id'] = ticket.id
        tickets.append(ticket_data)
        
    return render_template('view_tickets.html', tickets=tickets)

@app.route('/ticket/<ticket_id>', methods=['GET'])
def view_ticket(ticket_id):
    """Displays a single ticket."""
    if not db:
        return jsonify({"error": "Firestore not available."}), 500

    ticket_ref = db.collection('Tickets').document(ticket_id)
    ticket = ticket_ref.get()
    if not ticket.exists:
        return "Ticket not found", 404
    
    ticket_data = ticket.to_dict()
    ticket_data['id'] = ticket.id
    return render_template('view_ticket.html', ticket=ticket_data)

@app.route('/ticket/<ticket_id>/respond', methods=['POST'])
def respond_ticket(ticket_id):
    """Adds a response to a ticket."""
    if not db:
        return jsonify({"error": "Firestore not available."}), 500
        
    ticket_ref = db.collection('Tickets').document(ticket_id)
    ticket_ref.update({
        'status': request.form['status'],
        'response': request.form['response'],
        'updated_at': firestore.SERVER_TIMESTAMP
    })
    return redirect(f'/ticket/{ticket_id}')

if __name__ == '__main__':
    port = int(os.getenv("PORT", 8080))
    app.run(host='0.0.0.0', port=port, debug=True)
