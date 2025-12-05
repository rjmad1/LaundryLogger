import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_logger/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper databaseHelper;

  setUpAll(() {
    // Initialize FFI for desktop testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper.instance;
    await databaseHelper.resetDatabase();
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  group('DatabaseHelper', () {
    group('initialization', () {
      test('should create database with correct tables', () async {
        final db = await databaseHelper.database;

        // Check that tables exist
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );

        final tableNames = tables.map((t) => t['name']).toList();
        expect(tableNames, contains('items'));
        expect(tableNames, contains('transactions'));
        expect(tableNames, contains('household_members'));
        expect(tableNames, contains('app_settings'));
      });

      test('should insert default items on creation', () async {
        final items = await databaseHelper.query(DatabaseHelper.tableItems);

        expect(items.length, greaterThan(0));
        expect(items.any((i) => i['name'] == 'Shirt'), isTrue);
        expect(items.any((i) => i['name'] == 'Pants'), isTrue);
      });

      test('should set correct schema version', () async {
        expect(DatabaseHelper.schemaVersion, equals(2));
      });
    });

    group('CRUD operations', () {
      test('should insert and query items', () async {
        final id = await databaseHelper.insert(DatabaseHelper.tableItems, {
          'name': 'Test Item',
          'default_rate': 10.0,
          'category': 'Test',
          'is_favorite': 0,
          'is_archived': 0,
          'sort_order': 100,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        expect(id, isPositive);

        final items = await databaseHelper.query(
          DatabaseHelper.tableItems,
          where: 'id = ?',
          whereArgs: [id],
        );

        expect(items.length, equals(1));
        expect(items.first['name'], equals('Test Item'));
      });

      test('should update items', () async {
        final id = await databaseHelper.insert(DatabaseHelper.tableItems, {
          'name': 'Original',
          'default_rate': 10.0,
          'is_favorite': 0,
          'is_archived': 0,
          'sort_order': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        await databaseHelper.update(
          DatabaseHelper.tableItems,
          {'name': 'Updated'},
          where: 'id = ?',
          whereArgs: [id],
        );

        final items = await databaseHelper.query(
          DatabaseHelper.tableItems,
          where: 'id = ?',
          whereArgs: [id],
        );

        expect(items.first['name'], equals('Updated'));
      });

      test('should delete items', () async {
        final id = await databaseHelper.insert(DatabaseHelper.tableItems, {
          'name': 'ToDelete',
          'default_rate': 10.0,
          'is_favorite': 0,
          'is_archived': 0,
          'sort_order': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        await databaseHelper.delete(
          DatabaseHelper.tableItems,
          where: 'id = ?',
          whereArgs: [id],
        );

        final items = await databaseHelper.query(
          DatabaseHelper.tableItems,
          where: 'id = ?',
          whereArgs: [id],
        );

        expect(items.isEmpty, isTrue);
      });
    });

    group('transaction support', () {
      test('should run operations in transaction', () async {
        await databaseHelper.runInTransaction((txn) async {
          await txn.insert(DatabaseHelper.tableMembers, {
            'name': 'Transaction Test',
            'is_active': 1,
            'is_archived': 0,
            'created_at': DateTime.now().toIso8601String(),
          });
        });

        final members =
            await databaseHelper.query(DatabaseHelper.tableMembers);
        expect(members.any((m) => m['name'] == 'Transaction Test'), isTrue);
      });

      test('should rollback on error', () async {
        final initialCount = (await databaseHelper.query(
          DatabaseHelper.tableMembers,
        ))
            .length;

        try {
          await databaseHelper.runInTransaction((txn) async {
            await txn.insert(DatabaseHelper.tableMembers, {
              'name': 'Before Error',
              'is_active': 1,
              'is_archived': 0,
              'created_at': DateTime.now().toIso8601String(),
            });
            throw Exception('Intentional error');
          });
        } catch (_) {
          // Expected error
        }

        final finalCount = (await databaseHelper.query(
          DatabaseHelper.tableMembers,
        ))
            .length;
        expect(finalCount, equals(initialCount));
      });

      test('should batch insert atomically', () async {
        final rows = List.generate(
          5,
          (i) => {
            'name': 'Batch $i',
            'is_active': 1,
            'is_archived': 0,
            'created_at': DateTime.now().toIso8601String(),
          },
        );

        await databaseHelper.batchInsert(DatabaseHelper.tableMembers, rows);

        final members =
            await databaseHelper.query(DatabaseHelper.tableMembers);
        final batchMembers =
            members.where((m) => (m['name'] as String).startsWith('Batch'));
        expect(batchMembers.length, equals(5));
      });
    });

    group('settings', () {
      test('should store and retrieve settings', () async {
        await databaseHelper.setSetting('test_key', 'test_value');
        final value = await databaseHelper.getSetting('test_key');

        expect(value, equals('test_value'));
      });

      test('should return null for missing settings', () async {
        final value = await databaseHelper.getSetting('nonexistent');
        expect(value, isNull);
      });

      test('should update existing settings', () async {
        await databaseHelper.setSetting('key', 'value1');
        await databaseHelper.setSetting('key', 'value2');

        final value = await databaseHelper.getSetting('key');
        expect(value, equals('value2'));
      });

      test('should delete settings', () async {
        await databaseHelper.setSetting('to_delete', 'value');
        await databaseHelper.deleteSetting('to_delete');

        final value = await databaseHelper.getSetting('to_delete');
        expect(value, isNull);
      });
    });

    group('export/import', () {
      test('should export all data', () async {
        final data = await databaseHelper.exportAllData();

        expect(data['schema_version'], equals(2));
        expect(data['exported_at'], isNotNull);
        expect(data['items'], isA<List>());
        expect(data['transactions'], isA<List>());
        expect(data['members'], isA<List>());
        expect(data['settings'], isA<List>());
      });

      test('should get stats', () async {
        final stats = await databaseHelper.getStats();

        expect(stats['items'], isNotNull);
        expect(stats['transactions'], isNotNull);
        expect(stats['members'], isNotNull);
      });

      test('should import data replacing existing', () async {
        // Create some data first
        await databaseHelper.insert(DatabaseHelper.tableMembers, {
          'name': 'Original Member',
          'is_active': 1,
          'is_archived': 0,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Import new data
        await databaseHelper.importAllData({
          'schema_version': 2,
          'items': [],
          'transactions': [],
          'members': [
            {
              'id': 1,
              'name': 'Imported Member',
              'is_active': 1,
              'is_archived': 0,
              'created_at': DateTime.now().toIso8601String(),
            },
          ],
          'settings': [],
        });

        final members =
            await databaseHelper.query(DatabaseHelper.tableMembers);
        expect(members.length, equals(1));
        expect(members.first['name'], equals('Imported Member'));
      });
    });
  });
}
