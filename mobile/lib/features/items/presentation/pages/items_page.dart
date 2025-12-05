import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/laundry_item.dart';
import '../bloc/item_bloc.dart';
import '../widgets/item_card.dart';
import '../widgets/item_form_dialog.dart';

/// Items management page.
class ItemsPage extends StatelessWidget {
  /// Creates the items page.
  const ItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ItemBloc>()..add(const LoadItems()),
      child: const _ItemsView(),
    );
  }
}

class _ItemsView extends StatelessWidget {
  const _ItemsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laundry Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (category) {
              context.read<ItemBloc>().add(
                    category.isEmpty
                        ? const LoadItems()
                        : LoadItems(category: category),
                  );
            },
            itemBuilder: (context) {
              final state = context.read<ItemBloc>().state;
              return [
                const PopupMenuItem(
                  value: '',
                  child: Text('All Categories'),
                ),
                ...state.categories.map(
                  (category) => PopupMenuItem(
                    value: category,
                    child: Text(category),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: BlocBuilder<ItemBloc, ItemState>(
        builder: (context, state) {
          if (state.status == ItemStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ItemStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ItemBloc>().add(const LoadItems()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_laundry_service_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first laundry item',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return ItemCard(
                item: item,
                onTap: () => _editItem(context, item),
                onFavoriteToggle: () =>
                    context.read<ItemBloc>().add(ToggleFavorite(item.id!)),
                onDelete: () => _deleteItem(context, item),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addItem(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _ItemSearchDelegate(context.read<ItemBloc>()),
    );
  }

  Future<void> _addItem(BuildContext context) async {
    final bloc = context.read<ItemBloc>();
    final result = await showDialog<LaundryItem>(
      context: context,
      builder: (context) => const ItemFormDialog(),
    );

    if (result != null) {
      bloc.add(CreateItem(result));
    }
  }

  Future<void> _editItem(BuildContext context, LaundryItem item) async {
    final bloc = context.read<ItemBloc>();
    final result = await showDialog<LaundryItem>(
      context: context,
      builder: (context) => ItemFormDialog(item: item),
    );

    if (result != null) {
      bloc.add(UpdateItem(result));
    }
  }

  Future<void> _deleteItem(BuildContext context, LaundryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Item'),
        content: Text(
          'Are you sure you want to archive "${item.name}"?\n\n'
          'Archived items can be restored later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      context.read<ItemBloc>().add(ArchiveItem(item.id!));
    }
  }
}

class _ItemSearchDelegate extends SearchDelegate<LaundryItem?> {
  _ItemSearchDelegate(this.bloc);

  final ItemBloc bloc;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text('Type to search items'),
      );
    }

    bloc.add(SearchItems(query));

    return BlocBuilder<ItemBloc, ItemState>(
      bloc: bloc,
      builder: (context, state) {
        if (state.items.isEmpty) {
          return const Center(
            child: Text('No items found'),
          );
        }

        return ListView.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final item = state.items[index];
            return ListTile(
              leading: const Icon(Icons.local_laundry_service),
              title: Text(item.name),
              subtitle: Text('₹${item.defaultRate.toStringAsFixed(2)}'),
              trailing: item.isFavorite
                  ? const Icon(Icons.star, color: Colors.amber)
                  : null,
              onTap: () => close(context, item),
            );
          },
        );
      },
    );
  }
}
