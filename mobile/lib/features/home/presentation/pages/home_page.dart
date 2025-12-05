import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../items/presentation/pages/items_page.dart';
import '../../../journal/domain/entities/transaction.dart';
import '../../../journal/presentation/bloc/journal_bloc.dart';
import '../../../journal/presentation/pages/journal_page.dart';
import '../../../journal/presentation/widgets/add_transaction_dialog.dart';
import '../widgets/monthly_spend_summary_card.dart';

/// Home page with bottom navigation.
class HomePage extends StatefulWidget {
  /// Creates the home page.
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  /// Navigate to the Journal tab (optionally to Pending tab).
  void _navigateToJournal({bool showPending = false}) {
    setState(() {
      _currentIndex = 1; // Journal is index 1
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<JournalBloc>()
        ..add(const LoadPendingTransactions())
        ..add(const LoadSpendingSummary())
        ..add(const LoadMonthlySummary()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Laundry Logger'),
              actions: [
                // Pending badge in app bar
                BlocBuilder<JournalBloc, JournalState>(
                  builder: (context, state) {
                    final pendingCount = state.pendingCount;
                    if (pendingCount == 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _PendingBadge(
                        count: pendingCount,
                        amount: state.pendingAmount,
                        onTap: () => _navigateToJournal(showPending: true),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => context.pushNamed('settings'),
                ),
              ],
            ),
            body: IndexedStack(
              index: _currentIndex,
              children: [
                _DashboardView(
                  onNavigateToJournal: () => _navigateToJournal(showPending: true),
                ),
                const JournalPage(),
                const ItemsPage(),
              ],
            ),
            bottomNavigationBar: BlocBuilder<JournalBloc, JournalState>(
              builder: (context, state) {
                return NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: state.pendingCount > 0,
                        label: Text(state.pendingCount.toString()),
                        child: const Icon(Icons.book_outlined),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: state.pendingCount > 0,
                        label: Text(state.pendingCount.toString()),
                        child: const Icon(Icons.book),
                      ),
                      label: 'Journal',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.checkroom_outlined),
                      selectedIcon: Icon(Icons.checkroom),
                      label: 'Items',
                    ),
                  ],
                );
              },
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _addTransaction(context),
              icon: const Icon(Icons.add),
              label: const Text('New Entry'),
            ),
          );
        },
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

class _DashboardView extends StatelessWidget {
  const _DashboardView({this.onNavigateToJournal});

  /// Callback to navigate to the Journal page.
  final VoidCallback? onNavigateToJournal;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalBloc, JournalState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                'Welcome to Laundry Logger',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Track your laundry with ease',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),

              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Pending Items',
                      value: state.pendingCount.toString(),
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Pending Amount',
                      value: '₹${state.pendingAmount.toStringAsFixed(0)}',
                      icon: Icons.currency_rupee,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'This Month',
                      value: '₹${state.summary?.totalAmount.toStringAsFixed(0) ?? '0'}',
                      icon: Icons.calendar_month,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Entries',
                      value: (state.summary?.totalTransactions ?? 0).toString(),
                      icon: Icons.receipt_long,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),

              // Monthly Spend Summary Card
              if (state.monthlySummary != null) ...[
                const SizedBox(height: 16),
                MonthlySpendSummaryCard(
                  monthlySummary: state.monthlySummary!,
                  onTap: onNavigateToJournal,
                ),
              ],

              // Pending transactions section
              if (state.pendingTransactions.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pending Items',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: onNavigateToJournal,
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...state.pendingTransactions.take(3).map(
                      (t) => _PendingItemTile(transaction: t),
                    ),
              ],

              // Quick actions
              const SizedBox(height: 32),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.add_circle,
                      label: 'New Entry',
                      onPressed: () {
                        // Show add dialog
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.checkroom,
                      label: 'Items',
                      onPressed: () {
                        // Navigate to items
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.analytics,
                      label: 'Reports',
                      onPressed: () {
                        // Show reports
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingItemTile extends StatelessWidget {
  const _PendingItemTile({required this.transaction});

  final LaundryTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.status == TransactionStatus.sent
              ? Colors.orange.shade100
              : Colors.blue.shade100,
          child: Icon(
            transaction.status == TransactionStatus.sent
                ? Icons.send
                : Icons.autorenew,
            color: transaction.status == TransactionStatus.sent
                ? Colors.orange
                : Colors.blue,
          ),
        ),
        title: Text(transaction.itemName),
        subtitle: Text('${transaction.quantity} × ₹${transaction.rate.toStringAsFixed(0)}'),
        trailing: Text(
          '₹${transaction.totalCost.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A badge widget showing pending count and amount.
class _PendingBadge extends StatelessWidget {
  const _PendingBadge({
    required this.count,
    required this.amount,
    required this.onTap,
  });

  final int count;
  final double amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
