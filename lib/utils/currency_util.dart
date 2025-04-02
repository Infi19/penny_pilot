import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class CurrencyUtil {
  static final Map<String, CurrencyData> supportedCurrencies = {
    'USD': CurrencyData(
      code: 'USD',
      symbol: '\$',
      name: 'US Dollar',
      flag: '🇺🇸',
    ),
    'EUR': CurrencyData(
      code: 'EUR',
      symbol: '€',
      name: 'Euro',
      flag: '🇪🇺',
    ),
    'GBP': CurrencyData(
      code: 'GBP',
      symbol: '£',
      name: 'British Pound',
      flag: '🇬🇧',
    ),
    'JPY': CurrencyData(
      code: 'JPY',
      symbol: '¥',
      name: 'Japanese Yen',
      flag: '🇯🇵',
    ),
    'CAD': CurrencyData(
      code: 'CAD',
      symbol: 'C\$',
      name: 'Canadian Dollar',
      flag: '🇨🇦',
    ),
    'AUD': CurrencyData(
      code: 'AUD',
      symbol: 'A\$',
      name: 'Australian Dollar',
      flag: '🇦🇺',
    ),
    'INR': CurrencyData(
      code: 'INR',
      symbol: '₹',
      name: 'Indian Rupee',
      flag: '🇮🇳',
    ),
    'CNY': CurrencyData(
      code: 'CNY',
      symbol: '¥',
      name: 'Chinese Yuan',
      flag: '🇨🇳',
    ),
  };

  static String getDefaultCurrencyCode() {
    return 'USD';
  }

  static CurrencyData getDefaultCurrency() {
    return supportedCurrencies[getDefaultCurrencyCode()]!;
  }

  static CurrencyData getCurrencyData(String code) {
    return supportedCurrencies[code] ?? getDefaultCurrency();
  }

  static List<String> getCurrencyCodes() {
    return supportedCurrencies.keys.toList();
  }
  
  static List<DropdownMenuItem<String>> getCurrencyDropdownItems() {
    return supportedCurrencies.entries.map((entry) {
      final currency = entry.value;
      return DropdownMenuItem<String>(
        value: currency.code,
        child: Row(
          children: [
            Text(currency.flag + ' '),
            Text(currency.code + ' - '),
            Text(currency.symbol),
            const SizedBox(width: 8),
            Text(
              currency.name,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }).toList();
  }

  static String formatCurrency(double amount, String currencyCode, {int decimalDigits = 2}) {
    final currency = getCurrencyData(currencyCode);
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  static String formatCompactCurrency(double amount, String currencyCode) {
    final currency = getCurrencyData(currencyCode);
    if (amount >= 1000000) {
      return currency.symbol + NumberFormat.compact().format(amount);
    } else if (amount >= 1000) {
      return currency.symbol + NumberFormat.compact().format(amount);
    } else {
      return formatCurrency(amount, currencyCode);
    }
  }
}

class CurrencyData {
  final String code;
  final String symbol;
  final String name;
  final String flag;

  const CurrencyData({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
  });
} 