import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/log_with_flavor.dart';
import '../utils/currency_helper.dart';
import 'add_drink_screen.dart';
import 'history_screen.dart';
import 'manage_flavors_screen.dart';
import 'settings_screen.dart';

/// Home screen displaying today's drink statistics and recent drinks
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  int _caffeineTotal = 0;
  int _drinkCount = 0;
  double _totalSpending = 0.0;
  List<LogWithFlavor> _todaysLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads today's statistics from the database
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final caffeine = await _db.getTodaysCaffeineTotal();
    final count = await _db.getTodaysDrinkCount();
    final spending = await _db.getTodaysTotalSpending();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final logs = await _db.getLogsByDate(today);

    setState(() {
      _caffeineTotal = caffeine;
      _drinkCount = count;
      _totalSpending = spending;
      _todaysLogs = logs;
      _isLoading = false;
    });
  }

  /// Navigates to add drink screen and refreshes on return
  Future<void> _navigateToAddDrink() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDrinkScreen()),
    );
    _loadData();
  }

  /// Navigates to history screen and refreshes on return
  Future<void> _navigateToHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
    _loadData();
  }

  /// Navigates to manage flavors screen and refreshes on return
  Future<void> _navigateToManageFlavors() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageFlavorsScreen()),
    );
    _loadData();
  }

  /// Navigates to settings screen
  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    // Reload currency and refresh display
    await CurrencyHelper.initialize();
    _loadData();
  }

  /// Deletes a log entry with confirmation
  Future<void> _deleteLog(int logId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.deleteLog(logId);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monster Meter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_drink),
            onPressed: _navigateToManageFlavors,
            tooltip: 'Manage Flavors',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToHistory,
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildTodaysLogsSection(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddDrink,
        icon: const Icon(Icons.add),
        label: const Text('Add Drink'),
      ),
    );
  }

  /// Builds the statistics cards showing today's totals
  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Stats",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Drinks',
                _drinkCount.toString(),
                Icons.local_drink,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Caffeine',
                '${_caffeineTotal}mg',
                Icons.bolt,
                Colors.yellow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Spent',
                CurrencyHelper.formatPriceCached(_totalSpending),
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()), // Empty space for symmetry
          ],
        ),
      ],
    );
  }

  /// Builds a single statistics card
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the section showing today's drink logs
  Widget _buildTodaysLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Drinks",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (_todaysLogs.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.local_drink_outlined,
                        size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text(
                      'No drinks logged today',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todaysLogs.length,
            itemBuilder: (context, index) {
              final logWithFlavor = _todaysLogs[index];
              return _buildLogCard(logWithFlavor);
            },
          ),
      ],
    );
  }

  /// Builds a card for a single log entry
  Widget _buildLogCard(LogWithFlavor logWithFlavor) {
    final log = logWithFlavor.log;
    final flavor = logWithFlavor.flavor;
    final time = DateFormat('HH:mm').format(DateTime.parse(log.timestamp));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.2),
          child: const Icon(Icons.local_drink, color: Colors.green),
        ),
        title: Text(
          flavor.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${flavor.ml}ml • ${flavor.caffeineMg}mg caffeine'),
            Text('${CurrencyHelper.formatPriceCached(log.pricePaid)} • $time'),
            if (log.notes != null && log.notes!.isNotEmpty)
              Text(log.notes!, style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _deleteLog(log.id!),
        ),
      ),
    );
  }
}

