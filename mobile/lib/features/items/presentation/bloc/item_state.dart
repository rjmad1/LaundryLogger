part of 'item_bloc.dart';

/// Item loading status.
enum ItemStatus { initial, loading, success, failure }

/// State for the item bloc.
final class ItemState extends Equatable {
  const ItemState({
    this.status = ItemStatus.initial,
    this.items = const [],
    this.archivedItems = const [],
    this.categories = const [],
    this.selectedCategory,
    this.error,
    this.searchQuery,
    this.canArchiveItem = true,
    this.showingArchived = false,
  });

  /// Current loading status.
  final ItemStatus status;

  /// List of active items.
  final List<LaundryItem> items;

  /// List of archived items.
  final List<LaundryItem> archivedItems;

  /// Available categories.
  final List<String> categories;

  /// Currently selected category filter.
  final String? selectedCategory;

  /// Error message if status is failure.
  final String? error;

  /// Current search query.
  final String? searchQuery;

  /// Whether the currently checked item can be archived.
  final bool canArchiveItem;

  /// Whether currently showing archived items.
  final bool showingArchived;

  /// Creates a copy of this state with the given fields replaced.
  ItemState copyWith({
    ItemStatus? status,
    List<LaundryItem>? items,
    List<LaundryItem>? archivedItems,
    List<String>? categories,
    String? selectedCategory,
    String? error,
    String? searchQuery,
    bool? canArchiveItem,
    bool? showingArchived,
  }) {
    return ItemState(
      status: status ?? this.status,
      items: items ?? this.items,
      archivedItems: archivedItems ?? this.archivedItems,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      canArchiveItem: canArchiveItem ?? this.canArchiveItem,
      showingArchived: showingArchived ?? this.showingArchived,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        archivedItems,
        categories,
        selectedCategory,
        error,
        searchQuery,
        canArchiveItem,
        showingArchived,
      ];
}
