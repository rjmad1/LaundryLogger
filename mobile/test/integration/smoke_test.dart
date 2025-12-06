import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_logger/core/database/database_helper.dart';
import 'package:laundry_logger/features/journal/data/repositories/transaction_repository_impl.dart';
import 'package:laundry_logger/features/journal/domain/entities/transaction.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Smoke integration test - validates core workflow:
/// Create transaction → Check pending count
@Tags(['integration'])
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Smoke Integration Tests', () {
    late DatabaseHelper db;
    late TransactionRepositoryImpl repository;

    setUp(() async {
      db = DatabaseHelper.instance;
      await db.resetDatabase();
      repository = TransactionRepositoryImpl(databaseHelper: db);
    });

    tearDown(() async {
      await db.resetDatabase();
      await db.close();
    });

    test('Create transaction and verify pending count', () async {
      // Arrange: Create a transaction
      const transaction = LaundryTransaction(
        itemId: 1,
        itemName: 'Test Shirt',
        quantity: 2,
        rate: 25,
      );

      // Act: Create and fetch pending
      await repository.createTransaction(transaction);
      final pending = await repository.getPendingTransactions();

      // Assert
      expect(pending.length, 1);
      expect(pending.first.itemName, 'Test Shirt');
      expect(pending.first.quantity, 2);
      expect(pending.first.status, TransactionStatus.sent);
    });

    test('Update status removes from pending', () async {
      // Arrange
      const transaction = LaundryTransaction(
        itemId: 1,
        itemName: 'Test Pants',
        quantity: 1,
        rate: 30,
      );

      final created = await repository.createTransaction(transaction);
      
      // Act: Mark as returned
      await repository.updateStatus(
        created.id!,
        TransactionStatus.returned,
      );

      final pending = await repository.getPendingTransactions();

      // Assert: Should not be in pending anymore
      expect(pending.isEmpty, true);
    });

    test('Performance: Query 5k transactions', () async {
      // Arrange: Create 5000 synthetic transactions
      final stopwatch = Stopwatch()..start();
      
      for (var i = 0; i < 5000; i++) {
        final transaction = LaundryTransaction(
          itemId: (i % 10) + 1,
          itemName: 'Item ${(i % 10) + 1}',
          quantity: (i % 5) + 1,
          rate: 20.0 + (i % 50),
          status: i % 3 == 0 ? TransactionStatus.returned : TransactionStatus.sent,
        );
        await repository.createTransaction(transaction);
      }

      stopwatch.stop();
      // Created 5k transactions

      // Act: Query transactions
      // ignore: cascade_invocations
      stopwatch.reset();
      // ignore: cascade_invocations
      stopwatch.start();
      
      final transactions = await repository.getTransactions(limit: 20);
      
      stopwatch.stop();
      final queryTime = stopwatch.elapsedMilliseconds;

      // Assert: First page should load fast
      expect(transactions.length, 20);
      expect(queryTime, lessThan(100), reason: 'Initial query should be <100ms');
      // Queried first 20 of 5k transactions
    });
  });
}
