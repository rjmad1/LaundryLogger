import '../../../../core/database/database_helper.dart';
import '../../domain/entities/laundry_item.dart';
import '../../domain/repositories/item_repository.dart';
import '../models/laundry_item_model.dart';

/// SQLite implementation of [ItemRepository].
///
/// Uses soft-delete pattern via is_archived column.
class ItemRepositoryImpl implements ItemRepository {
  /// Creates a new ItemRepositoryImpl.
  ItemRepositoryImpl({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<LaundryItem>> getItems({String? category}) async {
    var where = 'is_archived = 0';
    final whereArgs = <dynamic>[];

    if (category != null) {
      where += ' AND category = ?';
      whereArgs.add(category);
    }

    final maps = await _databaseHelper.query(
      DatabaseHelper.tableItems,
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'sort_order ASC, name ASC',
    );

    return maps.map((map) => LaundryItemModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<List<LaundryItem>> getArchivedItems() async {
    final maps = await _databaseHelper.query(
      DatabaseHelper.tableItems,
      where: 'is_archived = 1',
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => LaundryItemModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<LaundryItem?> getItemById(int id) async {
    final maps = await _databaseHelper.query(
      DatabaseHelper.tableItems,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }
    return LaundryItemModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<List<LaundryItem>> getFavoriteItems() async {
    final maps = await _databaseHelper.query(
      DatabaseHelper.tableItems,
      where: 'is_favorite = 1 AND is_archived = 0',
      orderBy: 'sort_order ASC, name ASC',
    );

    return maps.map((map) => LaundryItemModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<List<String>> getCategories() async {
    final maps = await _databaseHelper.rawQuery('''
      SELECT DISTINCT category FROM ${DatabaseHelper.tableItems}
      WHERE category IS NOT NULL AND is_archived = 0
      ORDER BY category ASC
    ''');

    return maps
        .map((map) => map['category'] as String?)
        .where((c) => c != null)
        .cast<String>()
        .toList();
  }

  @override
  Future<LaundryItem> createItem(LaundryItem item) async {
    final model = LaundryItemModel.fromEntity(item);
    final id = await _databaseHelper.insert(
      DatabaseHelper.tableItems,
      model.toInsertMap(),
    );

    return item.copyWith(
      id: id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<LaundryItem> updateItem(LaundryItem item) async {
    if (item.id == null) {
      throw ArgumentError('Item must have an id to update');
    }

    final model = LaundryItemModel.fromEntity(item);
    await _databaseHelper.update(
      DatabaseHelper.tableItems,
      model.toUpdateMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );

    return item.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<bool> archiveItem(int id) async {
    // Check for pending transactions first
    final canArchive = await canArchiveItem(id);
    if (!canArchive) {
      throw StateError(
        'Cannot archive item with pending transactions. '
        'Mark all transactions as returned first.',
      );
    }

    final count = await _databaseHelper.update(
      DatabaseHelper.tableItems,
      {
        'is_archived': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  @override
  Future<LaundryItem> restoreItem(int id) async {
    await _databaseHelper.update(
      DatabaseHelper.tableItems,
      {
        'is_archived': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    final item = await getItemById(id);
    if (item == null) {
      throw ArgumentError('Item not found: $id');
    }
    return item;
  }

  @override
  Future<bool> deleteItemPermanently(int id) async {
    // Only allow permanent deletion of archived items
    final item = await getItemById(id);
    if (item == null) {
      return false;
    }

    if (!item.isArchived) {
      throw StateError(
        'Cannot permanently delete active items. Archive first.',
      );
    }

    final count = await _databaseHelper.delete(
      DatabaseHelper.tableItems,
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  @override
  Future<LaundryItem> toggleFavorite(int id) async {
    final item = await getItemById(id);
    if (item == null) {
      throw ArgumentError('Item not found: $id');
    }

    final updated = item.copyWith(isFavorite: !item.isFavorite);
    return updateItem(updated);
  }

  @override
  Future<void> reorderItems(List<int> itemIds) async {
    for (var i = 0; i < itemIds.length; i++) {
      await _databaseHelper.update(
        DatabaseHelper.tableItems,
        {'sort_order': i, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [itemIds[i]],
      );
    }
  }

  @override
  Future<List<LaundryItem>> searchItems(String query) async {
    final maps = await _databaseHelper.query(
      DatabaseHelper.tableItems,
      where: 'name LIKE ? AND is_archived = 0',
      whereArgs: ['%$query%'],
      orderBy: 'sort_order ASC, name ASC',
    );

    return maps.map((map) => LaundryItemModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<bool> canArchiveItem(int id) async {
    // Check for pending transactions (status != 'returned')
    final pendingTransactions = await _databaseHelper.rawQuery('''
      SELECT COUNT(*) as count FROM ${DatabaseHelper.tableTransactions}
      WHERE item_id = ? AND status != 'returned'
    ''', [id],);

    final count = pendingTransactions.first['count'] as int? ?? 0;
    return count == 0;
  }
}
