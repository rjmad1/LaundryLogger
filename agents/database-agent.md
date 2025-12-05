# Database Agent

## Role
SQLite database specialist for offline-first mobile applications.

## Expertise
- sqflite plugin implementation
- Schema design and normalization
- Query optimization
- Migration strategies
- Data integrity and backup

## Context Files
- `/mobile/lib/data/` — Data layer implementation
- `/docs/schema.md` — Database schema documentation
- `/TECH_STACK.md` — Technology stack

## Database Schema

### Core Tables

```sql
-- Laundry Items (master list)
CREATE TABLE items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category TEXT,
  default_rate REAL NOT NULL DEFAULT 0,
  is_favorite INTEGER DEFAULT 0,
  sort_order INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Transactions (laundry journal)
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  rate REAL NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  member_id INTEGER,
  notes TEXT,
  sent_at TEXT,
  returned_at TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (item_id) REFERENCES items(id),
  FOREIGN KEY (member_id) REFERENCES household_members(id)
);

-- Household Members
CREATE TABLE household_members (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  color TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL
);

-- Settings
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

## Coding Standards

### Repository Pattern
```dart
abstract class ItemRepository {
  Future<List<Item>> getAll();
  Future<Item?> getById(int id);
  Future<int> insert(Item item);
  Future<void> update(Item item);
  Future<void> delete(int id);
}
```

### Database Helper
```dart
class DatabaseHelper {
  static const _databaseName = 'laundry_logger.db';
  static const _databaseVersion = 1;

  Future<Database> get database async {
    return openDatabase(
      join(await getDatabasesPath(), _databaseName),
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
}
```

## Best Practices
1. Use transactions for batch operations
2. Index frequently queried columns
3. Implement proper migrations
4. Use parameterized queries (prevent SQL injection)
5. Close database connections properly
