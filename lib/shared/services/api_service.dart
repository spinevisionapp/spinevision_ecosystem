import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spinevision_ecosystem/shared/services/auth_service.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;
  final AuthService _authService;

  ApiService({
    required AuthService authService,
    this.baseUrl = 'http://localhost:8080',
    http.Client? client,
  })  : _authService = authService,
        _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('API Request failed with status: ${response.statusCode}\nBody: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: await _getHeaders(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('API Request failed with status: ${response.statusCode}\nBody: ${response.body}');
    }
  }

  // Domain-specific methods
  
  Future<Map<String, dynamic>> extractMetadata(String imageReference) async {
    return post('/extract_metadata', {'image_reference': imageReference});
  }

  Future<Map<String, dynamic>> extractPricing(String imageReference, {Map<String, dynamic>? bookData}) async {
    return post('/extract_pricing', {
      'image_reference': imageReference,
      'book_data': ?bookData,
    });
  }

  Future<Map<String, dynamic>> analyzeCondition(String imageReference) async {
    return post('/analyze_condition', {'image_reference': imageReference});
  }

  Future<Map<String, dynamic>> batchProcessShelf(String imageReference) async {
    return post('/batch_process_shelf', {'image_reference': imageReference});
  }

  Future<Map<String, dynamic>> generateListing(Map<String, dynamic> bookData, String platform) async {
    return post('/generate_listing', {
      'book_data': bookData,
      'platform': platform,
    });
  }

  Future<Map<String, dynamic>> getBuyDecision(Map<String, dynamic> bookData, Map<String, dynamic> userSettings) async {
    return post('/buy_decision', {
      'book_data': bookData,
      'user_settings': userSettings,
    });
  }

  Future<Map<String, dynamic>> getAnalyticsEnrichment(Map<String, dynamic> rawData) async {
    return post('/analytics_enrichment', {'raw_data': rawData});
  }

  Future<Map<String, dynamic>> optimizeBundle(List<Map<String, dynamic>> books) async {
    return post('/bundle_optimizer', {'books': books});
  }

  Future<Map<String, dynamic>> extractReceipt(String imageReference) async {
    return post('/extract_receipt', {'image_reference': imageReference});
  }

  Future<Map<String, dynamic>> askChatbot(String question) async {
    return post('/chatbot', {'question': question});
  }

  Future<Map<String, dynamic>> analyzeSet(Map<String, dynamic> metadata) async {
    return post('/analyze_set', {'metadata': metadata});
  }

  Future<Map<String, dynamic>> getSocialPosts() async {
    // In a real app, this would hit the backend's marketing_automation logic
    return post('/marketing_automation', {}); 
  }

  Future<Map<String, dynamic>> optimizeBox(List<Map<String, dynamic>> inventory, double currentWeight) async {
    return post('/box_optimizer', {'inventory': inventory, 'current_weight': currentWeight});
  }
  }

  Future<Map<String, dynamic>> optimizeBox(List<Map<String, dynamic>> inventory, double currentWeight) async {
    return post('/box_optimizer', {'inventory': inventory, 'current_weight': currentWeight});
  }

  Future<Map<String, dynamic>> repriceInventory(List<Map<String, dynamic>> inventory) async {
    return post('/reprice_vision', {'inventory': inventory});
  }
}
