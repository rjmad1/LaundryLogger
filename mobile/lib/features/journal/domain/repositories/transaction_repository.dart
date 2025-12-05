import '../entities/transaction.dart';

/// Filter options for querying transactions.
class TransactionFilter {
  /// Creates a new TransactionFilter.
  const TransactionFilter({
    this.status,
    this.memberId,
    this.itemId,
    this.startDate,
    this.endDate,
  });

  final TransactionStatus? status;
  final int? memberId;
  final int? itemId;
  final DateTime? startDate;
  final DateTime? endDate;
}

/// Repository interface for laundry transactions.
abstract class TransactionRepository {
  /// Gets all transactions, optionally filtered.
  Future<List<LaundryTransaction>> getTransactions({
    TransactionFilter? filter,
    int? limit,
    int? offset,
  });

  /// Gets a single transaction by ID.
  Future<LaundryTransaction?> getTransactionById(int id);

  /// Gets pending transactions (sent or in progress).
  Future<List<LaundryTransaction>> getPendingTransactions();

  /// Creates a new transaction.
  Future<LaundryTransaction> createTransaction(LaundryTransaction transaction);

  /// Updates an existing transaction.
  Future<LaundryTransaction> updateTransaction(LaundryTransaction transaction);

  /// Updates the status of a transaction.
  Future<LaundryTransaction> updateStatus(
    int id,
    TransactionStatus status, {
    DateTime? returnedAt,
  });

  /// Deletes a transaction by ID.
  Future<bool> deleteTransaction(int id);

  /// Gets spending summary for a date range.
  Future<SpendingSummary> getSpendingSummary({
    DateTime? startDate,
    DateTime? endDate,
    int? memberId,
  });

  /// Gets transactions grouped by date.
  Future<Map<DateTime, List<LaundryTransaction>>> getTransactionsByDate({
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// Spending summary data.
class SpendingSummary {
  /// Creates a new SpendingSummary.
  const SpendingSummary({
    required this.totalAmount,
    required this.totalItems,
    required this.totalTransactions,
    this.byCategory = const {},
    this.byMember = const {},
  });

  /// Total amount spent.
  final double totalAmount;

  /// Total number of items.
  final int totalItems;

  /// Total number of transactions.
  final int totalTransactions;

  /// Breakdown by category.
  final Map<String, double> byCategory;

  /// Breakdown by household member.
  final Map<String, double> byMember;
}
