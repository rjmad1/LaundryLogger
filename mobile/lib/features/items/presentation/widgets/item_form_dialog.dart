import 'package:flutter/material.dart';

import '../../domain/entities/laundry_item.dart';

/// Dialog for creating or editing a laundry item.
class ItemFormDialog extends StatefulWidget {
  /// Creates an item form dialog.
  const ItemFormDialog({super.key, this.item});

  /// The item to edit, or null for creating a new item.
  final LaundryItem? item;

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _rateController;
  late final TextEditingController _categoryController;
  late bool _isFavorite;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _rateController = TextEditingController(
      text: widget.item?.defaultRate.toStringAsFixed(2) ?? '',
    );
    _categoryController =
        TextEditingController(text: widget.item?.category ?? '');
    _isFavorite = widget.item?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Item' : 'Add Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g., Shirt, Pants',
                  prefixIcon: Icon(Icons.local_laundry_service),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Rate field
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(
                  labelText: 'Default Rate',
                  hintText: 'e.g., 25.00',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a rate';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null || rate <= 0) {
                    return 'Please enter a valid rate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category field
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  hintText: 'e.g., Clothing, Bedding',
                  prefixIcon: Icon(Icons.category),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Favorite toggle
              SwitchListTile(
                title: const Text('Favorite'),
                subtitle: const Text('Quick access in item selection'),
                value: _isFavorite,
                onChanged: (value) {
                  setState(() {
                    _isFavorite = value;
                  });
                },
                secondary: Icon(
                  _isFavorite ? Icons.star : Icons.star_border,
                  color: _isFavorite ? Colors.amber : null,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final item = LaundryItem(
      id: widget.item?.id,
      name: _nameController.text.trim(),
      defaultRate: double.parse(_rateController.text.trim()),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      isFavorite: _isFavorite,
      sortOrder: widget.item?.sortOrder ?? 0,
      createdAt: widget.item?.createdAt,
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(item);
  }
}
