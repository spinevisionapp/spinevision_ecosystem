import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/services/api_service.dart';
import 'package:spinevision_ecosystem/shared/services/firestore_service.dart';

class BookRepository {
  final ApiService _apiService;
  final FirestoreService _firestoreService;
  String _currentTier = 'Hobbyist';

  BookRepository(this._apiService, this._firestoreService);

  String get currentTier => _currentTier;

  // --- SUBSCRIPTIONS ---

  Future<void> syncSubscriptionStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updateTierFromCustomerInfo(customerInfo);
    } catch (e) {}
  }

  void handleCustomerInfoUpdate(CustomerInfo customerInfo) {
    _updateTierFromCustomerInfo(customerInfo);
  }

  void _updateTierFromCustomerInfo(CustomerInfo customerInfo) {
    if (customerInfo.entitlements.all['top_tier']?.isActive ?? false) {
      _currentTier = 'Enterprise';
    } else if (customerInfo.entitlements.all['mid_tier']?.isActive ?? false) {
      _currentTier = 'Pro';
    } else {
      _currentTier = 'Hobbyist';
    }
  }

  // --- USER DATA ---

  Future<Map<String, dynamic>> getUserStats() async {
    return await _firestoreService.getUserData();
  }

  // --- INVENTORY (OMNIVISION / VISIONHUB / LIBRARY) ---

  Future<void> saveBook(BookModel book) async {
    await _firestoreService.saveBook(book);
  }

  Stream<List<BookModel>> getInventoryStream() {
    return _firestoreService.getInventoryStream();
  }

  Future<List<BookModel>> getBooks() async {
    return await _firestoreService.getInventoryOnce();
  }

  // --- LEDGER (TAXVISION) ---

  Future<void> saveExpense(ExpenseModel expense) async {
    await _firestoreService.saveExpense(expense);
  }

  Stream<List<ExpenseModel>> getLedgerStream() {
    return _firestoreService.getLedgerStream();
  }

  // --- SETS (SETVISION) ---

  Future<void> saveSeries(SeriesModel series) async {
    await _firestoreService.saveSeries(series);
  }

  Stream<List<SeriesModel>> getSetsStream() {
    return _firestoreService.getSetsStream();
  }

  // --- WISHLIST (WISHVISION) ---

  Future<void> saveWish(WishModel wish) async {
    await _firestoreService.saveWish(wish);
  }

  Stream<List<WishModel>> getWishlistStream() {
    return _firestoreService.getWishlistStream();
  }

  // --- BUNDLES (BUNDLEVISION) ---

  Future<void> saveBundle(BundleModel bundle) async {
    await _firestoreService.saveBundle(bundle);
  }

  Stream<List<BundleModel>> getBundlesStream() {
    return _firestoreService.getBundlesStream();
  }

  // --- TICKETS (SUPPORTVISION) ---

  Future<void> createTicket(SupportTicket ticket) async {
    await _firestoreService.createTicket(ticket);
  }

  Stream<List<SupportTicket>> getMyTicketsStream() {
    return _firestoreService.getMyTicketsStream();
  }

  // --- AI ACTIONS (BACKEND) ---

  Future<Map<String, dynamic>> getAnalytics() async {
    final books = await _firestoreService.getInventoryOnce();
    final response = await _apiService.getAnalyticsEnrichment({'inventory': books.map((b) => b.toJson()).toList()});
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> getRecommendation(String uri, Map<String, dynamic> settings) async {
    final response = await _apiService.getBuyDecision({'image_reference': uri}, settings);
    return response['data'] ?? {};
  }

  Future<List<dynamic>> batchProcessShelf(String uri) async {
    final response = await _apiService.batchProcessShelf(uri);
    return response['data']?['books'] ?? [];
  }

  Future<Map<String, dynamic>> extractReceipt(String uri) async {
    final response = await _apiService.extractReceipt(uri);
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> optimizeBox(List<BookModel> inventory, double weight) async {
    final response = await _apiService.optimizeBox(inventory.map((b) => b.toJson()).toList(), weight);
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> optimizeBundle(List<BookModel> books) async {
    final booksJson = books.map((b) => b.toJson()).toList();
    final response = await _apiService.post('/bundle_optimizer', {'books': booksJson});
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> repriceInventory() async {
    final books = await _firestoreService.getInventoryOnce();
    final booksJson = books.map((b) => b.toJson()).toList();
    final response = await _apiService.repriceInventory(booksJson);
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> generateListing(BookModel book, [String? platform]) async {
    final response = await _apiService.generateListing(book.toJson(), platform ?? 'eBay');
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> analyzeSet(BookModel book) async {
    final response = await _apiService.analyzeSet(book.toJson());
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> getSocialPosts() async {
    final response = await _apiService.getSocialPosts();
    return response['data'] ?? {};
  }
}
