import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/journal_bloc.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/swipeable_transaction_card.dart';
import '../widgets/transaction_card.dart';

/// Laundry journal page.
class JournalPage extends StatelessWidget {
  /// Creates the journal page.
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<JournalBloc>()
        ..add(const LoadTransactions())
        ..add(const LoadPendingTransactions()),
      child: const _JournalView(),
    );
  }
}

class _JournalView extends StatelessWidget {
  const _JournalView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laundry Journal'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
              Tab(text: 'History', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PendingTab(),
            _HistoryTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addTransaction(context),
          icon: const Icon(Icons.add),
          label: const Text('New Entry'),
        ),
      ),
    );
  }

  Future<void> _addTransaction(BuildContext context) async {
    final bloc = context.read<JournalBloc>();
    final result = await showDialog<LaundryTransaction>(
      context: context,
      builder: (context) => const AddTransactionDialog(),
    );

    if (result != null) {
      bloc.add(CreateTransaction(result));
    }
  }
}

class _PendingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalBloc, JournalState>(
      builder: (context, state) {
        if (state.status == JournalStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.pendingTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'All caught up!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'No pending items',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Summary card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    label: 'Items',
                    value: state.pendingCount.toString(),
                    icon: Icons.local_laundry_service,
                  ),
                  _SummaryItem(
                    label: 'Amount',
                    value: '₹${state.pendingAmount.toStringAsFixed(0)}',
                    icon: Icons.currency_rupee,
                  ),
                  _SummaryItem(
                    label: 'Entries',
                    value: state.pendingTransactions.length.toString(),
                    icon: Icons.receipt_long,
                  ),
                ],
              ),
            ),

            // Pending transactions list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.pendingTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = state.pendingTransactions[index];
                  return SwipeableTransactionCard(
                    key: ValueKey('pending_${transaction.id}'),
                    transaction: transaction,
                    onStatusChange: (newStatus, previousStatus) {
                      context.read<JournalBloc>().add(
                            OptimisticUpdateStatus(
                              id: transaction.id!,
                              newStatus: newStatus,
                              previousStatus: previousStatus,
                              returnedAt: newStatus == TransactionStatus.returned
                                  ? DateTime.now()
                                  : null,
                            ),
                          );
                    },
                    onUndo: (previousStatus) {
                      context.read<JournalBloc>().add(
                            RevertOptimisticUpdate(
                              id: transaction.id!,
                              previousStatus: previousStatus,
                            ),
                          );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalBloc, JournalState>(
      builder: (context, state) {
        if (state.status == JournalStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No history yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your completed transactions will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
        }

        // Group transactions by date
        final grouped = <DateTime, List<LaundryTransaction>>{};
        for (final t in state.transactions) {
          final date = t.sentAt ?? t.createdAt ?? DateTime.now();
          final dateOnly = DateTime(date.year, date.month, date.day);
          grouped.putIfAbsent(dateOnly, () => []).add(t);
        }

        final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final date = dates[index];
            final transactions = grouped[date]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _formatDate(date),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ...transactions.map(
                  (t) => TransactionCard(
                    transaction: t,
                    onStatusChange: (status) {
                      context.read<JournalBloc>().add(
                            UpdateTransactionStatus(
                              id: t.id!,
                              status: status,
                            ),
                          );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMM d, y').format(date);
    }
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
      ],
    );
  }
}
