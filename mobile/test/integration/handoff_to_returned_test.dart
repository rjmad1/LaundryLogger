import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_logger/core/database/database_helper.dart';
import 'package:laundry_logger/features/household/data/repositories/household_member_repository_impl.dart';
import 'package:laundry_logger/features/household/domain/entities/household_member.dart';
import 'package:laundry_logger/features/items/data/repositories/item_repository_impl.dart';
import 'package:laundry_logger/features/items/domain/entities/laundry_item.dart';
import 'package:laundry_logger/features/journal/data/repositories/transaction_repository_impl.dart';
import 'package:laundry_logger/features/journal/domain/entities/transaction.dart';
import 'package:laundry_logger/features/journal/domain/repositories/transaction_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Integration test for the complete hand-off to returned flow.
///
/// This tests the following user journey:
/// 1. Create household member
/// 2. Create/select items
/// 3. Create hand-off transaction (status: sent)
/// 4. View transaction in journal
/// 5. Mark transaction as returned
/// 6. Verify transaction history
void main() {
  late DatabaseHelper databaseHelper;
  late ItemRepositoryImpl itemRepository;
  late HouseholdMemberRepositoryImpl memberRepository;
  late TransactionRepositoryImpl transactionRepository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper.instance;
    await databaseHelper.resetDatabase();

    itemRepository = ItemRepositoryImpl(databaseHelper: databaseHelper);
    memberRepository = HouseholdMemberRepositoryImpl(databaseHelper: databaseHelper);
    transactionRepository = TransactionRepositoryImpl(databaseHelper: databaseHelper);
  });

  tearDown(() async {
    await databaseHelper.close();
  });

  group('Complete Hand-off to Returned Flow', () {
    test('should complete full transaction lifecycle', () async {
      // Step 1: Create a household member
      final member = await memberRepository.createMember(
        const HouseholdMember(name: 'John Doe', color: '#4CAF50'),
      );
      expect(member.id, isNotNull);
      expect(member.name, equals('John Doe'));

      // Step 2: Get available items (default items are created with DB)
      final items = await itemRepository.getItems();
      expect(items, isNotEmpty);
      final shirt = items.firstWhere((i) => i.name == 'Shirt');

      // Step 3: Create a hand-off transaction
      final transaction = await transactionRepository.createTransaction(
        LaundryTransaction(
          itemId: shirt.id!,
          itemName: shirt.name,
          quantity: 3,
          rate: shirt.defaultRate,
          memberId: member.id,
          memberName: member.name,
          sentAt: DateTime.now(),
        ),
      );
      expect(transaction.id, isNotNull);
      expect(transaction.status, equals(TransactionStatus.sent));

      // Step 4: Verify transaction appears in journal
      final pendingTransactions = await transactionRepository.getTransactions(
        filter: const TransactionFilter(status: TransactionStatus.sent),
      );
      expect(pendingTransactions.any((t) => t.id == transaction.id), isTrue);

      // Step 5: Mark transaction as returned
      final returnedTransaction = await transactionRepository.updateTransaction(
        transaction.copyWith(
          status: TransactionStatus.returned,
          returnedAt: DateTime.now(),
        ),
      );
      expect(returnedTransaction.status, equals(TransactionStatus.returned));
      expect(returnedTransaction.returnedAt, isNotNull);

      // Step 6: Verify transaction history
      final allTransactions = await transactionRepository.getTransactions();
      expect(allTransactions.any((t) => t.id == transaction.id), isTrue);

      final returned = allTransactions.firstWhere((t) => t.id == transaction.id);
      expect(returned.status, equals(TransactionStatus.returned));

      // Verify no more pending for this item
      final stillPending = await transactionRepository.getTransactions(
        filter: const TransactionFilter(status: TransactionStatus.sent),
      );
      expect(stillPending.any((t) => t.id == transaction.id), isFalse);
    });

    test('should handle multiple items in a batch', () async {
      final member = await memberRepository.createMember(
        const HouseholdMember(name: 'Jane Doe'),
      );

      final items = await itemRepository.getItems();
      final itemsToSend = items.take(3).toList();

      // Create transactions for multiple items
      final transactions = <LaundryTransaction>[];
      for (final item in itemsToSend) {
        final txn = await transactionRepository.createTransaction(
          LaundryTransaction(
            itemId: item.id!,
            itemName: item.name,
            quantity: 2,
            rate: item.defaultRate,
            memberId: member.id,
            memberName: member.name,
            sentAt: DateTime.now(),
          ),
        );
        transactions.add(txn);
      }

      expect(transactions.length, equals(3));

      // Verify all are pending
      final pending = await transactionRepository.getTransactions(
        filter: const TransactionFilter(status: TransactionStatus.sent),
      );
      expect(pending.length, greaterThanOrEqualTo(3));

      // Return all items
      for (final txn in transactions) {
        await transactionRepository.updateTransaction(
          txn.copyWith(
            status: TransactionStatus.returned,
            returnedAt: DateTime.now(),
          ),
        );
      }

      // Verify all returned
      final finalPending = await transactionRepository.getTransactions(
        filter: const TransactionFilter(status: TransactionStatus.sent),
      );
      for (final txn in transactions) {
        expect(finalPending.any((t) => t.id == txn.id), isFalse);
      }
    });

    test('should preserve rate when item default rate changes', () async {
      // Create a custom item
      final item = await itemRepository.createItem(const LaundryItem(
        name: 'Special Item',
        defaultRate: 50,
      ),);

      // Create transaction with current rate
      final transaction = await transactionRepository.createTransaction(
        LaundryTransaction(
          itemId: item.id!,
          itemName: item.name,
          quantity: 1,
          rate: item.defaultRate,
          sentAt: DateTime.now(),
        ),
      );

      // Update item default rate
      await itemRepository.updateItem(item.copyWith(defaultRate: 75));

      // Verify transaction still has original rate
      final fetched = await transactionRepository.getTransactionById(transaction.id!);
      expect(fetched!.rate, equals(50.0));

      // New transaction should use new rate
      final newTransaction = await transactionRepository.createTransaction(
        LaundryTransaction(
          itemId: item.id!,
          itemName: item.name,
          quantity: 1,
          rate: 75,
          sentAt: DateTime.now(),
        ),
      );
      expect(newTransaction.rate, equals(75.0));
    });

    test('should prevent archiving items with pending transactions', () async {
      final item = await itemRepository.createItem(const LaundryItem(
        name: 'Pending Item',
        defaultRate: 10,
      ),);

      // Create pending transaction
      await transactionRepository.createTransaction(
        LaundryTransaction(
          itemId: item.id!,
          itemName: item.name,
          quantity: 1,
          rate: item.defaultRate,
          sentAt: DateTime.now(),
        ),
      );

      // Try to archive - should fail
      final canArchive = await itemRepository.canArchiveItem(item.id!);
      expect(canArchive, isFalse);

      expect(
        () => itemRepository.archiveItem(item.id!),
        throwsA(isA<StateError>()),
      );
    });

    test('should allow archiving items after transactions returned', () async {
      final item = await itemRepository.createItem(const LaundryItem(
        name: 'Completed Item',
        defaultRate: 10,
      ),);

      final transaction = await transactionRepository.createTransaction(
        LaundryTransaction(
          itemId: item.id!,
          itemName: item.name,
          quantity: 1,
          rate: item.defaultRate,
          sentAt: DateTime.now(),
        ),
      );

      // Return the transaction
      await transactionRepository.updateTransaction(
        transaction.copyWith(
          status: TransactionStatus.returned,
          returnedAt: DateTime.now(),
        ),
      );

      // Now should be able to archive
      final canArchive = await itemRepository.canArchiveItem(item.id!);
      expect(canArchive, isTrue);

      final result = await itemRepository.archiveItem(item.id!);
      expect(result, isTrue);
    });

    test('should filter transactions by member', () async {
      final member1 = await memberRepository.createMember(
        const HouseholdMember(name: 'Member 1'),
      );
      final member2 = await memberRepository.createMember(
        const HouseholdMember(name: 'Member 2'),
      );

      final items = await itemRepository.getItems();
      final item = items.first;

      // Create transactions for different members
      await transactionRepository.createTransaction(
        LaundryTransaction(
          itemId: item.id!,
          itemName: item.name,
          quantity: 1,
          rate: item.defaultRate,
          memberId: member1.id,
          memberName: member1.name,
          sentAt: DateTime.now(),
        ),
      );

      await transactionRepository.createTransaction(
        LaundryTransaction(
          itemId: item.id!,
          itemName: item.name,
          quantity: 2,
          rate: item.defaultRate,
          memberId: member2.id,
          memberName: member2.name,
          sentAt: DateTime.now(),
        ),
      );

      // Filter by member
      final member1Txns = await transactionRepository.getTransactions(
        filter: TransactionFilter(memberId: member1.id),
      );
      expect(member1Txns.length, equals(1));
      expect(member1Txns.first.memberName, equals('Member 1'));
    });
  });
}
