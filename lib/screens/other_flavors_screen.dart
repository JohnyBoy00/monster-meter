import 'package:flutter/material.dart';
import '../database/database_helper.dart';

/// Lists every active flavor with how many times it was logged (including zero).
class OtherFlavorsScreen extends StatefulWidget {
  /// Shown under the app bar, e.g. "All time" or "April 2026".
  final String periodLabel;

  /// Inclusive log date range; both null means all-time.
  final String? startDate;
  final String? endDate;

  /// Creates the other-flavors breakdown screen.
  const OtherFlavorsScreen({
    super.key,
    required this.periodLabel,
    this.startDate,
    this.endDate,
  });

  @override
  State<OtherFlavorsScreen> createState() => _OtherFlavorsScreenState();
}

class _OtherFlavorsScreenState extends State<OtherFlavorsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  /// Loads flavor rows: all active flavors for all-time; for a date range, counts are
  /// scoped to that range and only flavors with at least one drink in the range are listed.
  Future<void> _loadRows() async {
    final scoped = widget.startDate != null && widget.endDate != null;
    final all = await _db.getAllActiveFlavorsWithDrinkCounts(
      startDate: widget.startDate,
      endDate: widget.endDate,
    );
    final filtered = scoped
        ? all
            .where((Map<String, dynamic> row) => (row['drinkCount'] as int) > 0)
            .toList()
        : all;
    setState(() {
      _rows = filtered;
      _isLoading = false;
    });
  }

  /// Returns a drink count phrase for [count] including zero.
  String _drinkCountLabel(int count) {
    if (count == 0) {
      return '0 drinks';
    }
    return count == 1 ? '1 drink' : '$count drinks';
  }

  @override
  Widget build(BuildContext context) {
    final scoped = widget.startDate != null && widget.endDate != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('All flavors'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              widget.periodLabel,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              scoped
                  ? 'Drinks logged during this period only (most often first).'
                  : 'Sorted by how often you logged each flavor.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? Center(
                        child: Text(
                          scoped
                              ? 'No drinks logged in this period.'
                              : 'No flavors to show.',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.white.withOpacity(0.06),
                        ),
                        itemBuilder: (context, index) {
                          final flavor = _rows[index];
                          final name = flavor['name'] as String;
                          final count = flavor['drinkCount'] as int;
                          final imagePath = flavor['imagePath'] as String?;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                if (imagePath != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      imagePath,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildPlaceholder();
                                      },
                                    ),
                                  )
                                else
                                  _buildPlaceholder(),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _drinkCountLabel(count),
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// Placeholder when a flavor has no image asset.
  Widget _buildPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.local_drink,
        color: Colors.grey[500],
        size: 28,
      ),
    );
  }
}
