import logging
import re
import os
import tempfile
import hashlib
import json
from google.cloud import storage
from .firebase import db, storage_client
from .ai import model

logger = logging.getLogger("spinevision.vision")

def download_image_to_temp(gs_uri):
    match = re.match(r'^gs://([^/]+)/(.*)$', gs_uri)
    if not match:
        raise ValueError(f"Invalid gs:// URI format: {gs_uri}")
    bucket_name, blob_name = match.groups()

    temp_dir = "/tmp/spinevision"
    os.makedirs(temp_dir, exist_ok=True)
    _, temp_local_path = tempfile.mkstemp(suffix=".jpg", dir=temp_dir)

    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.download_to_filename(temp_local_path)
    return temp_local_path

def generate_json_with_retry(contents, max_retries=2):
    generation_config = {"response_mime_type": "application/json"}
    for attempt in range(max_retries + 1):
        try:
            response = model.generate_content(contents, generation_config=generation_config)
            text = response.text.strip()
            if text.startswith("```"):
                text = re.sub(r'^```(?:json)?\n?|```$', '', text, flags=re.MULTILINE).strip()
            return json.loads(text)
        except Exception as e:
            if attempt == max_retries:
                raise e
    return None

def extract_metadata(image_reference):
    logger.info(f"Extracting metadata for {image_reference}")
    
    # Check cache
    cache_key = hashlib.md5(image_reference.encode('utf-8')).hexdigest()
    cache_ref = db.collection('MetadataCache').document(cache_key)
    cached_doc = cache_ref.get()
    if cached_doc.exists:
        return cached_doc.to_dict()

    temp_path = download_image_to_temp(image_reference)
    try:
        uploaded_file = model.upload_file(path=temp_path, mime_type="image/jpeg")
        prompt = "Act as OmniVision. Analyze this book image and extract metadata as JSON: isbn10, isbn13, title, author, publisher, publication_year."
        metadata = generate_json_with_retry([prompt, uploaded_file])
        if metadata:
            cache_ref.set(metadata)
        return metadata
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

def analyze_condition(image_reference):
    temp_path = download_image_to_temp(image_reference)
    try:
        uploaded_file = model.upload_file(path=temp_path, mime_type="image/jpeg")
        prompt = "Act as ConditionVision. Analyze book condition. Return JSON: condition_grade, defects, confidence_score, notes."
        return generate_json_with_retry([prompt, uploaded_file])
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

def batch_shelf_scan(image_reference):
    temp_path = download_image_to_temp(image_reference)
    try:
        uploaded_file = model.upload_file(path=temp_path, mime_type="image/jpeg")
        prompt = "Act as ShelfVision. Extract metadata for all books on this shelf. Return JSON: batch_id, books (list), total_detected."
        return generate_json_with_retry([prompt, uploaded_file])
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)
