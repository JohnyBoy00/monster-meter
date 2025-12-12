import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/flavor.dart';

/// Screen for managing Monster Energy flavors
class ManageFlavorsScreen extends StatefulWidget {
  const ManageFlavorsScreen({super.key});

  @override
  State<ManageFlavorsScreen> createState() => _ManageFlavorsScreenState();
}

class _ManageFlavorsScreenState extends State<ManageFlavorsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Flavor> _flavors = [];
  bool _isLoading = true;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadFlavors();
  }

  /// Loads flavors from the database
  Future<void> _loadFlavors() async {
    setState(() => _isLoading = true);
    final flavors = _showInactive
        ? await _db.getAllFlavors()
        : await _db.getActiveFlavors();
    setState(() {
      _flavors = flavors;
      _isLoading = false;
    });
  }

  /// Shows dialog to add a new flavor
  Future<void> _showAddFlavorDialog() async {
    final nameController = TextEditingController();
    final mlController = TextEditingController(text: '500');
    final caffeineController = TextEditingController(text: '140');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Flavor'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Flavor Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: mlController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Volume (ml)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter volume';
                    }
                    final ml = int.tryParse(value);
                    if (ml == null || ml <= 0) {
                      return 'Please enter a valid volume';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: caffeineController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Caffeine (mg)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter caffeine amount';
                    }
                    final caffeine = int.tryParse(value);
                    if (caffeine == null || caffeine < 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final flavor = Flavor(
                  name: nameController.text,
                  ml: int.parse(mlController.text),
                  caffeineMg: int.parse(caffeineController.text),
                );
                await _db.createFlavor(flavor);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadFlavors();
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Shows dialog to edit an existing flavor
  Future<void> _showEditFlavorDialog(Flavor flavor) async {
    final nameController = TextEditingController(text: flavor.name);
    final mlController = TextEditingController(text: flavor.ml.toString());
    final caffeineController =
        TextEditingController(text: flavor.caffeineMg.toString());
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Flavor'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Flavor Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: mlController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Volume (ml)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter volume';
                    }
                    final ml = int.tryParse(value);
                    if (ml == null || ml <= 0) {
                      return 'Please enter a valid volume';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: caffeineController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Caffeine (mg)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter caffeine amount';
                    }
                    final caffeine = int.tryParse(value);
                    if (caffeine == null || caffeine < 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final updatedFlavor = flavor.copyWith(
                  name: nameController.text,
                  ml: int.parse(mlController.text),
                  caffeineMg: int.parse(caffeineController.text),
                );
                await _db.updateFlavor(updatedFlavor);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadFlavors();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Toggles a flavor's active status
  Future<void> _toggleFlavorActive(Flavor flavor) async {
    final updatedFlavor = flavor.copyWith(isActive: !flavor.isActive);
    await _db.updateFlavor(updatedFlavor);
    _loadFlavors();
  }

  /// Deletes a flavor with confirmation
  Future<void> _deleteFlavor(Flavor flavor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flavor'),
        content: Text(
          'Are you sure you want to delete "${flavor.name}"? This action cannot be undone.',
        ),
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
      await _db.deleteFlavor(flavor.id!);
      _loadFlavors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Flavors'),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() => _showInactive = !_showInactive);
              _loadFlavors();
            },
            tooltip: _showInactive ? 'Hide Inactive' : 'Show Inactive',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _flavors.isEmpty
              ? _buildEmptyView()
              : RefreshIndicator(
                  onRefresh: _loadFlavors,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _flavors.length,
                    itemBuilder: (context, index) {
                      return _buildFlavorCard(_flavors[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFlavorDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Flavor'),
      ),
    );
  }

  /// Builds the view shown when no flavors exist
  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_drink_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No flavors yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first Monster Energy flavor',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a card for a single flavor
  Widget _buildFlavorCard(Flavor flavor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: flavor.imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  flavor.imagePath!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return CircleAvatar(
                      backgroundColor: flavor.isActive
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      child: Icon(
                        Icons.local_drink,
                        color: flavor.isActive ? Colors.green : Colors.grey,
                      ),
                    );
                  },
                ),
              )
            : CircleAvatar(
                backgroundColor: flavor.isActive
                    ? Colors.green.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                child: Icon(
                  Icons.local_drink,
                  color: flavor.isActive ? Colors.green : Colors.grey,
                ),
              ),
        title: Text(
          flavor.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: flavor.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          '${flavor.ml}ml • ${flavor.caffeineMg}mg caffeine',
          style: TextStyle(
            color: flavor.isActive ? Colors.grey : Colors.grey[700],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditFlavorDialog(flavor);
                break;
              case 'toggle':
                _toggleFlavorActive(flavor);
                break;
              case 'delete':
                _deleteFlavor(flavor);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    flavor.isActive ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(flavor.isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

