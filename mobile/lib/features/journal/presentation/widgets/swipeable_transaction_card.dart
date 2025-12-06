import 'package:flutter/material.dart';

import '../../domain/entities/transaction.dart';
import 'transaction_card.dart';

/// A wrapper widget that adds swipe-to-update functionality to TransactionCard.
///
/// Left swipe: Update status to In Progress
/// Right swipe: Update status to Returned
class SwipeableTransactionCard extends StatefulWidget {
  /// Creates a swipeable transaction card.
  const SwipeableTransactionCard({
    required this.transaction,
    required this.onStatusChange,
    required this.onUndo,
    super.key,
    this.onTap,
  });

  /// The transaction to display.
  final LaundryTransaction transaction;

  /// Called when status changes via swipe.
  /// Returns the previous status for undo functionality.
  final void Function(TransactionStatus newStatus, TransactionStatus previousStatus) onStatusChange;

  /// Called when user taps undo in the snackbar.
  final void Function(TransactionStatus previousStatus) onUndo;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  @override
  State<SwipeableTransactionCard> createState() => _SwipeableTransactionCardState();
}

class _SwipeableTransactionCardState extends State<SwipeableTransactionCard> {
  bool _isDismissed = false;

  bool _canSwipeLeft() {
    // Can transition to inProgress only from sent
    return widget.transaction.status == TransactionStatus.sent;
  }

  bool _canSwipeRight() {
    // Can transition to returned from sent or inProgress
    return widget.transaction.status == TransactionStatus.sent ||
        widget.transaction.status == TransactionStatus.inProgress;
  }

  void _handleSwipe(DismissDirection direction) {
    final previousStatus = widget.transaction.status;
    TransactionStatus newStatus;

    if (direction == DismissDirection.startToEnd) {
      // Right swipe -> Returned
      newStatus = TransactionStatus.returned;
    } else {
      // Left swipe -> In Progress
      newStatus = TransactionStatus.inProgress;
    }

    setState(() {
      _isDismissed = true;
    });

    // Notify parent of status change
    widget.onStatusChange(newStatus, previousStatus);

    // Show snackbar with undo option
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Status updated to ${_getStatusLabel(newStatus)}',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            widget.onUndo(previousStatus);
            setState(() {
              _isDismissed = false;
            });
          },
        ),
      ),
    );
  }

  String _getStatusLabel(TransactionStatus status) {
    return switch (status) {
      TransactionStatus.sent => 'Sent',
      TransactionStatus.inProgress => 'In Progress',
      TransactionStatus.returned => 'Returned',
      TransactionStatus.cancelled => 'Cancelled',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    final canSwipeLeft = _canSwipeLeft();
    final canSwipeRight = _canSwipeRight();

    // If neither swipe is allowed, just show the regular card
    if (!canSwipeLeft && !canSwipeRight) {
      return TransactionCard(
        transaction: widget.transaction,
        onStatusChange: (status) =>
            widget.onStatusChange(status, widget.transaction.status),
        onTap: widget.onTap,
      );
    }

    return Dismissible(
      key: Key('transaction_${widget.transaction.id}'),
      direction: _getDismissDirection(canSwipeLeft, canSwipeRight),
      confirmDismiss: (direction) async {
        // Validate the swipe direction
        if (direction == DismissDirection.endToStart && !canSwipeLeft) {
          return false;
        }
        if (direction == DismissDirection.startToEnd && !canSwipeRight) {
          return false;
        }
        return true;
      },
      onDismissed: _handleSwipe,
      background: _buildSwipeBackground(
        context,
        isRightSwipe: true,
        enabled: canSwipeRight,
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        isRightSwipe: false,
        enabled: canSwipeLeft,
      ),
      child: TransactionCard(
        transaction: widget.transaction,
        onStatusChange: (status) =>
            widget.onStatusChange(status, widget.transaction.status),
        onTap: widget.onTap,
      ),
    );
  }

  DismissDirection _getDismissDirection(bool canLeft, bool canRight) {
    if (canLeft && canRight) {
      return DismissDirection.horizontal;
    } else if (canRight) {
      return DismissDirection.startToEnd;
    } else if (canLeft) {
      return DismissDirection.endToStart;
    }
    return DismissDirection.none;
  }

  Widget _buildSwipeBackground(
    BuildContext context, {
    required bool isRightSwipe,
    required bool enabled,
  }) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    final color = isRightSwipe ? Colors.green : Colors.blue;
    final icon = isRightSwipe ? Icons.check_circle : Icons.autorenew;
    final label = isRightSwipe ? 'Returned' : 'In Progress';
    final alignment =
        isRightSwipe ? Alignment.centerLeft : Alignment.centerRight;
    final padding = isRightSwipe
        ? const EdgeInsets.only(left: 20)
        : const EdgeInsets.only(right: 20);

    return Container(
      alignment: alignment,
      padding: padding,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isRightSwipe) ...[
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: color, size: 28),
          if (isRightSwipe) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
