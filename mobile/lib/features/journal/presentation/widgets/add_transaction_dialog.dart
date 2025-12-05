import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../household/domain/entities/household_member.dart';
import '../../../household/domain/repositories/household_member_repository.dart';
import '../../../items/domain/entities/laundry_item.dart';
import '../../../items/presentation/bloc/item_bloc.dart';
import 'handoff_summary_modal.dart';

/// Dialog for adding a new transaction.
class AddTransactionDialog extends StatefulWidget {
  /// Creates an add transaction dialog.
  const AddTransactionDialog({super.key});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _rateController;
  late final TextEditingController _notesController;

  LaundryItem? _selectedItem;
  HouseholdMember? _selectedMember;
  List<HouseholdMember> _members = [];

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _rateController = TextEditingController();
    _notesController = TextEditingController();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final repository = getIt<HouseholdMemberRepository>();
      final members = await repository.getMembers();
      setState(() {
        _members = members;
      });
    } catch (e) {
      // Ignore errors loading members
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onItemSelected(LaundryItem item) {
    setState(() {
      _selectedItem = item;
      _rateController.text = item.defaultRate.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ItemBloc>()..add(const LoadItems()),
      child: AlertDialog(
        title: const Text('New Laundry Entry'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Item selection
                BlocBuilder<ItemBloc, ItemState>(
                  builder: (context, state) {
                    if (state.status == ItemStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return DropdownButtonFormField<LaundryItem>(
                      initialValue: _selectedItem,
                      decoration: const InputDecoration(
                        labelText: 'Select Item',
                        prefixIcon: Icon(Icons.local_laundry_service),
                      ),
                      items: state.items.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item.name),
                        );
                      }).toList(),
                      onChanged: (item) {
                        if (item != null) {
                          _onItemSelected(item);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select an item';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Quantity and rate in a row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final qty = int.tryParse(value);
                          if (qty == null || qty <= 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _rateController,
                        decoration: const InputDecoration(
                          labelText: 'Rate',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final rate = double.tryParse(value);
                          if (rate == null || rate <= 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Member selection (optional)
                if (_members.isNotEmpty)
                  DropdownButtonFormField<HouseholdMember>(
                    initialValue: _selectedMember,
                    decoration: const InputDecoration(
                      labelText: 'Household Member (optional)',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: [
                      const DropdownMenuItem(
                        child: Text('None'),
                      ),
                      ..._members.map((member) {
                        return DropdownMenuItem(
                          value: member,
                          child: Text(member.name),
                        );
                      }),
                    ],
                    onChanged: (member) {
                      setState(() {
                        _selectedMember = member;
                      });
                    },
                  ),
                if (_members.isNotEmpty) const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),

                // Total preview
                if (_selectedItem != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total'),
                        Text(
                          '₹${_calculateTotal().toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
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
            child: const Text('Add Entry'),
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    return qty * rate;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = int.parse(_quantityController.text);
    final rate = double.parse(_rateController.text);
    final notes = _notesController.text.isEmpty ? null : _notesController.text;

    // Show the handoff summary modal for confirmation
    final transaction = await HandoffSummaryModal.show(
      context: context,
      item: _selectedItem!,
      quantity: quantity,
      rate: rate,
      member: _selectedMember,
      notes: notes,
    );

    // If confirmed, return the transaction
    if (transaction != null && mounted) {
      Navigator.of(context).pop(transaction);
    }
  }
}
