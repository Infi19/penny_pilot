import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/retry_helper.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await RetryHelper.withRetry(
        operation: () => _firestore.collection('users').doc(userId).set(data),
      );
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await RetryHelper.withRetry(
        operation: () => _firestore.collection('users').doc(userId).get(),
      );
      return doc.data();
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
  try {
    final docRef = _firestore.collection('users').doc(userId);
    final doc = await docRef.get();
    
    if (doc.exists) {
      // Update existing document
      await RetryHelper.withRetry(
        operation: () => docRef.update(data),
      );
    } else {
      // Create new document
      await RetryHelper.withRetry(
        operation: () => docRef.set(data),
      );
    }
  } catch (e) {
    print('Error updating user profile: $e');
    rethrow;
  }
}
}