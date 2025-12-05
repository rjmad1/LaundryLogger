import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

part 'journal_event.dart';
part 'journal_state.dart';

/// BLoC for managing laundry journal/transactions.
class JournalBloc extends Bloc<JournalEvent, JournalState> {
  /// Creates a new JournalBloc.
  JournalBloc({required TransactionRepository transactionRepository})
      : _transactionRepository = transactionRepository,
        super(const JournalState()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<LoadPendingTransactions>(_onLoadPendingTransactions);
    on<LoadSpendingSummary>(_onLoadSpendingSummary);
    on<LoadMonthlySummary>(_onLoadMonthlySummary);
    on<CreateTransaction>(_onCreateTransaction);
    on<UpdateTransactionStatus>(_onUpdateTransactionStatus);
    on<OptimisticUpdateStatus>(_onOptimisticUpdateStatus);
    on<RevertOptimisticUpdate>(_onRevertOptimisticUpdate);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
  }

  final TransactionRepository _transactionRepository;

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<JournalState> emit,
  ) async {
    emit(state.copyWith(status: JournalStatus.loading));

    try {
      final transactions = await _transactionRepository.getTransactions(
        filter: event.filter,
      );

      emit(state.copyWith(
        status: JournalStatus.success,
        transactions: transactions,
        filter: event.filter,
      ),);
    } catch (e) {
      emit(state.copyWith(
        status: JournalStatus.failure,
        error: e.toString(),
      ),);
    }
  }

  Future<void> _onLoadPendingTransactions(
    LoadPendingTransactions event,
    Emitter<JournalState> emit,
  ) async {
    emit(state.copyWith(status: JournalStatus.loading));

    try {
      final pendingTransactions =
          await _transactionRepository.getPendingTransactions();

      emit(state.copyWith(
        status: JournalStatus.success,
        pendingTransactions: pendingTransactions,
      ),);
    } catch (e) {
      emit(state.copyWith(
        status: JournalStatus.failure,
        error: e.toString(),
      ),);
    }
  }

  Future<void> _onLoadSpendingSummary(
    LoadSpendingSummary event,
    Emitter<JournalState> emit,
  ) async {
    try {
      final summary = await _transactionRepository.getSpendingSummary(
        startDate: event.startDate,
        endDate: event.endDate,
        memberId: event.memberId,
      );

      emit(state.copyWith(summary: summary));
    } catch (e) {
      emit(state.copyWith(
        status: JournalStatus.failure,
        error: e.toString(),
      ),);
    }
  }

  Future<void> _onLoadMonthlySummary(
    LoadMonthlySummary event,
    Emitter<JournalState> emit,
  ) async {
    try {
      final now = DateTime.now();
      
      // Current month boundaries
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      
      // Previous month boundaries
      final previousMonthStart = DateTime(now.year, now.month - 1, 1);
      final previousMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

      // Fetch both summaries in parallel
      final results = await Future.wait([
        _transactionRepository.getSpendingSummary(
          startDate: currentMonthStart,
          endDate: currentMonthEnd,
        ),
        _transactionRepository.getSpendingSummary(
          startDate: previousMonthStart,
          endDate: previousMonthEnd,
        ),
      ]);

      final currentMonthSummary = results[0];
      final previousMonthSummary = results[1];

      emit(state.copyWith(
        monthlySummary: MonthlySummary(
          currentMonthAmount: currentMonthSummary.totalAmount,
          previousMonthAmount: previousMonthSummary.totalAmount,
          currentMonthStart: currentMonthStart,
          currentMonthEnd: currentMonthEnd,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: JournalStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCreateTransaction(
    CreateTransaction event,
    Emitter<JournalState> emit,
  ) async {
    try {
      final newTransaction =
          await _transactionRepository.createTransaction(event.transaction);

      final updatedTransactions = [newTransaction, ...state.transactions];

      // Update pending list if the transaction is pending
      var updatedPending = state.pendingTransactions;
      if (newTransaction.status == TransactionStatus.sent ||
          newTransaction.status == TransactionStatus.inProgress) {
        updatedPending = [newTransaction, ...state.pendingTransactions];
      }

      emit(state.copyWith(
        transactions: updatedTransactions,
        pendingTransactions: updatedPending,
      ),);
    } catch (e) {
      emit(state.copyWith(
        status: JournalStatus.failure,
        error: e.toString(),
      ),);
    }
  }

  Future<void> _onUpdateTransactionStatus(
    UpdateTransactionStatus event,
    Emitter<JournalState> emit,
  ) async {
    try {
      final updated = await _transactionRepository.updateStatus(
        event.id,
        event.status,
        returnedAt: event.returnedAt,
      );

      final updatedTransactions = state.transactions.map((t) {
        return t.id == updated.id ? updated : t;
      }).toList();

      // Update pending list
      List<LaundryTransaction> updatedPending;
      if (updated.status == TransactionStatus.returned ||
          updated.status == TransactionStatus.cancelled) {
        // Remove from pending
        updatedPending =
            state.pendingTransactions.where((t) => t.id != updated.id).toList();
      } else {
        // Update in pending
        updatedPending = state.pendingTransactions.map((t) {
          return t.id == updated.id ? updated : t;
        }).toList();
      }

      emit(state.copyWith(
        transactions: updatedTransactions,
        pendingTransactions: updatedPending,
      ),);
    } catch (e) {
      emit(state.copyWith(
        status: JournalStatus.failure,
        error: e.toString(),
      ),);
    }
  }

  /// Handles optimistic UI updates for swipe actions.
  /// Updates the UI immediately without waiting for DB.
  Future<void> _onOptimisticUpdateStatus(
    OptimisticUpdateStatus event,
    Emitter<JournalState> emit,
  ) async {
    // Validate transition is allowed
    if (!_isValidTransition(event.previousStatus, event.newStatus)) {
      emit(state.copyWith(
        status: JournalStatus.failure,
        error: 'Invalid status transition',
      ));
      return;
    }

    // Find the transaction
    final transaction = state.pendingTransactions.firstWhere(
      (t) => t.id == event.id,
      orElse: () => state.transactions.firstWhere((t) => t.id == event.id),
    );

    // Create optimistically updated transaction
    final updated = transaction.copyWith(
      status: event.newStatus,
      returnedAt: event.returnedAt,
    );

    // Update UI immediately (optimistic)
    final updatedTransactions = state.transactions.map((t) {
      return t.id == updated.id ? updated : t;
    }).toList();

    List<LaundryTransaction> updatedPending;
    if (event.newStatus == TransactionStatus.returned ||
        event.newStatus == TransactionStatus.cancelled) {
      updatedPending =
          state.pendingTransactions.where((t) => t.id != event.id).toList();
    } else {
      updatedPending = state.pendingTransactions.map((t) {
        return t.id == event.id ? updated : t;
      }).toList();
    }

    emit(state.copyWith(
      transactions: updatedTransactions,
      pendingTransactions: updatedPending,
    ));

    // Now perform the actual DB update
    try {
      await _transactionRepository.updateStatus(
        event.id,
        event.newStatus,
        returnedAt: event.returnedAt,
      );
      // Success - UI is already updated
    } catch (e) {
      // Failure - revert to previous state
      add(RevertOptimisticUpdate(
        id: event.id,
        previousStatus: event.previousStatus,
      ));
      emit(state.copyWith(
        status: JournalStatus.failure,
        error: 'Failed to update status. Reverted.',
      ));
    }
  }

  /// Reverts an optimistic update (for undo or error recovery).
  Future<void> _onRevertOptimisticUpdate(
    RevertOptimisticUpdate event,
    Emitter<JournalState> emit,
  ) async {
    try {
      // Revert in database first
      final reverted = await _transactionRepository.updateStatus(
        event.id,
        event.previousStatus,
      );

      final updatedTransactions = state.transactions.map((t) {
        return t.id == reverted.id ? reverted : t;
      }).toList();

      // If reverting to sent/inProgress, add back to pending
      List<LaundryTransaction> updatedPending;
      if (event.previousStatus == TransactionStatus.sent ||
          event.previousStatus == TransactionStatus.inProgress) {
        // Check if already in pending
        final alreadyInPending = state.pendingTransactions.any(
          (t) => t.id == event.id,
        );
        if (alreadyInPending) {
          updatedPending = state.pendingTransactions.map((t) {
            return t.id == reverted.id ? reverted : t;
          }).toList();
        } else {
          updatedPending = [reverted, ...state.pendingTransactions];
        }
      } else {
        updatedPending = state.pendingTransactions
            .where((t) => t.id != event.id)
            .toList();
      }

      emit(state.copyWith(
        status: JournalStatus.success,
        transactions: updatedTransactions,
        pendingTransactions: updatedPending,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: JournalStatus.failure,
        error: 'Failed to revert: ${e.toString()}',
      ));
    }
  }

  /// Validates if a status transition is allowed.
  bool _isValidTransition(
    TransactionStatus from,
    TransactionStatus to,
  ) {
    // Define valid transitions
    return switch ((from, to)) {
      // From sent: can go to inProgress, returned, or cancelled
      (TransactionStatus.sent, TransactionStatus.inProgress) => true,
      (TransactionStatus.sent, TransactionStatus.returned) => true,
      (TransactionStatus.sent, TransactionStatus.cancelled) => true,
      // From inProgress: can go to returned or cancelled
      (TransactionStatus.inProgress, TransactionStatus.returned) => true,
      (TransactionStatus.inProgress, TransactionStatus.cancelled) => true,
      // Everything else is invalid
      _ => false,
    };
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<JournalState> emit,
  ) async {
    try {
      final updated =
          await _transactionRepository.updateTransaction(event.transaction);

      final updatedTransactions = state.transactions.map((t) {
        return t.id == updated.id ? updated : t;
      }).toList();

      final updatedPending = state.pendingTransactions.map((t) {
        return t.id == updated.id ? updated : t;
      }).toList();

      emit(state.copyWith(
        transactions: updatedTransactions,
        pendingTransactions: updatedPending,
      ),);
    } catch (e) {
      emit(state.copyWith(
        status: JournalStatus.failure,
        error: e.toString(),
      ),);
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<JournalState> emit,
  ) async {
    try {
      await _transactionRepository.deleteTransaction(event.id);

      final updatedTransactions =
          state.transactions.where((t) => t.id != event.id).toList();
      final updatedPending =
          state.pendingTransactions.where((t) => t.id != event.id).toList();

      emit(state.copyWith(
        transactions: updatedTransactions,
        pendingTransactions: updatedPending,
      ),);
    } catch (e) {
      emit(state.copyWith(
        status: JournalStatus.failure,
        error: e.toString(),
      ),);
    }
  }
}
