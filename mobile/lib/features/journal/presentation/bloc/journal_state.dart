part of 'journal_bloc.dart';

/// Journal loading status.
enum JournalStatus { initial, loading, success, failure }

/// Monthly spending comparison data.
class MonthlySummary extends Equatable {
  /// Creates a new MonthlySummary.
  const MonthlySummary({
    required this.currentMonthAmount,
    required this.previousMonthAmount,
    required this.currentMonthStart,
    required this.currentMonthEnd,
  });

  /// Current month's total spend.
  final double currentMonthAmount;

  /// Previous month's total spend.
  final double previousMonthAmount;

  /// Start of current month.
  final DateTime currentMonthStart;

  /// End of current month.
  final DateTime currentMonthEnd;

  /// Percentage change from previous month.
  /// Positive means spending increased, negative means decreased.
  double get percentageChange {
    if (previousMonthAmount == 0) {
      return currentMonthAmount > 0 ? 100.0 : 0.0;
    }
    return ((currentMonthAmount - previousMonthAmount) / previousMonthAmount) * 100;
  }

  /// Whether spending increased from last month.
  bool get isIncrease => currentMonthAmount > previousMonthAmount;

  /// Whether spending decreased from last month.
  bool get isDecrease => currentMonthAmount < previousMonthAmount;

  /// Absolute difference from previous month.
  double get absoluteDifference => currentMonthAmount - previousMonthAmount;

  @override
  List<Object?> get props => [
        currentMonthAmount,
        previousMonthAmount,
        currentMonthStart,
        currentMonthEnd,
      ];
}

/// State for the journal bloc.
final class JournalState extends Equatable {
  const JournalState({
    this.status = JournalStatus.initial,
    this.transactions = const [],
    this.pendingTransactions = const [],
    this.summary,
    this.monthlySummary,
    this.filter,
    this.error,
    this.hasMoreTransactions = true,
    this.currentPage = 0,
  });

  /// Current loading status.
  final JournalStatus status;

  /// List of transactions.
  final List<LaundryTransaction> transactions;

  /// List of pending transactions (sent or in progress).
  final List<LaundryTransaction> pendingTransactions;

  /// Spending summary.
  final SpendingSummary? summary;

  /// Monthly spending comparison.
  final MonthlySummary? monthlySummary;

  /// Current filter.
  final TransactionFilter? filter;

  /// Error message if status is failure.
  final String? error;

  /// Whether there are more transactions to load.
  final bool hasMoreTransactions;

  /// Current page for pagination.
  final int currentPage;

  /// Total number of pending items.
  int get pendingCount =>
      pendingTransactions.fold(0, (sum, t) => sum + t.quantity);

  /// Total pending amount.
  double get pendingAmount =>
      pendingTransactions.fold(0, (sum, t) => sum + t.totalCost);

  /// Creates a copy of this state with the given fields replaced.
  JournalState copyWith({
    JournalStatus? status,
    List<LaundryTransaction>? transactions,
    List<LaundryTransaction>? pendingTransactions,
    SpendingSummary? summary,
    MonthlySummary? monthlySummary,
    TransactionFilter? filter,
    String? error,
    bool? hasMoreTransactions,
    int? currentPage,
  }) {
    return JournalState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      summary: summary ?? this.summary,
      monthlySummary: monthlySummary ?? this.monthlySummary,
      filter: filter ?? this.filter,
      error: error ?? this.error,
      hasMoreTransactions: hasMoreTransactions ?? this.hasMoreTransactions,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        transactions,
        pendingTransactions,
        summary,
        monthlySummary,
        filter,
        error,
        hasMoreTransactions,
        currentPage,
      ];
}
