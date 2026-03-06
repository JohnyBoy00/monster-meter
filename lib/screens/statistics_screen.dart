import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../utils/currency_helper.dart';

/// Screen displaying detailed statistics with charts and graphs
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  Map<String, dynamic> _weeklyStats = {};
  Map<String, dynamic> _monthlyStats = {};
  List<Map<String, dynamic>> _mostDrankFlavors = [];
  bool _isLoading = true;
  String _selectedPeriod = 'week'; // 'week' or 'month'
  
  // Current week/month being viewed
  late DateTime _currentWeekStart;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(DateTime.now());
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadStats();
  }

  /// Gets the start of the week (Monday) for a given date
  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Loads all statistics from the database
  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final weekStartStr = DateFormat('yyyy-MM-dd').format(_currentWeekStart);
    final weekly = await _db.getWeeklyStats(startDate: weekStartStr);
    final monthly = await _db.getMonthlyStats(
      year: _currentMonth.year,
      month: _currentMonth.month,
    );

    // Most drank flavors for the currently selected period
    String? flavorStart;
    String? flavorEnd;
    if (_selectedPeriod == 'week') {
      flavorStart = weekStartStr;
      flavorEnd = DateFormat('yyyy-MM-dd').format(
        _currentWeekStart.add(const Duration(days: 6)),
      );
    } else {
      flavorStart = DateFormat('yyyy-MM-dd').format(
        DateTime(_currentMonth.year, _currentMonth.month, 1),
      );
      flavorEnd = DateFormat('yyyy-MM-dd').format(
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0),
      );
    }
    final flavors = await _db.getMostDrankFlavors(
      limit: 10,
      startDate: flavorStart,
      endDate: flavorEnd,
    );

    setState(() {
      _weeklyStats = weekly;
      _monthlyStats = monthly;
      _mostDrankFlavors = flavors;
      _isLoading = false;
    });
  }

  /// Navigates to previous week
  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _loadStats();
  }

  /// Navigates to next week
  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    _loadStats();
  }

  /// Navigates to previous month
  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadStats();
  }

  /// Navigates to next month
  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadStats();
  }

  /// Resets to current week/month
  void _resetToCurrent() {
    setState(() {
      _currentWeekStart = _getWeekStart(DateTime.now());
      _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    });
    _loadStats();
  }

  /// Checks if current week is the same as the viewed week
  bool _isCurrentWeek() {
    final nowWeekStart = _getWeekStart(DateTime.now());
    return _currentWeekStart.year == nowWeekStart.year &&
        _currentWeekStart.month == nowWeekStart.month &&
        _currentWeekStart.day == nowWeekStart.day;
  }

  /// Checks if current month is the same as the viewed month
  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _currentMonth.year == now.year && _currentMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),
                    _buildPeriodSummary(),
                    const SizedBox(height: 24),
                    _buildDrinksChart(),
                    const SizedBox(height: 24),
                    _buildCaffeineChart(),
                    const SizedBox(height: 24),
                    _buildSpendingChart(),
                    const SizedBox(height: 24),
                    _buildMostDrankFlavors(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  /// Builds the period selector (Week/Month) with navigation
  Widget _buildPeriodSelector() {
    final isCurrentPeriod = _selectedPeriod == 'week'
        ? _isCurrentWeek()
        : _isCurrentMonth();

    String periodLabel;
    if (_selectedPeriod == 'week') {
      final weekEnd = _currentWeekStart.add(const Duration(days: 6));
      periodLabel =
          '${DateFormat('MMM d').format(_currentWeekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}';
    } else {
      periodLabel = DateFormat('MMMM yyyy').format(_currentMonth);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildPeriodButton('week', 'Week'),
              ),
              Expanded(
                child: _buildPeriodButton('month', 'Month'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Navigation controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _selectedPeriod == 'week' ? _previousWeek : _previousMonth,
                color: Colors.white,
                iconSize: 24,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: isCurrentPeriod ? null : _resetToCurrent,
                  child: Text(
                    periodLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCurrentPeriod
                          ? const Color(0xFF00FF00)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _selectedPeriod == 'week' ? _nextWeek : _nextMonth,
                color: Colors.white,
                iconSize: 24,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a period selector button
  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = period);
        // Reload stats when switching periods
        _loadStats();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00FF00).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF00FF00),
                  width: 1,
                )
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00FF00) : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  /// Builds the period summary cards
  Widget _buildPeriodSummary() {
    final stats = _selectedPeriod == 'week' ? _weeklyStats : _monthlyStats;
    String periodLabel;
    if (_selectedPeriod == 'week') {
      periodLabel = _isCurrentWeek() ? 'This Week' : 'Week';
    } else {
      periodLabel = _isCurrentMonth() ? 'This Month' : 'Month';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          periodLabel,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Drinks',
                (stats['totalDrinks'] ?? 0).toString(),
                Icons.local_drink,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Caffeine',
                '${stats['totalCaffeine'] ?? 0}mg',
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
              child: _buildSummaryCard(
                'Spent',
                CurrencyHelper.formatPriceCached(
                  (stats['totalSpending'] ?? 0.0).toDouble(),
                ),
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  /// Builds a summary card
  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the drinks chart
  Widget _buildDrinksChart() {
    final stats = _selectedPeriod == 'week' ? _weeklyStats : _monthlyStats;
    final dailyData = stats['dailyData'] as Map<String, dynamic>? ?? {};

    if (dailyData.isEmpty) {
      return _buildEmptyChart('No drinks data available');
    }

    final spots = _buildChartSpots(dailyData, 'drinks');
    final maxY = spots.isEmpty
        ? 10.0
        : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2;

    final chartTitle = _selectedPeriod == 'week' 
        ? 'Drinks per Day' 
        : 'Drinks per Week';

    return _buildChartCard(
      chartTitle,
      Icons.local_drink,
      Colors.green,
      LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.05),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= spots.length) {
                    return const SizedBox.shrink();
                  }
                  final sortedDates = dailyData.keys.toList()..sort();
                  if (index >= sortedDates.length) {
                    return const SizedBox.shrink();
                  }
                  final date = DateTime.parse(sortedDates[index]);
                  if (_selectedPeriod == 'week') {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('MMM d').format(date),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                    );
                  } else {
                    final weekEnd = date.add(const Duration(days: 6));
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${DateFormat('MMM d').format(date)}\n${DateFormat('MMM d').format(weekEnd)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 9,
                        ),
                      ),
                    );
                  }
                },
                reservedSize: _selectedPeriod == 'week' ? 50 : 60,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 50,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => const Color(0xFF1E1E1E),
              tooltipRoundedRadius: 8,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.green,
                    strokeWidth: 2,
                    strokeColor: Colors.green[300]!,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 0,
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the caffeine chart
  Widget _buildCaffeineChart() {
    final stats = _selectedPeriod == 'week' ? _weeklyStats : _monthlyStats;
    final dailyData = stats['dailyData'] as Map<String, dynamic>? ?? {};

    if (dailyData.isEmpty) {
      return _buildEmptyChart('No caffeine data available');
    }

    final spots = _buildChartSpots(dailyData, 'caffeine');
    final maxY = spots.isEmpty
        ? 500.0
        : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2;

    final chartTitle = _selectedPeriod == 'week' 
        ? 'Caffeine per Day (mg)' 
        : 'Caffeine per Week (mg)';

    return _buildChartCard(
      chartTitle,
      Icons.bolt,
      Colors.yellow,
      LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.05),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= spots.length) {
                    return const SizedBox.shrink();
                  }
                  final sortedDates = dailyData.keys.toList()..sort();
                  if (index >= sortedDates.length) {
                    return const SizedBox.shrink();
                  }
                  final date = DateTime.parse(sortedDates[index]);
                  if (_selectedPeriod == 'week') {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('MMM d').format(date),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                    );
                  } else {
                    // Monthly view: show week range
                    final weekEnd = date.add(const Duration(days: 6));
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${DateFormat('MMM d').format(date)}\n${DateFormat('MMM d').format(weekEnd)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 9,
                        ),
                      ),
                    );
                  }
                },
                reservedSize: _selectedPeriod == 'week' ? 50 : 60,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 50,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => const Color(0xFF1E1E1E),
              tooltipRoundedRadius: 8,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.yellow,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.yellow,
                    strokeWidth: 2,
                    strokeColor: Colors.yellow[300]!,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.yellow.withOpacity(0.1),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 0,
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the spending chart
  Widget _buildSpendingChart() {
    final stats = _selectedPeriod == 'week' ? _weeklyStats : _monthlyStats;
    final dailyData = stats['dailyData'] as Map<String, dynamic>? ?? {};

    if (dailyData.isEmpty) {
      return _buildEmptyChart('No spending data available');
    }

    final spots = _buildChartSpots(dailyData, 'spending');
    final maxY = spots.isEmpty
        ? 100.0
        : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2;

    final chartTitle = _selectedPeriod == 'week' 
        ? 'Spending per Day' 
        : 'Spending per Week';

    return _buildChartCard(
      chartTitle,
      Icons.account_balance_wallet,
      Colors.blue,
      LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.05),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= spots.length) {
                    return const SizedBox.shrink();
                  }
                  final sortedDates = dailyData.keys.toList()..sort();
                  if (index >= sortedDates.length) {
                    return const SizedBox.shrink();
                  }
                  final date = DateTime.parse(sortedDates[index]);
                  if (_selectedPeriod == 'week') {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('MMM d').format(date),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                    );
                  } else {
                    final weekEnd = date.add(const Duration(days: 6));
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${DateFormat('MMM d').format(date)}\n${DateFormat('MMM d').format(weekEnd)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 9,
                        ),
                      ),
                    );
                  }
                },
                reservedSize: _selectedPeriod == 'week' ? 50 : 60,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    CurrencyHelper.getCachedSymbol() +
                        value.toStringAsFixed(0),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 50,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => const Color(0xFF1E1E1E),
              tooltipRoundedRadius: 8,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.blue,
                    strokeWidth: 2,
                    strokeColor: Colors.blue[300]!,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 0,
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds chart spots from daily data
  List<FlSpot> _buildChartSpots(
    Map<String, dynamic> dailyData,
    String key,
  ) {
    final sortedDates = dailyData.keys.toList()..sort();
    return sortedDates.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final date = entry.value;
      final value = (dailyData[date] as Map<String, dynamic>)[key] ?? 0;
      return FlSpot(index, (value as num).toDouble());
    }).toList();
  }

  /// Builds a chart card container
  Widget _buildChartCard(
    String title,
    IconData icon,
    Color color,
    Widget chart,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: chart,
          ),
        ],
      ),
    );
  }

  /// Builds empty chart placeholder
  Widget _buildEmptyChart(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Builds the most drank flavors section
  Widget _buildMostDrankFlavors() {
    if (_mostDrankFlavors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'No flavor data available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final totalDrinks = _mostDrankFlavors
        .map((f) => f['drinkCount'] as int)
        .reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _selectedPeriod == 'week'
                    ? 'Most Drank Flavors for the week'
                    : 'Most Drank Flavors for the month',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Pie chart in a square to prevent oval distortion
          Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220, maxHeight: 220),
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: _mostDrankFlavors.asMap().entries.map((entry) {
                      final index = entry.key;
                      final flavor = entry.value;
                      final count = flavor['drinkCount'] as int;
                      final percentage = (count / totalDrinks) * 100;

                      final colors = [
                        Colors.green,
                        Colors.blue,
                        Colors.yellow,
                        Colors.orange,
                        Colors.purple,
                        Colors.pink,
                        Colors.red,
                        Colors.teal,
                        Colors.cyan,
                        Colors.indigo,
                      ];

                      return PieChartSectionData(
                        value: count.toDouble(),
                        title: percentage > 8
                            ? '${percentage.toStringAsFixed(0)}%'
                            : '',
                        color: colors[index % colors.length],
                        radius: 72,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _mostDrankFlavors.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final flavor = entry.value;
              final count = flavor['drinkCount'] as int;
              final percentage = (count / totalDrinks) * 100;

              final colors = [
                Colors.green,
                Colors.blue,
                Colors.yellow,
                Colors.orange,
                Colors.purple,
                Colors.pink,
                Colors.red,
                Colors.teal,
                Colors.cyan,
                Colors.indigo,
              ];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (flavor['imagePath'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          flavor['imagePath'] as String,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length]
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.local_drink,
                                size: 24,
                                color: colors[index % colors.length],
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length].withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.local_drink,
                          size: 24,
                          color: colors[index % colors.length],
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            flavor['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$count drinks • ${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

