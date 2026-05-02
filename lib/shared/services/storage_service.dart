import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class CloudStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Uploads a file to Firebase Storage and returns its GS URI.
  /// [folder] should be 'raw-uploads', 'processed-assets', or 'listing-photos'.
  Future<String?> uploadImage(File file, {String folder = 'raw-uploads'}) async {
    try {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child(folder).child(fileName);
      
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      
      // Construct the GS URI: gs://<bucket-name>/<path>
      final bucket = snapshot.ref.bucket;
      final fullPath = snapshot.ref.fullPath;
      
      return 'gs://$bucket/$fullPath';
    } catch (e) {
      // Log error or handle appropriately
      return null;
    }
  }

  /// Deletes a file from Firebase Storage given its GS URI.
  Future<void> deleteImage(String gsUri) async {
    try {
      final ref = _storage.refFromURL(gsUri);
      await ref.delete();
    } catch (e) {
      // Ignore or handle deletion error
    }
  }
}
