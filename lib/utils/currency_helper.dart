import 'package:shared_preferences/shared_preferences.dart';

/// Helper class for managing currency display throughout the app
class CurrencyHelper {
  static String _cachedSymbol = '\$';

  /// Gets the saved currency symbol
  static Future<String> getCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedSymbol = prefs.getString('currency_symbol') ?? '\$';
    return _cachedSymbol;
  }

  /// Gets the cached currency symbol (synchronous)
  static String getCachedSymbol() {
    return _cachedSymbol;
  }

  /// Formats a price with the selected currency
  static Future<String> formatPrice(double price) async {
    final symbol = await getCurrencySymbol();
    return '$symbol${price.toStringAsFixed(2)}';
  }

  /// Formats a price with the cached currency (synchronous)
  static String formatPriceCached(double price) {
    return '$_cachedSymbol${price.toStringAsFixed(2)}';
  }

  /// Initializes the currency cache
  static Future<void> initialize() async {
    await getCurrencySymbol();
  }
}

