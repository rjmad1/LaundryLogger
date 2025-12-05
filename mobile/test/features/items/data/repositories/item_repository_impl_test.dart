import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_logger/core/database/database_helper.dart';
import 'package:laundry_logger/features/items/data/repositories/item_repository_impl.dart';
import 'package:laundry_logger/features/items/domain/entities/laundry_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late ItemRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper.instance;
    await databaseHelper.resetDatabase();
    repository = ItemRepositoryImpl(databaseHelper: databaseHelper);
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  group('ItemRepositoryImpl', () {
    group('getItems', () {
      test('should return all active items', () async {
        final items = await repository.getItems();
        // Default items are inserted on DB creation
        expect(items.length, greaterThan(0));
        expect(items.every((i) => !i.isArchived), isTrue);
      });

      test('should filter by category', () async {
        final clothingItems = await repository.getItems(category: 'Clothing');
        expect(clothingItems.every((i) => i.category == 'Clothing'), isTrue);
      });

      test('should not return archived items', () async {
        // Create and archive an item
        final item = await repository.createItem(const LaundryItem(
          name: 'Archived Test',
          defaultRate: 10,
        ),);
        await repository.archiveItem(item.id!);

        final items = await repository.getItems();
        expect(items.any((i) => i.name == 'Archived Test'), isFalse);
      });
    });

    group('getArchivedItems', () {
      test('should return only archived items', () async {
        final item = await repository.createItem(const LaundryItem(
          name: 'To Archive',
          defaultRate: 10,
        ),);
        await repository.archiveItem(item.id!);

        final archivedItems = await repository.getArchivedItems();
        expect(archivedItems.any((i) => i.name == 'To Archive'), isTrue);
        expect(archivedItems.every((i) => i.isArchived), isTrue);
      });
    });

    group('getItemById', () {
      test('should return item when exists', () async {
        final created = await repository.createItem(const LaundryItem(
          name: 'Find Me',
          defaultRate: 15,
        ),);

        final found = await repository.getItemById(created.id!);
        expect(found, isNotNull);
        expect(found!.name, equals('Find Me'));
      });

      test('should return null when not exists', () async {
        final found = await repository.getItemById(99999);
        expect(found, isNull);
      });

      test('should return archived items too', () async {
        final item = await repository.createItem(const LaundryItem(
          name: 'Archived Find',
          defaultRate: 10,
        ),);
        await repository.archiveItem(item.id!);

        final found = await repository.getItemById(item.id!);
        expect(found, isNotNull);
        expect(found!.isArchived, isTrue);
      });
    });

    group('getFavoriteItems', () {
      test('should return only favorite items', () async {
        await repository.createItem(const LaundryItem(
          name: 'Not Favorite',
          defaultRate: 10,
        ),);

        final favorites = await repository.getFavoriteItems();
        expect(favorites.every((i) => i.isFavorite), isTrue);
      });

      test('should not return archived favorites', () async {
        final item = await repository.createItem(const LaundryItem(
          name: 'Archived Fav',
          defaultRate: 10,
          isFavorite: true,
        ),);
        await repository.archiveItem(item.id!);

        final favorites = await repository.getFavoriteItems();
        expect(favorites.any((i) => i.name == 'Archived Fav'), isFalse);
      });
    });

    group('createItem', () {
      test('should create item with generated id', () async {
        final item = await repository.createItem(const LaundryItem(
          name: 'New Item',
          defaultRate: 25,
          category: 'Test',
        ),);

        expect(item.id, isNotNull);
        expect(item.id, isPositive);
        expect(item.name, equals('New Item'));
        expect(item.createdAt, isNotNull);
      });

      test('should set timestamps', () async {
        final before = DateTime.now();
        final item = await repository.createItem(const LaundryItem(
          name: 'Timestamped',
          defaultRate: 10,
        ),);
        final after = DateTime.now();

        expect(item.createdAt!.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(item.createdAt!.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('updateItem', () {
      test('should update item fields', () async {
        final item = await repository.createItem(const LaundryItem(
          name: 'Original',
          defaultRate: 10,
        ),);

        final updated = await repository.updateItem(
          item.copyWith(name: 'Updated', defaultRate: 20),
        );

        expect(updated.name, equals('Updated'));
        expect(updated.defaultRate, equals(20.0));

        final fetched = await repository.getItemById(item.id!);
        expect(fetched!.name, equals('Updated'));
      });

      test('should throw for item without id', () async {
        expect(
          () => repository.updateItem(const LaundryItem(
            name: 'No ID',
            defaultRate: 10,
          ),),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('archiveItem', () {
      test('should archive active item', () async {
        final item = await repository.createItem(const LaundryItem(
          name: 'To Archive',
          defaultRate: 10,
        ),);

        final result = await repository.archiveItem(item.id!);
        expect(result, isTrue);

        final fetched = await repository.getItemById(item.id!);
        expect(fetched!.isArchived, isTrue);
      });

      test('should throw for item with pending transactions', () async {
        // This test requires transaction data - will need integration test
      });
    });

    group('restoreItem', () {
      test('should restore archived item', () async {
        final item = await repository.createItem(const LaundryItem(
          name: 'To Restore',
          defaultRate: 10,
        ),);
        await repository.archiveItem(item.id!);

        final restored = await repository.restoreItem(item.id!);
        expect(restored.isArchived, isFalse);

        final items = await repository.getItems();
        expect(items.any((i) => i.name == 'To Restore'), isTrue);
      });
    });

    group('deleteItemPermanently', () {
      test('should delete archived item', () async {
        final item = await repository.createItem(const LaundryItem(
          name: 'To Delete',
          defaultRate: 10,
        ),);
        await repository.archiveItem(item.id!);

        final result = await repository.deleteItemPermanently(item.id!);
        expect(result, isTrue);

        final fetched = await repository.getItemById(item.id!);
        expect(fetched, isNull);
      });

      test('should throw for active item', () async {
        final item = await repository.createItem(const LaundryItem(
          name: 'Active',
          defaultRate: 10,
        ),);

        expect(
          () => repository.deleteItemPermanently(item.id!),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('toggleFavorite', () {
      test('should toggle favorite status', () async {
        final item = await repository.createItem(const LaundryItem(
          name: 'Toggle',
          defaultRate: 10,
        ),);

        final toggled = await repository.toggleFavorite(item.id!);
        expect(toggled.isFavorite, isTrue);

        final toggledAgain = await repository.toggleFavorite(item.id!);
        expect(toggledAgain.isFavorite, isFalse);
      });
    });

    group('searchItems', () {
      test('should find items by name', () async {
        await repository.createItem(const LaundryItem(
          name: 'Searchable Item',
          defaultRate: 10,
        ),);

        final results = await repository.searchItems('Search');
        expect(results.any((i) => i.name == 'Searchable Item'), isTrue);
      });

      test('should not find archived items', () async {
        final item = await repository.createItem(const LaundryItem(
          name: 'Hidden Search',
          defaultRate: 10,
        ),);
        await repository.archiveItem(item.id!);

        final results = await repository.searchItems('Hidden');
        expect(results.any((i) => i.name == 'Hidden Search'), isFalse);
      });
    });

    group('canArchiveItem', () {
      test('should return true for item without transactions', () async {
        final item = await repository.createItem(const LaundryItem(
          name: 'No Txns',
          defaultRate: 10,
        ),);

        final canArchive = await repository.canArchiveItem(item.id!);
        expect(canArchive, isTrue);
      });
    });
  });
}
