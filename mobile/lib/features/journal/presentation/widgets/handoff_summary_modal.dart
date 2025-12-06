import 'package:flutter/material.dart';

import '../../../household/domain/entities/household_member.dart';
import '../../../items/domain/entities/laundry_item.dart';
import '../../domain/entities/transaction.dart';

/// Modal to preview and confirm a handoff transaction before creation.
class HandoffSummaryModal extends StatelessWidget {
  /// Creates a handoff summary modal.
  const HandoffSummaryModal({
    required this.item,
    required this.quantity,
    required this.rate,
    super.key,
    this.member,
    this.notes,
  });

  /// The selected item.
  final LaundryItem item;

  /// Quantity of items.
  final int quantity;

  /// Rate (price at time).
  final double rate;

  /// Selected household member (optional).
  final HouseholdMember? member;

  /// Optional notes.
  final String? notes;

  /// Total amount.
  double get totalAmount => quantity * rate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.local_laundry_service,
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Review Handoff',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please confirm the details below',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Item details
                  _SummaryRow(
                    icon: Icons.checkroom,
                    label: 'Item',
                    value: item.name,
                  ),
                  const Divider(height: 24),

                  // Quantity
                  _SummaryRow(
                    icon: Icons.numbers,
                    label: 'Quantity',
                    value: quantity.toString(),
                  ),
                  const Divider(height: 24),

                  // Rate
                  _SummaryRow(
                    icon: Icons.currency_rupee,
                    label: 'Rate',
                    value: '₹${rate.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 24),

                  // Member (if selected)
                  if (member != null) ...[
                    _SummaryRow(
                      icon: Icons.person,
                      label: 'Member',
                      value: member!.name,
                    ),
                    const Divider(height: 24),
                  ],

                  // Notes (if any)
                  if (notes != null && notes!.isNotEmpty) ...[
                    _SummaryRow(
                      icon: Icons.note,
                      label: 'Notes',
                      value: notes!,
                    ),
                    const Divider(height: 24),
                  ],

                  // Total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the modal and returns the created transaction if confirmed.
  static Future<LaundryTransaction?> show({
    required BuildContext context,
    required LaundryItem item,
    required int quantity,
    required double rate,
    HouseholdMember? member,
    String? notes,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => HandoffSummaryModal(
        item: item,
        quantity: quantity,
        rate: rate,
        member: member,
        notes: notes,
      ),
    );

    if (confirmed ?? false) {
      return LaundryTransaction(
        itemId: item.id!,
        itemName: item.name,
        quantity: quantity,
        rate: rate,
        memberId: member?.id,
        memberName: member?.name,
        notes: notes?.isEmpty ?? false ? null : notes,
        sentAt: DateTime.now(),
      );
    }

    return null;
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
