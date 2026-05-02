import pytest
import json
import sys
import os

# Add the current directory to the path so we can import main
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))
from main import app

@pytest.fixture
def client():
    """A test client for the app."""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_check(client):
    """Test the /health endpoint."""
    response = client.get('/health')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'healthy'
    assert data['service'] == 'spinevision-orchestrator'

def test_extract_metadata_endpoint(client, mocker):
    """Test the /extract_metadata routing with mocked AI and GCS."""
    payload = {"image_reference": "gs://fake-bucket/image.jpg"}
    
    # Mock Firestore DB
    mock_db = mocker.patch('main.db')
    mock_db.collection.return_value.document.return_value.get.return_value.exists = False
    
    # Mock GCS download and Gemini upload
    mocker.patch('main.download_image_to_temp', return_value="/tmp/fake.jpg")
    mocker.patch('main.genai.upload_file', return_value=mocker.MagicMock())
    
    # Mock Gemini AI response
    mock_response = mocker.MagicMock()
    mock_response.text = '''
    {
      "isbn10": null,
      "isbn13": "978-0743273565",
      "title": "The Great Gatsby",
      "author": "F. Scott Fitzgerald",
      "publisher": "Scribner",
      "publication_year": "1925",
      "confidence_scores": {
        "isbn": 0.99,
        "title": 0.95,
        "author": 0.98
      },
      "error_flags": []
    }
    '''
    mocker.patch('google.generativeai.GenerativeModel.generate_content', return_value=mock_response)
    
    response = client.post('/extract_metadata', json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert 'data' in data
    assert data['data']['title'] == 'The Great Gatsby'
    assert data['data']['isbn13'] == '978-0743273565'
    assert data.get('cached') is False

def test_extract_metadata_cache_hit(client, mocker):
    """Test the /extract_metadata endpoint returning cached data."""
    payload = {"image_reference": "gs://fake-bucket/cached-image.jpg"}
    
    mock_db = mocker.patch('main.db')
    mock_doc = mocker.MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = {"title": "Cached Book", "isbn13": "1234567890123"}
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc
    
    response = client.post('/extract_metadata', json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert data['cached'] is True
    assert data['data']['title'] == 'Cached Book'

def test_extract_metadata_gcs_failure(client, mocker):
    """Test the /extract_metadata endpoint handling of a GCS download failure."""
    payload = {"image_reference": "gs://invalid-bucket/image.jpg"}
    mock_db = mocker.patch('main.db')
    mock_db.collection.return_value.document.return_value.get.return_value.exists = False
    mocker.patch('main.download_image_to_temp', side_effect=Exception("Simulated GCS Error"))
    
    response = client.post('/extract_metadata', json=payload)
    assert response.status_code == 400
    data = json.loads(response.data)
    assert 'error' in data
    assert data['error']['error_type'] == 'INVALID_INPUT'

def test_buy_decision_endpoint(client, mocker):
    """Test the /buy_decision routing with mocked AI."""
    payload = {
        "book_data": {"title": "The Great Gatsby", "estimated_price": 25.0},
        "user_settings": {"minimum_profit_margin": 10.0}
    }
    
    # Mock Gemini AI response
    mock_response = mocker.MagicMock()
    mock_response.text = '''
    {
      "decision": "buy",
      "confidence_score": 0.95,
      "estimated_profit": 15.0,
      "reason": "Estimated profit exceeds the minimum margin."
    }
    '''
    mocker.patch('google.generativeai.GenerativeModel.generate_content', return_value=mock_response)
    
    response = client.post('/buy_decision', json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert data['data']['decision'] == 'buy'
    assert data['data']['estimated_profit'] == 15.0

def test_buy_decision_missing_input(client):
    """Test the /buy_decision endpoint handling of missing input data."""
    payload = {"book_data": {"title": "The Great Gatsby"}} # Missing user_settings
    response = client.post('/buy_decision', json=payload)
    assert response.status_code == 400

def test_library_catalog_endpoint(client, mocker):
    """Test the /library_catalog routing with mocked AI and GCS."""
    payload = {"image_reference": "gs://fake-bucket/catalog-image.jpg"}
    
    # Mock GCS download and Gemini upload
    mocker.patch('main.download_image_to_temp', return_value="/tmp/fake.jpg")
    mocker.patch('main.genai.upload_file', return_value=mocker.MagicMock())
    
    # Mock Gemini AI response
    mock_response = mocker.MagicMock()
    mock_response.text = '''
    {
      "isbn": "978-1449355739",
      "title": "Learning Python",
      "author": "Mark Lutz",
      "publisher": "O'Reilly Media",
      "publication_year": "2013",
      "binding_type": "Paperback",
      "condition": "Good",
      "confidence_score": 0.98
    }
    '''
    mocker.patch('google.generativeai.GenerativeModel.generate_content', return_value=mock_response)
    
    response = client.post('/library_catalog', json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert 'data' in data
    assert data['data']['title'] == 'Learning Python'
    assert data['data']['isbn'] == '978-1449355739'

def test_library_catalog_missing_input(client):
    """Test the /library_catalog endpoint handling of missing input data."""
    payload = {} # Missing image_reference
    response = client.post('/library_catalog', json=payload)
    assert response.status_code == 400

def test_analyze_condition_endpoint(client, mocker):
    """Test the /analyze_condition routing with mocked AI and GCS."""
    payload = {"image_reference": "gs://fake-bucket/condition-image.jpg"}
    
    # Mock GCS download and Gemini upload
    mocker.patch('main.download_image_to_temp', return_value="/tmp/fake.jpg")
    mocker.patch('main.genai.upload_file', return_value=mocker.MagicMock())
    
    # Mock Gemini AI response
    mock_response = mocker.MagicMock()
    mock_response.text = '''
    {
      "condition_grade": "Good",
      "defects": ["Creased spine", "Slight page yellowing"],
      "confidence_score": 0.90,
      "notes": "Overall sturdy copy but shows signs of wear."
    }
    '''
    mocker.patch('google.generativeai.GenerativeModel.generate_content', return_value=mock_response)
    
    response = client.post('/analyze_condition', json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert data['data']['condition_grade'] == 'Good'
    assert 'Creased spine' in data['data']['defects']

def test_analyze_condition_missing_input(client):
    """Test the /analyze_condition endpoint handling of missing input data."""
    payload = {} # Missing image_reference
    response = client.post('/analyze_condition', json=payload)
    assert response.status_code == 400

def test_generate_listing_endpoint(client, mocker):
    """Test the /generate_listing routing with mocked AI."""
    payload = {
        "book_data": {"title": "The Great Gatsby", "author": "F. Scott Fitzgerald", "condition": "Good"},
        "platform": "eBay"
    }
    
    # Mock Gemini AI response
    mock_response = mocker.MagicMock()
    mock_response.text = '''
    {
      "title": "The Great Gatsby by F. Scott Fitzgerald - Good Condition",
      "description": "A classic American novel in good condition.",
      "keywords": ["classic", "fitzgerald", "novel", "1920s"],
      "recommended_price": 12.99
    }
    '''
    mocker.patch('google.generativeai.GenerativeModel.generate_content', return_value=mock_response)
    
    response = client.post('/generate_listing', json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert data['data']['title'] == 'The Great Gatsby by F. Scott Fitzgerald - Good Condition'
    assert data['data']['recommended_price'] == 12.99

def test_generate_listing_missing_input(client):
    """Test the /generate_listing endpoint handling of missing input data."""
    payload = {"book_data": {"title": "The Great Gatsby"}} # Missing platform
    response = client.post('/generate_listing', json=payload)
    assert response.status_code == 400

def test_generate_json_with_retry_success_after_failures(mocker):
    """Test that the retry loop attempts multiple times and eventually succeeds."""
    from main import generate_json_with_retry
    
    # Mock time.sleep to avoid slowing down the test suite during backoff
    mock_sleep = mocker.patch('main.time.sleep')
    mock_model = mocker.MagicMock()
    
    mock_bad_response = mocker.MagicMock()
    mock_bad_response.text = "This is not valid JSON and will trigger a JSONDecodeError"
    
    mock_good_response = mocker.MagicMock()
    mock_good_response.text = '{"success": true}'
    
    # Simulate a sequence of events:
    # 1. API Exception, 2. Bad JSON response, 3. Successful JSON response
    mock_model.generate_content.side_effect = [
        Exception("Simulated Transient API Error"),
        mock_bad_response,
        mock_good_response
    ]
    
    result = generate_json_with_retry(mock_model, "prompt", max_retries=2)
    
    assert result == {"success": True}
    assert mock_model.generate_content.call_count == 3
    assert mock_sleep.call_count == 2

def test_generate_json_with_retry_exhaustion(mocker):
    """Test that the retry loop raises the final error after max retries are exceeded."""
    from main import generate_json_with_retry
    
    mock_sleep = mocker.patch('main.time.sleep')
    mock_model = mocker.MagicMock()
    
    # Always raise an exception
    mock_model.generate_content.side_effect = Exception("Persistent API Error")
    
    with pytest.raises(Exception, match="Persistent API Error"):
        generate_json_with_retry(mock_model, "prompt", max_retries=2)
        
    assert mock_model.generate_content.call_count == 3
    assert mock_sleep.call_count == 2

def test_eventarc_firestore_queue_missing_headers(client):
    """Test Eventarc endpoint fails cleanly without CloudEvent headers."""
    response = client.post('/eventarc/firestore_queue', json={"some": "data"})
    assert response.status_code == 400
    data = json.loads(response.data)
    assert data['status'] == 'ignored'
    assert 'Missing CloudEvent headers' in data['reason']

def test_eventarc_firestore_queue_unhandled_event(client):
    """Test Eventarc endpoint gracefully ignores unhandled event types."""
    headers = {'ce-type': 'google.cloud.storage.object.v1.finalized'}
    response = client.post('/eventarc/firestore_queue', headers=headers, json={})
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'ignored'
    assert 'Unhandled event type' in data['reason']

def test_eventarc_firestore_queue_valid_event(client, mocker):
    """Test Eventarc endpoint successfully processes a valid offline queue event."""
    mocker.patch('main._process_metadata_extraction', return_value=({"status": "success"}, 200))
    headers = {'ce-type': 'google.cloud.firestore.document.v1.created'}
    payload = {
        "value": {
            "name": "projects/spinevision/databases/(default)/documents/OfflineQueue/task123",
            "fields": {
                "task_type": {"stringValue": "extract_metadata"},
                "image_reference": {"stringValue": "gs://fake-bucket/queued-image.jpg"}
            }
        }
    }
    response = client.post('/eventarc/firestore_queue', headers=headers, json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert data['processed'] == payload['value']['name']

def test_eventarc_firestore_queue_generate_listing(client, mocker):
    """Test Eventarc endpoint successfully processes an async listing generation event."""
    mock_process = mocker.patch('main._process_listing_generation', return_value=({"status": "success"}, 200))
    headers = {'ce-type': 'google.cloud.firestore.document.v1.created'}
    payload = {
        "value": {
            "name": "projects/spinevision/databases/(default)/documents/OfflineQueue/task456",
            "fields": {
                "task_type": {"stringValue": "generate_listing"},
                "platform": {"stringValue": "eBay"},
                "book_data": {
                    "mapValue": {
                        "fields": {
                            "title": {"stringValue": "The Great Gatsby"},
                            "condition": {"stringValue": "Good"}
                        }
                    }
                }
            }
        }
    }
    response = client.post('/eventarc/firestore_queue', headers=headers, json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert data['processed'] == payload['value']['name']
    
    mock_process.assert_called_once_with({"title": "The Great Gatsby", "condition": "Good"}, "eBay")

def test_eventarc_firestore_queue_library_catalog(client, mocker):
    """Test Eventarc endpoint successfully processes an async library catalog event."""
    mock_process = mocker.patch('main._process_library_catalog', return_value=({"status": "success"}, 200))
    headers = {'ce-type': 'google.cloud.firestore.document.v1.created'}
    payload = {
        "value": {
            "name": "projects/spinevision/databases/(default)/documents/OfflineQueue/task789",
            "fields": {
                "task_type": {"stringValue": "library_catalog"},
                "image_reference": {"stringValue": "gs://fake-bucket/catalog-image.jpg"}
            }
        }
    }
    response = client.post('/eventarc/firestore_queue', headers=headers, json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert data['processed'] == payload['value']['name']
    
    mock_process.assert_called_once_with("gs://fake-bucket/catalog-image.jpg")

def test_eventarc_firestore_queue_buy_decision(client, mocker):
    """Test Eventarc endpoint successfully processes an async buy decision event."""
    mock_process = mocker.patch('main._process_buy_decision', return_value=({"status": "success"}, 200))
    headers = {'ce-type': 'google.cloud.firestore.document.v1.created'}
    payload = {
        "value": {
            "name": "projects/spinevision/databases/(default)/documents/OfflineQueue/task101",
            "fields": {
                "task_type": {"stringValue": "buy_decision"},
                "book_data": {
                    "mapValue": {
                        "fields": {
                            "title": {"stringValue": "The Great Gatsby"}
                        }
                    }
                },
                "user_settings": {
                    "mapValue": {
                        "fields": {
                            "minimum_profit_margin": {"doubleValue": 10.0}
                        }
                    }
                }
            }
        }
    }
    response = client.post('/eventarc/firestore_queue', headers=headers, json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert data['processed'] == payload['value']['name']
    
    mock_process.assert_called_once_with({"title": "The Great Gatsby"}, {"minimum_profit_margin": 10.0})

def test_extract_pricing_endpoint(client, mocker):
    """Test the /extract_pricing routing with mocked AI and GCS."""
    payload = {
        "image_reference": "gs://fake-bucket/pricing-image.jpg",
        "book_data": {"title": "The Great Gatsby", "author": "F. Scott Fitzgerald"}
    }
    
    # Mock GCS download and Gemini upload
    mocker.patch('main.download_image_to_temp', return_value="/tmp/fake.jpg")
    mocker.patch('main.genai.upload_file', return_value=mocker.MagicMock())
    
    # Mock Gemini AI response
    mock_response = mocker.MagicMock()
    mock_response.text = '''
    {
      "original_retail_price": 25.0,
      "estimated_market_value": 15.0,
      "comparable_prices": [
        { "marketplace": "Amazon", "price": 14.99, "condition": "Good", "url": "http://amazon.com/ Gatsby" },
        { "marketplace": "eBay", "price": 12.50, "condition": "Good", "url": "http://ebay.com/Gatsby" }
      ],
      "sales_rank": 150000,
      "sales_velocity": "Medium",
      "demand_score": 75,
      "is_bolo": false
    }
    '''
    mocker.patch('google.generativeai.GenerativeModel.generate_content', return_value=mock_response)
    
    response = client.post('/extract_pricing', json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert data['data']['estimated_market_value'] == 15.0
    assert data['data']['demand_score'] == 75

def test_batch_process_shelf_endpoint(client, mocker):
    """Test the /batch_process_shelf routing with mocked AI and GCS."""
    payload = {"image_reference": "gs://fake-bucket/shelf-image.jpg"}
    
    # Mock GCS download and Gemini upload
    mocker.patch('main.download_image_to_temp', return_value="/tmp/fake.jpg")
    mocker.patch('main.genai.upload_file', return_value=mocker.MagicMock())
    
    # Mock Gemini AI response
    mock_response = mocker.MagicMock()
    mock_response.text = '''
    {
      "batch_id": "batch-001",
      "books": [
        { "title": "Book 1", "author": "Author 1", "isbn": "1111111111", "condition_estimate": "Good", "confidence_score": 0.9 },
        { "title": "Book 2", "author": "Author 2", "isbn": "2222222222", "condition_estimate": "Acceptable", "confidence_score": 0.8 }
      ],
      "total_detected": 2
    }
    '''
    mocker.patch('google.generativeai.GenerativeModel.generate_content', return_value=mock_response)
    
    response = client.post('/batch_process_shelf', json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert len(data['data']['books']) == 2
    assert data['data']['batch_id'] == 'batch-001'

def test_analytics_enrichment_endpoint(client, mocker):
    """Test the /analytics_enrichment routing with mocked AI."""
    payload = {
        "raw_data": {"inventory": [{"title": "Book 1", "cost": 5.0, "estimated_value": 15.0}]}
    }
    
    # Mock Gemini AI response
    mock_response = mocker.MagicMock()
    mock_response.text = '''
    {
      "total_inventory_value": 1000.0,
      "projected_profit": 450.0,
      "top_performing_categories": ["Fantasy", "Sci-Fi"],
      "sourcing_recommendations": "Focus on 1950s Sci-Fi hardcovers.",
      "market_trends": ["Vintage fantasy is rising"],
      "low_stock_alerts": ["Tolkien novels"],
      "efficiency_score": 0.85
    }
    '''
    mocker.patch('google.generativeai.GenerativeModel.generate_content', return_value=mock_response)
    
    response = client.post('/analytics_enrichment', json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert data['data']['projected_profit'] == 450.0
    assert "Fantasy" in data['data']['top_performing_categories']

def test_eventarc_firestore_queue_analyze_condition(client, mocker):
    """Test Eventarc endpoint successfully processes an async condition analysis event."""
    mock_process = mocker.patch('main._process_analyze_condition', return_value=({"status": "success"}, 200))
    headers = {'ce-type': 'google.cloud.firestore.document.v1.created'}
    payload = {
        "value": {
            "name": "projects/spinevision/databases/(default)/documents/OfflineQueue/task202",
            "fields": {
                "task_type": {"stringValue": "analyze_condition"},
                "image_reference": {"stringValue": "gs://fake-bucket/condition-image.jpg"}
            }
        }
    }
    response = client.post('/eventarc/firestore_queue', headers=headers, json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert data['processed'] == payload['value']['name']
    
    mock_process.assert_called_once_with("gs://fake-bucket/condition-image.jpg")

def test_market_forecast_endpoint(client, mocker):
    """Test the /market_forecast routing with mocked AI."""
    payload = {
        "book_data": {"title": "The Great Gatsby", "author": "F. Scott Fitzgerald"}
    }
    
    mock_response = mocker.MagicMock()
    mock_response.text = '''
    {
      "forecast_horizon": "6 months",
      "demand_trend": "Stable",
      "price_volatility": "Low",
      "optimal_selling_season": "Year-round",
      "seasonal_multipliers": {"Q1": 1.0, "Q2": 1.0, "Q3": 1.0, "Q4": 1.1},
      "market_risk_factors": ["High competition"],
      "strategic_advice": "Hold for classic collectors."
    }
    '''
    mocker.patch('google.generativeai.GenerativeModel.generate_content', return_value=mock_response)
    
    response = client.post('/market_forecast', json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert data['data']['demand_trend'] == 'Stable'

def test_analyze_set_endpoint(client, mocker):
    """Test the /analyze_set routing with mocked AI."""
    payload = {
        "metadata": {"title": "The Fellowship of the Ring", "author": "J.R.R. Tolkien"}
    }
    
    mock_response = mocker.MagicMock()
    mock_response.text = '''
    {
      "is_part_of_set": true,
      "set_name": "The Lord of the Rings",
      "total_volumes_in_set": 3,
      "current_volume_number": 1,
      "missing_volumes": ["The Two Towers", "The Return of the King"],
      "set_completion_value_bonus": 1.5,
      "rarity_score": 20,
      "notes": "Common edition."
    }
    '''
    mocker.patch('google.generativeai.GenerativeModel.generate_content', return_value=mock_response)
    
    response = client.post('/analyze_set', json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'success'
    assert data['data']['set_name'] == 'The Lord of the Rings'
    assert data['data']['is_part_of_set'] is True