import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';
import 'package:spinevision_ecosystem/shared/services/api_service.dart';
import 'package:spinevision_ecosystem/shared/services/firestore_service.dart';

class BookRepository {

  BookRepository(this._apiService, this._firestoreService);
  final ApiService _apiService;
  final FirestoreService _firestoreService;
  String _currentTier = 'Hobbyist';

  String get currentTier => _currentTier;

  // --- SUBSCRIPTIONS ---

  Future<void> syncSubscriptionStatus() async {
    try {
      final CustomerInfo customerInfo = await Purchases.getCustomerInfo();
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

  Future<void> saveBooks(List<BookModel> books) async {
    for (final book in books) {
      await saveBook(book);
    }
  }

  Stream<List<BookModel>> getLibraryStream() {
    return _firestoreService.getLibraryStream();
  }

  Future<List<BookModel>> getBooks() async {
    return await _firestoreService.getLibraryStream().first;
  }

  // --- SALES & TAXES (OPERATEVISION / TAXVISION) ---

  double _ytdCogs = 0.0;
  double _loggedMiles = 0.0;

  double get ytdCogs => _ytdCogs;
  double get loggedMiles => _loggedMiles;

  void addCogs(double amount) {
    _ytdCogs += amount;
    saveSale(SaleModel(
      userId: _firestoreService.uid,
      listingId: 'manual',
      buyerId: 'self',
      grossAmount: 0,
      netAmount: -amount,
      fees: 0,
      taxAmount: 0,
      shippingPaid: 0,
      dateSold: DateTime.now(),
      paymentStatus: 'paid',
      fulfillmentStatus: 'completed',
    ));
  }

  void addMileage(double miles) {
    _loggedMiles += miles;
    // ... logic for mileage
  }

  Future<void> saveSale(SaleModel sale) async {
    await _firestoreService.saveSale(sale);
  }

  Stream<List<SaleModel>> getSalesStream() {
    return _firestoreService.getSalesStream();
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

  // --- CRM (BUYERVISION / CRMVISION) ---

  Future<void> saveBuyer(BuyerModel buyer) async {
    await _firestoreService.saveBuyer(buyer);
  }

  Stream<List<BuyerModel>> getBuyersStream() {
    return _firestoreService.getBuyersStream();
  }

  // --- AI ACTIONS (BACKEND) ---

  Future<Map<String, dynamic>> getAnalytics() async {
    final books = await getBooks();
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
    final books = await getBooks();
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

  Future<void> activatePromotion(String key) async {
    final response = await _apiService.activatePromotion(key);
    // After activating, sync the subscription status locally
    // In a real app, this would update RevenueCat, but here we just refresh
    // For this prototype, we'll manually set the tier if the response is successful
    if (response['data']?['status'] == 'success') {
      if (key == 'Pro_Trial') _currentTier = 'Pro';
      if (key == 'Enterprise_Trial') _currentTier = 'Enterprise';
    }
  }

  Future<Map<String, dynamic>> getMilestones() async {
    final response = await _apiService.getMilestones();
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> getSocialPosts() async {
    final response = await _apiService.getSocialPosts();
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> analyzeSignature(String uri) async {
    final response = await _apiService.analyzeSignature(uri);
    return response['data'] ?? {};
  }
}
