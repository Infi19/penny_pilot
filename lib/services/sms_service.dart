import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();

  /// Requests SMS permission if not already granted.
  /// Returns true if permission is granted.
  Future<bool> requestSmsPermission() async {
    var status = await Permission.sms.status;
    if (status.isDenied) {
      status = await Permission.sms.request();
    }
    return status.isGranted;
  }

  /// Fetches messages that appear to be banking related.
  Future<List<SmsMessage>> getBankingMessages() async {
    if (!await requestSmsPermission()) {
      // It's better to handle UI feedback for permission denial in the UI layer
      return [];
    }

    // Query all inbox messages
    List<SmsMessage> messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      // We can't easily filter by address here as banks vary, so fetch all and filter in memory
      // Limit count if necessary for performance, but for now we want all historical data potential
    );

    return messages.where((msg) => _isBankingMessage(msg)).toList();
  }

  /// Filters for banking messages based on keywords and sender ID patterns.
  bool _isBankingMessage(SmsMessage msg) {
    if (msg.body == null) return false;
    final body = msg.body!.toLowerCase();
    final address = msg.address?.toLowerCase() ?? '';

    // Filter 1: Check if sender ID looks like a short code (usually banks use these)
    // Most bank sender IDs are like "HDFCBK", "SBIINB", etc. - rarely pure numbers like personal contacts
    // But sometimes they come from 6-digit codes.
    // A simple heuristic: Personal numbers usually start with + or digits. Bank IDs usually contain letters.
    // Note: This is weak, so we rely more on body keywords.
    bool potentiallyBankSender = address.contains(RegExp(r'[a-z]')) && address.length < 10;

    // Filter 2: Keywords
    bool hasFinancialKeywords = 
         body.contains('debited') || 
         body.contains('credited') || 
         body.contains('acct') || 
         body.contains('spent') || 
         body.contains('withdraw') || 
         body.contains('txn') || 
         body.contains('tran') || 
         body.contains('balance') || 
         body.contains('avbl') ||
         body.contains('inr') ||
         body.contains('rs.') ||
         body.contains('upi');

    // Filter 3: Exclusions (OTP, Spam)
    bool isExcluded = 
         body.contains('otp') || 
         body.contains('verification code') ||
         body.contains('loan') || // Often spam
         body.contains('offer');  // Often spam

    return hasFinancialKeywords && !isExcluded;
  }
}
