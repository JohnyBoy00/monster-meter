import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/flavor.dart';
import '../models/log.dart';
import '../models/user.dart';
import '../utils/currency_helper.dart';

/// Screen for adding a new drink entry
class AddDrinkScreen extends StatefulWidget {
  const AddDrinkScreen({super.key});

  @override
  State<AddDrinkScreen> createState() => _AddDrinkScreenState();
}

class _AddDrinkScreenState extends State<AddDrinkScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();

  List<Flavor> _flavors = [];
  Flavor? _selectedFlavor;
  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFlavors();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  /// Loads all active flavors from the database
  Future<void> _loadFlavors() async {
    final flavors = await _db.getActiveFlavors();
    setState(() {
      _flavors = flavors;
      _isLoading = false;
      if (_flavors.isNotEmpty) {
        _selectedFlavor = _flavors.first;
      }
    });
  }

  /// Saves the drink entry to the database
  Future<void> _saveDrink() async {
    if (!_formKey.currentState!.validate() || _selectedFlavor == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = await _db.getDefaultUser();
      if (user == null) {
        throw Exception('No user found');
      }

      final log = Log(
        userId: user.id!,
        flavorId: _selectedFlavor!.id!,
        pricePaid: double.parse(_priceController.text),
        timestamp: DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedDateTime),
        notes: null, // Notes removed from UI
      );

      await _db.createLog(log);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drink logged successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Shows date picker dialog
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  /// Shows time picker dialog
  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (time != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Drink'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _flavors.isEmpty
              ? _buildNoFlavorsView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFlavorSelector(),
                        const SizedBox(height: 24),
                        _buildPriceField(),
                        const SizedBox(height: 24),
                        _buildDateTimeSelector(),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                        const SizedBox(height: 24), // Extra padding at bottom
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Builds the view shown when no flavors are available
  Widget _buildNoFlavorsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_drink_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No flavors available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Please add some flavors first',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the flavor selector dropdown
  Widget _buildFlavorSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flavor',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Flavor>(
              value: _selectedFlavor,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _flavors.map((flavor) {
                return DropdownMenuItem(
                  value: flavor,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (flavor.imagePath != null) ...[
                        Image.asset(
                          flavor.imagePath!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.local_drink, size: 24);
                          },
                        ),
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        child: Text(
                          flavor.name,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedFlavor = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a flavor';
                }
                return null;
              },
            ),
            if (_selectedFlavor != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedFlavor!.ml}ml • ${_selectedFlavor!.caffeineMg}mg caffeine',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the price input field
  Widget _buildPriceField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                prefixIcon: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1.0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      CurrencyHelper.getCachedSymbol(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                hintText: '0.00',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                final price = double.tryParse(value);
                if (price == null || price < 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the date and time selector
  Widget _buildDateTimeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date & Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('MMM dd, yyyy').format(_selectedDateTime)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(DateFormat('HH:mm').format(_selectedDateTime)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the notes input field
  /// Builds the save button
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveDrink,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(
              'Save Drink',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}

