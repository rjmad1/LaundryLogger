import '../../../../core/database/database_helper.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';

/// SQLite implementation of [TransactionRepository].
class TransactionRepositoryImpl implements TransactionRepository {
  /// Creates a new TransactionRepositoryImpl.
  TransactionRepositoryImpl({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<LaundryTransaction>> getTransactions({
    TransactionFilter? filter,
    int? limit,
    int? offset,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (filter != null) {
      final conditions = <String>[];
      whereArgs = <dynamic>[];

      if (filter.status != null) {
        conditions.add('status = ?');
        whereArgs.add(_statusToString(filter.status!));
      }
      if (filter.memberId != null) {
        conditions.add('member_id = ?');
        whereArgs.add(filter.memberId);
      }
      if (filter.itemId != null) {
        conditions.add('item_id = ?');
        whereArgs.add(filter.itemId);
      }
      if (filter.startDate != null) {
        conditions.add('sent_at >= ?');
        whereArgs.add(filter.startDate!.toIso8601String());
      }
      if (filter.endDate != null) {
        conditions.add('sent_at <= ?');
        whereArgs.add(filter.endDate!.toIso8601String());
      }

      if (conditions.isNotEmpty) {
        where = conditions.join(' AND ');
      }
    }

    final maps = await _databaseHelper.query(
      DatabaseHelper.tableTransactions,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps
        .map((map) => TransactionModel.fromMap(map).toEntity())
        .toList();
  }

  @override
  Future<LaundryTransaction?> getTransactionById(int id) async {
    final maps = await _databaseHelper.query(
      DatabaseHelper.tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return TransactionModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<List<LaundryTransaction>> getPendingTransactions() async {
    final maps = await _databaseHelper.query(
      DatabaseHelper.tableTransactions,
      where: 'status IN (?, ?)',
      whereArgs: ['sent', 'inProgress'],
      orderBy: 'sent_at ASC',
    );

    return maps
        .map((map) => TransactionModel.fromMap(map).toEntity())
        .toList();
  }

  @override
  Future<LaundryTransaction> createTransaction(
    LaundryTransaction transaction,
  ) async {
    final model = TransactionModel.fromEntity(transaction);
    final id = await _databaseHelper.insert(
      DatabaseHelper.tableTransactions,
      model.toInsertMap(),
    );

    return transaction.copyWith(
      id: id,
      createdAt: DateTime.now(),
      sentAt: transaction.sentAt ?? DateTime.now(),
    );
  }

  @override
  Future<LaundryTransaction> updateTransaction(
    LaundryTransaction transaction,
  ) async {
    if (transaction.id == null) {
      throw ArgumentError('Transaction must have an id to update');
    }

    final model = TransactionModel.fromEntity(transaction);
    await _databaseHelper.update(
      DatabaseHelper.tableTransactions,
      model.toUpdateMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );

    return transaction;
  }

  @override
  Future<LaundryTransaction> updateStatus(
    int id,
    TransactionStatus status, {
    DateTime? returnedAt,
  }) async {
    final transaction = await getTransactionById(id);
    if (transaction == null) {
      throw ArgumentError('Transaction not found: $id');
    }

    final updated = transaction.copyWith(
      status: status,
      returnedAt: status == TransactionStatus.returned
          ? (returnedAt ?? DateTime.now())
          : transaction.returnedAt,
    );

    return updateTransaction(updated);
  }

  @override
  Future<bool> deleteTransaction(int id) async {
    final count = await _databaseHelper.delete(
      DatabaseHelper.tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  @override
  Future<SpendingSummary> getSpendingSummary({
    DateTime? startDate,
    DateTime? endDate,
    int? memberId,
  }) async {
    final conditions = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      conditions.add('sent_at >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('sent_at <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    if (memberId != null) {
      conditions.add('member_id = ?');
      whereArgs.add(memberId);
    }

    final whereClause =
        conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    // Get totals
    final totals = await _databaseHelper.rawQuery('''
      SELECT 
        COALESCE(SUM(quantity * rate), 0) as total_amount,
        COALESCE(SUM(quantity), 0) as total_items,
        COUNT(*) as total_transactions
      FROM ${DatabaseHelper.tableTransactions}
      $whereClause
    ''', whereArgs,);

    final totalAmount = (totals.first['total_amount'] as num?)?.toDouble() ?? 0;
    final totalItems = (totals.first['total_items'] as int?) ?? 0;
    final totalTransactions = (totals.first['total_transactions'] as int?) ?? 0;

    // Get breakdown by member
    final memberBreakdown = await _databaseHelper.rawQuery('''
      SELECT 
        COALESCE(member_name, 'Unassigned') as member,
        SUM(quantity * rate) as amount
      FROM ${DatabaseHelper.tableTransactions}
      $whereClause
      GROUP BY member_id
    ''', whereArgs,);

    final byMember = <String, double>{};
    for (final row in memberBreakdown) {
      byMember[row['member'] as String] = (row['amount'] as num).toDouble();
    }

    return SpendingSummary(
      totalAmount: totalAmount,
      totalItems: totalItems,
      totalTransactions: totalTransactions,
      byMember: byMember,
    );
  }

  @override
  Future<Map<DateTime, List<LaundryTransaction>>> getTransactionsByDate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filter = TransactionFilter(startDate: startDate, endDate: endDate);
    final transactions = await getTransactions(filter: filter);

    final grouped = <DateTime, List<LaundryTransaction>>{};
    for (final transaction in transactions) {
      final date = transaction.sentAt ?? transaction.createdAt ?? DateTime.now();
      final dateOnly = DateTime(date.year, date.month, date.day);

      grouped.putIfAbsent(dateOnly, () => []).add(transaction);
    }

    return grouped;
  }

  String _statusToString(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.sent:
        return 'sent';
      case TransactionStatus.inProgress:
        return 'inProgress';
      case TransactionStatus.returned:
        return 'returned';
      case TransactionStatus.cancelled:
        return 'cancelled';
    }
  }
}
