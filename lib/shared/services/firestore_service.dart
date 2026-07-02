import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';

/// Service handling all Firestore interactions for the user's ecosystem.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get current user ID, defaulting to a test ID if not authenticated for local dev
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'user_123';

  DocumentReference get _userDoc => _db.collection('users').doc(_uid);
  CollectionReference get _inventoryCol => _userDoc.collection('inventory');
  CollectionReference get _ledgerCol => _userDoc.collection('ledger');
  CollectionReference get _setsCol => _userDoc.collection('sets');
  CollectionReference get _wishlistCol => _userDoc.collection('wishlist');
  CollectionReference get _bundlesCol => _userDoc.collection('bundles');
  CollectionReference get _ticketsCol => _userDoc.collection('tickets');
  CollectionReference get _customersCol => _userDoc.collection('customers');
  CollectionReference get _locationsCol => _userDoc.collection('locations');
  CollectionReference get _forecastsCol => _userDoc.collection('forecasts');
  CollectionReference get _mileageCol => _userDoc.collection('mileage');

  // --- User Profile & Stats ---

  Future<Map<String, dynamic>> getUserData() async {
    final doc = await _userDoc.get();
    return doc.data() as Map<String, dynamic>? ?? {};
  }

  // --- Inventory (Books) ---

  Future<void> saveBook(BookModel book) async {
    final docId = book.id ?? _inventoryCol.doc().id;
    await _inventoryCol
        .doc(docId)
        .set(book.copyWith(id: docId).toJson(), SetOptions(merge: true));
  }

  Stream<List<BookModel>> getInventoryStream() {
    return _inventoryCol
        .orderBy('dateSourced', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BookModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  Future<List<BookModel>> getInventoryOnce() async {
    final snapshot = await _inventoryCol.get();
    return snapshot.docs
        .map((doc) => BookModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // --- Ledger (Expenses/TaxVision) ---

  Future<void> saveExpense(ExpenseModel expense) async {
    final docId = expense.id ?? _ledgerCol.doc().id;
    await _ledgerCol
        .doc(docId)
        .set(expense.copyWith(id: docId).toJson(), SetOptions(merge: true));
  }

  Stream<List<ExpenseModel>> getLedgerStream() {
    return _ledgerCol
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    ExpenseModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // --- Sets & Series ---

  Future<void> saveSeries(SeriesModel series) async {
    final docId = series.id ?? _setsCol.doc().id;
    await _setsCol.doc(docId).set(series.toJson());
  }

  Stream<List<SeriesModel>> getSetsStream() {
    return _setsCol.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => SeriesModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  // --- Wishlist ---

  Future<void> saveWish(WishModel wish) async {
    final docId = wish.id ?? _wishlistCol.doc().id;
    await _wishlistCol.doc(docId).set(wish.toJson());
  }

  Stream<List<WishModel>> getWishlistStream() {
    return _wishlistCol.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => WishModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  // --- Bundles ---

  Future<void> saveBundle(BundleModel bundle) async {
    final docId = bundle.id ?? _bundlesCol.doc().id;
    await _bundlesCol.doc(docId).set(bundle.toJson());
  }

  Stream<List<BundleModel>> getBundlesStream() {
    return _bundlesCol.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => BundleModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  // --- Support Tickets ---

  Future<void> createTicket(SupportTicket ticket) async {
    final docId = _ticketsCol.doc().id;
    await _ticketsCol.doc(docId).set(ticket.copyWith(id: docId).toJson());
  }

  Stream<List<SupportTicket>> getMyTicketsStream() {
    return _ticketsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    SupportTicket.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // --- CRM ---

  Future<void> saveCustomer(CustomerModel customer) async {
    final docId = customer.id ?? _customersCol.doc().id;
    await _customersCol.doc(docId).set(customer.copyWith(id: docId).toJson());
  }

  Stream<List<CustomerModel>> getCustomersStream() {
    return _customersCol.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    CustomerModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // --- Locate ---

  Future<void> saveLocation(LocationModel location) async {
    final docId = location.id ?? _locationsCol.doc().id;
    await _locationsCol.doc(docId).set(location.copyWith(id: docId).toJson());
  }

  Stream<List<LocationModel>> getLocationsStream() {
    return _locationsCol.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    LocationModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // --- Forecast ---

  Future<void> saveForecast(ForecastModel forecast) async {
    final docId = forecast.id ?? _forecastsCol.doc().id;
    await _forecastsCol.doc(docId).set(forecast.copyWith(id: docId).toJson());
  }

  Stream<List<ForecastModel>> getForecastsStream() {
    return _forecastsCol.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    ForecastModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // --- Mileage ---

  Future<void> saveMileage(MileageModel mileage) async {
    final docId = mileage.id ?? _mileageCol.doc().id;
    await _mileageCol.doc(docId).set(mileage.copyWith(id: docId).toJson());
  }

  Stream<List<MileageModel>> getMileageStream() {
    return _mileageCol.orderBy('date', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    MileageModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }
}
