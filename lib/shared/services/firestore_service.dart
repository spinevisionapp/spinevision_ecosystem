import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spinevision_ecosystem/shared/data/models/book_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // --- COLLECTION REFERENCES ---

  CollectionReference<Map<String, dynamic>> get _inventoryRef {
    if (_uid == null) throw Exception('User not authenticated');
    return _db.collection('users').doc(_uid!).collection('inventory');
  }

  CollectionReference<Map<String, dynamic>> get _ledgerRef {
    if (_uid == null) throw Exception('User not authenticated');
    return _db.collection('users').doc(_uid!).collection('ledger');
  }

  CollectionReference<Map<String, dynamic>> get _setsRef {
    if (_uid == null) throw Exception('User not authenticated');
    return _db.collection('users').doc(_uid!).collection('sets');
  }

  CollectionReference<Map<String, dynamic>> get _wishlistRef {
    if (_uid == null) throw Exception('User not authenticated');
    return _db.collection('users').doc(_uid!).collection('wishlist');
  }

  CollectionReference<Map<String, dynamic>> get _bundlesRef {
    if (_uid == null) throw Exception('User not authenticated');
    return _db.collection('users').doc(_uid!).collection('bundles');
  }

  CollectionReference<Map<String, dynamic>> get _ticketsRef {
    return _db.collection('Tickets');
  }

  // --- USER PROFILE ---

  Future<Map<String, dynamic>> getUserData() async {
    if (_uid == null) return {'tier': 'Hobbyist', 'scans_this_month': 0, 'listings_created': 0};
    final doc = await _db.collection('users').doc(_uid!).get();
    return doc.data() ?? {'tier': 'Hobbyist', 'scans_this_month': 0, 'listings_created': 0};
  }

  // --- INVENTORY (OMNIVISION / VISIONHUB / LIBRARY) ---

  Future<void> saveBook(BookModel book) async {
    final docRef = _inventoryRef.doc(book.id ?? book.isbn);
    await docRef.set(book.toJson(), SetOptions(merge: true));
  }

  Stream<List<BookModel>> getInventoryStream() {
    return _inventoryRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BookModel.fromJson(doc.data())).toList();
    });
  }

  Future<List<BookModel>> getInventoryOnce() async {
    final snapshot = await _inventoryRef.get();
    return snapshot.docs.map((doc) => BookModel.fromJson(doc.data())).toList();
  }

  // --- LEDGER (TAXVISION) ---

  Future<void> saveExpense(ExpenseModel expense) async {
    final docRef = _ledgerRef.doc();
    await docRef.set(expense.toJson());
  }

  Stream<List<ExpenseModel>> getLedgerStream() {
    return _ledgerRef.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ExpenseModel.fromJson(doc.data()..['id'] = doc.id)).toList();
    });
  }

  // --- SETS (SETVISION) ---

  Future<void> saveSeries(SeriesModel series) async {
    final docRef = _setsRef.doc(series.id);
    await docRef.set(series.toJson(), SetOptions(merge: true));
  }

  Stream<List<SeriesModel>> getSetsStream() {
    return _setsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SeriesModel.fromJson(doc.data()..['id'] = doc.id)).toList();
    });
  }

  // --- WISHLIST (WISHVISION) ---

  Future<void> saveWish(WishModel wish) async {
    final docRef = _wishlistRef.doc(wish.isbn);
    await docRef.set(wish.toJson(), SetOptions(merge: true));
  }

  Stream<List<WishModel>> getWishlistStream() {
    return _wishlistRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => WishModel.fromJson(doc.data()..['id'] = doc.id)).toList();
    });
  }

  // --- BUNDLES (BUNDLEVISION) ---

  Future<void> saveBundle(BundleModel bundle) async {
    final docRef = _bundlesRef.doc();
    await docRef.set(bundle.toJson());
  }

  Stream<List<BundleModel>> getBundlesStream() {
    return _bundlesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BundleModel.fromJson(doc.data()..['id'] = doc.id)).toList();
    });
  }

  // --- TICKETS (SUPPORTVISION) ---

  Future<void> createTicket(SupportTicket ticket) async {
    final docRef = _ticketsRef.doc();
    await docRef.set(ticket.toJson()..['user_id'] = _uid);
  }

  Stream<List<SupportTicket>> getMyTicketsStream() {
    if (_uid == null) return Stream.value([]);
    return _ticketsRef
      .where('user_id', isEqualTo: _uid)
      .orderBy('updated_at', descending: true)
      .snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => SupportTicket.fromJson(doc.data()..['id'] = doc.id)).toList();
      });
  }
}
