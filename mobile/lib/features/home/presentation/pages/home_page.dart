import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Home page with bottom navigation.
class HomePage extends StatefulWidget {
  /// Creates the home page.
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laundry Logger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.pushNamed('settings'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardView(),
          _JournalView(),
          _ItemsView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: 'Items',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Show add transaction dialog
        },
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_laundry_service,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 32),
          const _SummaryCard(
            title: 'Items Sent',
            value: '0',
            icon: Icons.upload,
          ),
          const SizedBox(height: 16),
          const _SummaryCard(
            title: 'Items Returned',
            value: '0',
            icon: Icons.download,
          ),
          const SizedBox(height: 16),
          const _SummaryCard(
            title: 'This Month',
            value: '₹0.00',
            icon: Icons.currency_rupee,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
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
}

class _JournalView extends StatelessWidget {
  const _JournalView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Journal - Coming Soon'),
    );
  }
}

class _ItemsView extends StatelessWidget {
  const _ItemsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Items - Coming Soon'),
    );
  }
}
