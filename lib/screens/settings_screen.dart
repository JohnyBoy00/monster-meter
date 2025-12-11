import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings screen for app configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCurrency = '\$'; // Default currency
  bool _isLoading = true;

  // List of available currencies
  final List<Map<String, String>> _currencies = [
    {'symbol': '\$', 'name': 'US Dollar (USD)', 'code': 'USD'},
    {'symbol': '€', 'name': 'Euro (EUR)', 'code': 'EUR'},
    {'symbol': '£', 'name': 'British Pound (GBP)', 'code': 'GBP'},
    {'symbol': '¥', 'name': 'Japanese Yen (JPY)', 'code': 'JPY'},
    {'symbol': '₹', 'name': 'Indian Rupee (INR)', 'code': 'INR'},
    {'symbol': 'R', 'name': 'South African Rand (ZAR)', 'code': 'ZAR'},
    {'symbol': 'R\$', 'name': 'Brazilian Real (BRL)', 'code': 'BRL'},
    {'symbol': 'C\$', 'name': 'Canadian Dollar (CAD)', 'code': 'CAD'},
    {'symbol': 'A\$', 'name': 'Australian Dollar (AUD)', 'code': 'AUD'},
    {'symbol': '¥', 'name': 'Chinese Yuan (CNY)', 'code': 'CNY'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  /// Loads the saved currency from shared preferences
  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('currency_symbol') ?? '\$';
      _isLoading = false;
    });
  }

  /// Saves the selected currency to shared preferences
  Future<void> _saveCurrency(String symbol, String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_symbol', symbol);
    await prefs.setString('currency_code', code);
    setState(() {
      _selectedCurrency = symbol;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Currency changed to $code'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCurrencySection(),
              ],
            ),
    );
  }

  /// Builds the currency settings section
  Widget _buildCurrencySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Currency',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select your preferred currency for price tracking',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade700),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currencies.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final currency = _currencies[index];
                  final isSelected = _selectedCurrency == currency['symbol'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      child: Text(
                        currency['symbol']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                    title: Text(
                      currency['name']!,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () => _saveCurrency(
                      currency['symbol']!,
                      currency['code']!,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

