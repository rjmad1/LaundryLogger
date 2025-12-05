import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Database helper for SQLite operations.
///
/// This class manages the SQLite database connection and
/// provides methods for CRUD operations. It follows the
/// singleton pattern to ensure a single database instance.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  /// Database name.
  static const String _databaseName = 'laundry_logger.db';

  /// Current database version.
  static const int _databaseVersion = 2;

  /// Schema version for backup compatibility.
  static const int schemaVersion = 2;

  /// Table names.
  static const String tableItems = 'items';
  static const String tableTransactions = 'transactions';
  static const String tableMembers = 'household_members';
  static const String tableSettings = 'app_settings';

  /// Valid transaction status values.
  static const List<String> validTransactionStatuses = [
    'sent',
    'in_progress',
    'returned',
  ];

  /// Gets the database instance, creating it if necessary.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initializes the database.
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configure database settings (e.g., foreign keys).
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Creates the database tables.
  Future<void> _onCreate(Database db, int version) async {
    await _createTablesV2(db);
    await _createIndexes(db);
    await _insertDefaultItems(db);
  }

  /// Creates tables for schema version 2.
  Future<void> _createTablesV2(Database db) async {
    // Create items table with soft delete support
    await db.execute('''
      CREATE TABLE $tableItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        default_rate REAL NOT NULL,
        category TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create transactions table with price_at_time and status constraint
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        rate REAL NOT NULL,
        price_at_time REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'sent' CHECK(status IN ('sent', 'inProgress', 'returned', 'cancelled')),
        member_id INTEGER,
        member_name TEXT,
        notes TEXT,
        sent_at TEXT,
        returned_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES $tableItems (id) ON DELETE RESTRICT,
        FOREIGN KEY (member_id) REFERENCES $tableMembers (id) ON DELETE SET NULL
      )
    ''');

    // Create household members table with soft delete
    await db.execute('''
      CREATE TABLE $tableMembers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Create app settings table for PIN, preferences, etc.
    await db.execute('''
      CREATE TABLE $tableSettings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Creates indexes for query performance.
  Future<void> _createIndexes(Database db) async {
    // Transaction indexes for filter performance
    await db.execute(
      'CREATE INDEX idx_transactions_status ON $tableTransactions (status)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_item_id ON $tableTransactions (item_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_member_id ON $tableTransactions (member_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_sent_at ON $tableTransactions (sent_at)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_created_at ON $tableTransactions (created_at)',
    );

    // Items indexes
    await db.execute(
      'CREATE INDEX idx_items_is_archived ON $tableItems (is_archived)',
    );
    await db.execute(
      'CREATE INDEX idx_items_category ON $tableItems (category)',
    );

    // Members indexes
    await db.execute(
      'CREATE INDEX idx_members_is_archived ON $tableMembers (is_archived)',
    );
  }

  /// Handles database upgrades with migrations.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration from v1 to v2
    if (oldVersion < 2) {
      await _migrateV1ToV2(db);
    }
  }

  /// Migration from schema v1 to v2.
  Future<void> _migrateV1ToV2(Database db) async {
    // Add price_at_time column to transactions
    await db.execute(
      'ALTER TABLE $tableTransactions ADD COLUMN price_at_time REAL',
    );

    // Backfill price_at_time with existing rate values
    await db.execute(
      'UPDATE $tableTransactions SET price_at_time = rate WHERE price_at_time IS NULL',
    );

    // Add is_archived to items
    await db.execute(
      'ALTER TABLE $tableItems ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0',
    );

    // Add is_archived to members
    await db.execute(
      'ALTER TABLE $tableMembers ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0',
    );

    // Create settings table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSettings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create new indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_items_is_archived ON $tableItems (is_archived)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_members_is_archived ON $tableMembers (is_archived)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON $tableTransactions (created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_items_category ON $tableItems (category)',
    );
  }

  /// Inserts default laundry items.
  Future<void> _insertDefaultItems(Database db) async {
    final now = DateTime.now().toIso8601String();

    final defaultItems = [
      {'name': 'Shirt', 'default_rate': 25.0, 'category': 'Clothing'},
      {'name': 'T-Shirt', 'default_rate': 20.0, 'category': 'Clothing'},
      {'name': 'Pants', 'default_rate': 30.0, 'category': 'Clothing'},
      {'name': 'Jeans', 'default_rate': 35.0, 'category': 'Clothing'},
      {'name': 'Kurta', 'default_rate': 30.0, 'category': 'Clothing'},
      {'name': 'Saree', 'default_rate': 50.0, 'category': 'Clothing'},
      {'name': 'Suit (2pc)', 'default_rate': 100.0, 'category': 'Formal'},
      {'name': 'Suit (3pc)', 'default_rate': 150.0, 'category': 'Formal'},
      {'name': 'Bedsheet', 'default_rate': 40.0, 'category': 'Bedding'},
      {'name': 'Pillow Cover', 'default_rate': 15.0, 'category': 'Bedding'},
      {'name': 'Curtain', 'default_rate': 50.0, 'category': 'Home'},
      {'name': 'Tablecloth', 'default_rate': 30.0, 'category': 'Home'},
    ];

    for (var i = 0; i < defaultItems.length; i++) {
      await db.insert(tableItems, {
        ...defaultItems[i],
        'is_favorite': 0,
        'is_archived': 0,
        'sort_order': i,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  // ============ Generic CRUD Operations ============

  /// Inserts a row into the specified table.
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(table, data);
  }

  /// Updates rows in the specified table.
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return db.update(table, data, where: where, whereArgs: whereArgs);
  }

  /// Deletes rows from the specified table.
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Queries the specified table.
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Executes a raw SQL query.
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, arguments);
  }

  // ============ Atomic Transaction Support ============

  /// Executes operations within an atomic database transaction.
  /// Rolls back on any error and rethrows with context.
  Future<T> runInTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await database;
    try {
      return await db.transaction(action);
    } catch (e) {
      throw DatabaseException('Transaction failed: $e');
    }
  }

  /// Batch insert multiple rows atomically.
  Future<void> batchInsert(
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert(table, row);
      }
      await batch.commit(noResult: true);
    });
  }

  // ============ Settings Operations ============

  /// Gets a setting value by key.
  Future<String?> getSetting(String key) async {
    final results = await query(
      tableSettings,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  /// Sets a setting value.
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      tableSettings,
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes a setting.
  Future<void> deleteSetting(String key) async {
    await delete(tableSettings, where: 'key = ?', whereArgs: [key]);
  }

  // ============ Backup & Restore ============

  /// Gets database statistics for backup preview.
  Future<Map<String, int>> getStats() async {
    final db = await database;
    final itemCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $tableItems WHERE is_archived = 0',
          ),
        ) ??
        0;
    final transactionCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tableTransactions'),
        ) ??
        0;
    final memberCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $tableMembers WHERE is_archived = 0',
          ),
        ) ??
        0;

    return {
      'items': itemCount,
      'transactions': transactionCount,
      'members': memberCount,
    };
  }

  /// Exports all data as a map for backup.
  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;

    final items = await db.query(tableItems);
    final transactions = await db.query(tableTransactions);
    final members = await db.query(tableMembers);
    final settings = await db.query(tableSettings);

    return {
      'schema_version': schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'items': items,
      'transactions': transactions,
      'members': members,
      'settings': settings,
    };
  }

  /// Imports data from a backup, replacing existing data.
  Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await database;

    await db.transaction((txn) async {
      // Clear existing data in correct order for foreign keys
      await txn.delete(tableTransactions);
      await txn.delete(tableItems);
      await txn.delete(tableMembers);
      await txn.delete(tableSettings);

      // Import members first (referenced by transactions)
      final members = data['members'] as List<dynamic>? ?? [];
      for (final member in members) {
        await txn.insert(
          tableMembers,
          Map<String, dynamic>.from(member as Map),
        );
      }

      // Import items (referenced by transactions)
      final items = data['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        await txn.insert(tableItems, Map<String, dynamic>.from(item as Map));
      }

      // Import transactions
      final transactions = data['transactions'] as List<dynamic>? ?? [];
      for (final transaction in transactions) {
        await txn.insert(
          tableTransactions,
          Map<String, dynamic>.from(transaction as Map),
        );
      }

      // Import settings (excluding PIN-related for security)
      final settings = data['settings'] as List<dynamic>? ?? [];
      for (final setting in settings) {
        final key = (setting as Map)['key'] as String?;
        // Don't restore PIN settings from backup
        if (key != null && !key.startsWith('pin_')) {
          await txn.insert(
            tableSettings,
            Map<String, dynamic>.from(setting),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Resets the database (for testing).
  Future<void> resetDatabase() async {
    await close();
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await deleteDatabase(path);
    _database = null;
  }
}

/// Exception thrown when a database operation fails.
class DatabaseException implements Exception {
  const DatabaseException(this.message);

  final String message;

  @override
  String toString() => 'DatabaseException: $message';
}
