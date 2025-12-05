part of 'journal_bloc.dart';

/// Base class for journal events.
sealed class JournalEvent extends Equatable {
  const JournalEvent();

  @override
  List<Object?> get props => [];
}

/// Load transactions with optional filter.
final class LoadTransactions extends JournalEvent {
  const LoadTransactions({this.filter});

  final TransactionFilter? filter;

  @override
  List<Object?> get props => [filter];
}

/// Load pending transactions.
final class LoadPendingTransactions extends JournalEvent {
  const LoadPendingTransactions();
}

/// Load spending summary.
final class LoadSpendingSummary extends JournalEvent {
  const LoadSpendingSummary({
    this.startDate,
    this.endDate,
    this.memberId,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final int? memberId;

  @override
  List<Object?> get props => [startDate, endDate, memberId];
}

/// Load monthly spending summary (current vs previous month).
final class LoadMonthlySummary extends JournalEvent {
  const LoadMonthlySummary();
}

/// Create a new transaction.
final class CreateTransaction extends JournalEvent {
  const CreateTransaction(this.transaction);

  final LaundryTransaction transaction;

  @override
  List<Object?> get props => [transaction];
}

/// Update transaction status.
final class UpdateTransactionStatus extends JournalEvent {
  const UpdateTransactionStatus({
    required this.id,
    required this.status,
    this.returnedAt,
  });

  final int id;
  final TransactionStatus status;
  final DateTime? returnedAt;

  @override
  List<Object?> get props => [id, status, returnedAt];
}

/// Optimistic update for swipe actions - updates UI immediately.
final class OptimisticUpdateStatus extends JournalEvent {
  const OptimisticUpdateStatus({
    required this.id,
    required this.newStatus,
    required this.previousStatus,
    this.returnedAt,
  });

  final int id;
  final TransactionStatus newStatus;
  final TransactionStatus previousStatus;
  final DateTime? returnedAt;

  @override
  List<Object?> get props => [id, newStatus, previousStatus, returnedAt];
}

/// Revert optimistic update (for undo functionality).
final class RevertOptimisticUpdate extends JournalEvent {
  const RevertOptimisticUpdate({
    required this.id,
    required this.previousStatus,
  });

  final int id;
  final TransactionStatus previousStatus;

  @override
  List<Object?> get props => [id, previousStatus];
}

/// Update an existing transaction.
final class UpdateTransaction extends JournalEvent {
  const UpdateTransaction(this.transaction);

  final LaundryTransaction transaction;

  @override
  List<Object?> get props => [transaction];
}

/// Delete a transaction.
final class DeleteTransaction extends JournalEvent {
  const DeleteTransaction(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
