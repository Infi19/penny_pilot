import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class RetryHelper {
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 1000),
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (e is FirebaseException && 
            e.code == 'unavailable' && 
            attempts < maxAttempts) {
          await Future.delayed(delay);
          delay *= 2; // Exponential backoff
          continue;
        }
        rethrow;
      }
    }
  }
}
