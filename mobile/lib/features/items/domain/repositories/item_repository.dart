import '../entities/laundry_item.dart';

/// Repository interface for laundry items.
///
/// This defines the contract for item data operations
/// following the repository pattern. Uses soft-delete
/// via [archiveItem] instead of hard deletion.
abstract class ItemRepository {
  /// Gets all active (non-archived) items, optionally filtered by category.
  Future<List<LaundryItem>> getItems({String? category});

  /// Gets all archived items.
  Future<List<LaundryItem>> getArchivedItems();

  /// Gets a single item by ID (including archived).
  Future<LaundryItem?> getItemById(int id);

  /// Gets favorite items (non-archived only).
  Future<List<LaundryItem>> getFavoriteItems();

  /// Gets all unique categories from active items.
  Future<List<String>> getCategories();

  /// Creates a new item.
  Future<LaundryItem> createItem(LaundryItem item);

  /// Updates an existing item.
  Future<LaundryItem> updateItem(LaundryItem item);

  /// Archives an item (soft-delete).
  /// Returns true if the item was successfully archived.
  Future<bool> archiveItem(int id);

  /// Restores an archived item.
  /// Returns the restored item.
  Future<LaundryItem> restoreItem(int id);

  /// Permanently deletes an item (use with caution).
  /// Only works on archived items.
  Future<bool> deleteItemPermanently(int id);

  /// Toggles the favorite status of an item.
  Future<LaundryItem> toggleFavorite(int id);

  /// Reorders items (updates sort_order).
  Future<void> reorderItems(List<int> itemIds);

  /// Searches active items by name.
  Future<List<LaundryItem>> searchItems(String query);

  /// Checks if an item can be archived (no pending transactions).
  Future<bool> canArchiveItem(int id);
}
