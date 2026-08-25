import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';

/// Service handling all Firestore interactions for the SpineVision ecosystem.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get current user ID, defaulting to a test ID if not authenticated for local dev
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? 'user_123';

  DocumentReference get _userDoc => _db.collection('users').doc(uid);
  
  // Subcollections (Per-User)
  CollectionReference get _libraryCol => _userDoc.collection('library');
  CollectionReference get _listingsCol => _userDoc.collection('listings');
  CollectionReference get _salesCol => _userDoc.collection('sales');
  CollectionReference get _scansCol => _userDoc.collection('scans');
  CollectionReference get _crmCol => _userDoc.collection('crm');
  CollectionReference get _analyticsCol => _userDoc.collection('analytics');
  CollectionReference get _settingsCol => _userDoc.collection('settings');
  
  // Global Collections
  CollectionReference get _supportCol => _db.collection('support');
  CollectionReference get _metadataCol => _db.collection('metadata');

  // --- User Profile & Settings ---

  Future<UserSettingsModel?> getUserSettings() async {
    final doc = await _settingsCol.doc('profile').get();
    if (!doc.exists) return null;
    return UserSettingsModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<void> saveUserSettings(UserSettingsModel settings) async {
    await _settingsCol.doc('profile').set(settings.toJson(), SetOptions(merge: true));
  }

  // --- Library (Books) ---

  Future<void> saveBook(BookModel book) async {
    final docId = book.id ?? _libraryCol.doc().id;
    await _libraryCol
        .doc(docId)
        .set(book.copyWith(id: docId).toJson(), SetOptions(merge: true));
  }

  Stream<List<BookModel>> getLibraryStream() {
    return _libraryCol
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BookModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // --- Scans ---

  Future<void> saveScan(ScanModel scan) async {
    final docId = scan.scanId ?? _scansCol.doc().id;
    await _scansCol.doc(docId).set(scan.copyWith(scanId: docId).toJson());
  }

  Stream<List<ScanModel>> getScansStream() {
    return _scansCol
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ScanModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // --- Listings ---

  Future<void> saveListing(ListingModel listing) async {
    final docId = listing.listingId ?? _listingsCol.doc().id;
    await _listingsCol.doc(docId).set(listing.copyWith(listingId: docId).toJson());
  }

  Stream<List<ListingModel>> getListingsStream() {
    return _listingsCol.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ListingModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // --- Sales ---

  Future<void> saveSale(SaleModel sale) async {
    final docId = sale.saleId ?? _salesCol.doc().id;
    await _salesCol.doc(docId).set(sale.copyWith(saleId: docId).toJson());
  }

  Stream<List<SaleModel>> getSalesStream() {
    return _salesCol.orderBy('dateSold', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => SaleModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // --- CRM (Buyers) ---

  Future<void> saveBuyer(BuyerModel buyer) async {
    final docId = buyer.buyerId ?? _crmCol.doc().id;
    await _crmCol.doc(docId).set(buyer.copyWith(buyerId: docId).toJson());
  }

  Stream<List<BuyerModel>> getBuyersStream() {
    return _crmCol.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BuyerModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // --- Support Tickets ---

  Future<void> createTicket(SupportTicket ticket) async {
    final docId = _supportCol.doc().id;
    await _supportCol.doc(docId).set(ticket.copyWith(id: docId).toJson());
  }

  Stream<List<SupportTicket>> getMyTicketsStream() {
    return _supportCol
        .where('userId', isEqualTo: _uid)
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

  // --- Analytics ---

  Future<void> saveAnalyticsSnapshot(AnalyticsSnapshotModel snapshot) async {
    final docId = snapshot.snapshotId ?? _analyticsCol.doc().id;
    await _analyticsCol.doc(docId).set(snapshot.copyWith(snapshotId: docId).toJson());
  }

  Stream<List<AnalyticsSnapshotModel>> getAnalyticsStream() {
    return _analyticsCol.orderBy('timestamp', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AnalyticsSnapshotModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }
}
