import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';

class TransactionDetails {
  final double amount;
  final TransactionType type;
  final String merchant;
  final DateTime date;
  final String? bankName;
  final String originalMessage;

  TransactionDetails({
    required this.amount,
    required this.type,
    required this.merchant,
    required this.date,
    this.bankName,
    required this.originalMessage,
  });

  @override
  String toString() {
    return 'TransactionDetails(amount: $amount, type: $type, merchant: $merchant, date: $date)';
  }
}

enum TransactionType {
  debit,
  credit,
}

class TransactionParser {
  /// Attempts to parse a banking SMS into structured transaction details.
  /// Returns null if parsing fails.
  static TransactionDetails? parse(SmsMessage message) {
    final body = message.body;
    if (body == null) return null;
    
    // Normalize body
    String text = body.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 1. Detect Type (Debit/Credit)
    TransactionType type;
    if (text.toLowerCase().contains('debited') || text.toLowerCase().contains('spent') || text.toLowerCase().contains('withdrawn') || text.toLowerCase().contains('paid')) {
      type = TransactionType.debit;
    } else if (text.toLowerCase().contains('credited') || text.toLowerCase().contains('received') || text.toLowerCase().contains('deposited')) {
      type = TransactionType.credit;
    } else {
      // Ambiguous or informational only
      return null;
    }

    // 2. Extract Amount
    // Matches: Rs. 100, INR 100, 100.00, etc.
    final amountRegex = RegExp(r'(?:Rs\.?|INR|₹)\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(text);
    if (amountMatch == null) return null; // No amount found

    String amountStr = amountMatch.group(1)!.replaceAll(',', '');
    double amount = double.tryParse(amountStr) ?? 0.0;
    if (amount == 0.0) return null;

    // 3. Extract Merchant / Beneficiary
    // This is the hardest part. Usually logic depends on specific bank formats.
    // Example: "Rs 100 debited for Zomato..." or "at STARBUCKS"
    // Heuristics:
    String merchant = "Unknown";
    
    // Common patterns: "at <merchant>", "to <merchant>", "VPA <merchant>"
    final merchantRegexes = [
      RegExp(r'\bat\s+([A-Za-z0-9\s\.\*]+?)(?=\son\b|\.\s|$)'),
      RegExp(r'\bto\s+([A-Za-z0-9\s\.\*]+?)(?=\son\b|\.\s|$)'), 
    ];

    for (var regex in merchantRegexes) {
      final match = regex.firstMatch(text);
      if (match != null) {
        String capture = match.group(1)?.trim() ?? "";
        // Clean up capture (remove "Info", "Ref", etc if mistakenly captured)
        if (capture.isNotEmpty && capture.length < 30) { 
           merchant = capture;
           break;
        }
      }
    }

    // 4. Date
    DateTime date = message.date ?? DateTime.now();

    return TransactionDetails(
      amount: amount,
      type: type,
      merchant: merchant,
      date: date,
      originalMessage: body,
      bankName: message.address,
    );
  }
}
