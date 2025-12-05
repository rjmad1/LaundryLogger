import 'package:equatable/equatable.dart';

/// Status of a laundry transaction.
enum TransactionStatus {
  /// Item has been sent for ironing.
  sent,

  /// Item is being processed.
  inProgress,

  /// Item has been returned.
  returned,

  /// Transaction was cancelled.
  cancelled,
}

/// Represents a laundry transaction (journal entry).
///
/// A transaction records when items are sent for ironing
/// and tracks their status through the hand-off workflow.
class LaundryTransaction extends Equatable {
  /// Creates a new laundry transaction.
  const LaundryTransaction({
    required this.itemId, required this.itemName, required this.quantity, required this.rate, this.id,
    this.status = TransactionStatus.sent,
    this.memberId,
    this.memberName,
    this.notes,
    this.sentAt,
    this.returnedAt,
    this.createdAt,
  });

  /// Unique identifier for the transaction.
  final int? id;

  /// ID of the laundry item.
  final int itemId;

  /// Name of the item (denormalized for display).
  final String itemName;

  /// Number of items in this transaction.
  final int quantity;

  /// Rate charged per item.
  final double rate;

  /// Current status of the transaction.
  final TransactionStatus status;

  /// ID of the household member (optional).
  final int? memberId;

  /// Name of the household member (denormalized for display).
  final String? memberName;

  /// Additional notes for this transaction.
  final String? notes;

  /// When the items were sent.
  final DateTime? sentAt;

  /// When the items were returned.
  final DateTime? returnedAt;

  /// When the transaction was created.
  final DateTime? createdAt;

  /// Calculates the total cost for this transaction.
  double get totalCost => quantity * rate;

  /// Creates a copy of this transaction with the given fields replaced.
  LaundryTransaction copyWith({
    int? id,
    int? itemId,
    String? itemName,
    int? quantity,
    double? rate,
    TransactionStatus? status,
    int? memberId,
    String? memberName,
    String? notes,
    DateTime? sentAt,
    DateTime? returnedAt,
    DateTime? createdAt,
  }) {
    return LaundryTransaction(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      status: status ?? this.status,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      notes: notes ?? this.notes,
      sentAt: sentAt ?? this.sentAt,
      returnedAt: returnedAt ?? this.returnedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemId,
        itemName,
        quantity,
        rate,
        status,
        memberId,
        memberName,
        notes,
        sentAt,
        returnedAt,
        createdAt,
      ];
}
