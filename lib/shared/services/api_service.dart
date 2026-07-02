import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service responsible for communicating with the SpineVision AI Orchestrator.
class ApiService {

  ApiService({
    this.baseUrl = 'http://localhost:5000',
    this.authToken,
  });
  final String baseUrl;
  final String? authToken;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  /// Generic POST handler used by the repository.
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getAnalyticsEnrichment(
    Map<String, dynamic> body,
  ) => post('/analytics_enrichment', body);

  Future<Map<String, dynamic>> getBuyDecision(
    Map<String, dynamic> body,
    Map<String, dynamic> settings,
  ) => post('/buy_decision', {...body, 'settings': settings});

  Future<Map<String, dynamic>> batchProcessShelf(String uri) =>
      post('/batch_process_shelf', {'image_url': uri});

  Future<Map<String, dynamic>> extractReceipt(String uri) =>
      post('/extract_receipt', {'image_url': uri});

  Future<Map<String, dynamic>> optimizeBox(
    List<Map<String, dynamic>> inventory,
    double weight,
  ) => post('/optimize_box', {'inventory': inventory, 'weight': weight});

  Future<Map<String, dynamic>> repriceInventory(
    List<Map<String, dynamic>> inventory,
  ) => post('/extract_pricing', {'inventory': inventory});

  Future<Map<String, dynamic>> generateListing(
    Map<String, dynamic> bookJson,
    String platform,
  ) => post('/generate_listing', {'book': bookJson, 'platform': platform});

  Future<Map<String, dynamic>> analyzeSet(Map<String, dynamic> bookJson) =>
      post('/analyze_set', {'book': bookJson});

  Future<Map<String, dynamic>> activatePromotion(String key) => 
      post('/activate_promotion', {'promotion_key': key});

  Future<Map<String, dynamic>> getMilestones() => post('/milestones', {});

  Future<Map<String, dynamic>> getSocialPosts() =>
      post('/generate_social_content', {});

  Future<Map<String, dynamic>> analyzeSignature(String uri) =>
      post('/analyze_condition', {'image_url': uri, 'focus': 'signature'});

  // --- CRM ---
  Future<Map<String, dynamic>> getCustomers() => post('/crm/customers', {});
  Future<Map<String, dynamic>> saveCustomer(Map<String, dynamic> data) =>
      post('/crm/customers', data);
  Future<Map<String, dynamic>> getCrmAnalytics() => post('/crm/analytics', {});

  // --- Locate ---
  Future<Map<String, dynamic>> getLocations() => post('/locate/map', {});
  Future<Map<String, dynamic>> saveLocation(Map<String, dynamic> data) =>
      post('/locate/map', data);
  Future<Map<String, dynamic>> getPickList() => post('/locate/pick_list', {});

  // --- TaxVision ---
  Future<Map<String, dynamic>> calculateMileage(double miles) =>
      post('/tax/calculate_mileage', {'miles': miles});
  Future<Map<String, dynamic>> generateTaxReport() => post('/tax/generate_report', {});

  Future<Map<String, dynamic>> askChatbot(String question) =>
      post('/chatbot', {'question': question});

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body);
        // Wrap in a 'data' key to match BookRepository expectations if necessary
        return {'data': decoded};
      } catch (e) {
        throw Exception('Failed to parse API response: $e');
      }
    } else {
      final errorBody = response.body;
      throw Exception('API Error (${response.statusCode}): $errorBody');
    }
  }

  Future<Map<String, dynamic>> getHealth() async {
    final response = await http.get(
      Uri.parse('$baseUrl/health'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }
}
