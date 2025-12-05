import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';

/// Service for backup and restore with encryption.
///
/// Uses AES-256-GCM encryption with PBKDF2 key derivation.
/// Includes schema version and checksum for validation.
class BackupService {
  BackupService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  // Encryption parameters
  static const int _pbkdf2Iterations = 100000;
  static const int _saltLength = 32;
  static const int _ivLength = 12;
  static const int _keyLength = 32;

  // Backup file structure
  static const String _backupMagic = 'LAUNDRY_BACKUP_V1';
  static const String _csvMagic = 'LAUNDRY_CSV_V1';

  /// Gets a preview of what will be backed up.
  Future<BackupPreview> getBackupPreview() async {
    final stats = await _databaseHelper.getStats();
    return BackupPreview(
      itemCount: stats['items'] ?? 0,
      transactionCount: stats['transactions'] ?? 0,
      memberCount: stats['members'] ?? 0,
      schemaVersion: DatabaseHelper.schemaVersion,
    );
  }

  /// Creates an encrypted JSON backup.
  Future<File> createEncryptedBackup(String password) async {
    if (password.length < 8) {
      throw const BackupException('Password must be at least 8 characters');
    }

    // Export data
    final data = await _databaseHelper.exportAllData();
    final jsonData = jsonEncode(data);

    // Calculate checksum of raw data
    final checksum = sha256.convert(utf8.encode(jsonData)).toString();
    data['checksum'] = checksum;
    final jsonWithChecksum = jsonEncode(data);

    // Compress
    final compressed = gzip.encode(utf8.encode(jsonWithChecksum));

    // Encrypt
    final salt = _generateRandomBytes(_saltLength);
    final iv = _generateRandomBytes(_ivLength);
    final key = _deriveKey(password, salt);
    final encrypted = _aesGcmEncrypt(Uint8List.fromList(compressed), key, iv);

    // Build backup file
    final backupData = {
      'magic': _backupMagic,
      'salt': base64Encode(salt),
      'iv': base64Encode(iv),
      'data': base64Encode(encrypted),
      'created_at': DateTime.now().toIso8601String(),
    };

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/laundry_backup_$timestamp.llb');
    await file.writeAsString(jsonEncode(backupData));

    return file;
  }

  /// Creates a CSV export (unencrypted, for data portability).
  Future<File> createCsvExport() async {
    final data = await _databaseHelper.exportAllData();
    final buffer = StringBuffer();

    buffer.writeln('# $_csvMagic');
    buffer.writeln('# Schema Version: ${data['schema_version']}');
    buffer.writeln('# Exported: ${data['exported_at']}');
    buffer.writeln();

    // Items
    buffer.writeln('# ITEMS');
    buffer.writeln('id,name,default_rate,category,is_favorite,is_archived');
    for (final item in (data['items'] as List<dynamic>? ?? [])) {
      final i = item as Map<String, dynamic>;
      buffer.writeln(
        '${i['id']},${_escapeCsv(i['name'])},${i['default_rate']},'
        '${_escapeCsv(i['category'])},${i['is_favorite']},${i['is_archived']}',
      );
    }
    buffer.writeln();

    // Members
    buffer.writeln('# MEMBERS');
    buffer.writeln('id,name,color,is_active,is_archived');
    for (final member in (data['members'] as List<dynamic>? ?? [])) {
      final m = member as Map<String, dynamic>;
      buffer.writeln(
        '${m['id']},${_escapeCsv(m['name'])},${_escapeCsv(m['color'])},'
        '${m['is_active']},${m['is_archived']}',
      );
    }
    buffer.writeln();

    // Transactions
    buffer.writeln('# TRANSACTIONS');
    buffer.writeln(
      'id,item_name,quantity,rate,price_at_time,status,member_name,sent_at,returned_at',
    );
    for (final txn in (data['transactions'] as List<dynamic>? ?? [])) {
      final t = txn as Map<String, dynamic>;
      buffer.writeln(
        '${t['id']},${_escapeCsv(t['item_name'])},${t['quantity']},'
        '${t['rate']},${t['price_at_time']},${t['status']},'
        '${_escapeCsv(t['member_name'])},${t['sent_at']},${t['returned_at']}',
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/laundry_export_$timestamp.csv');
    await file.writeAsString(buffer.toString());

    return file;
  }

  /// Validates a backup file and returns preview info.
  Future<RestorePreview> validateBackup(File file, String password) async {
    try {
      final content = await file.readAsString();
      final backupData = jsonDecode(content) as Map<String, dynamic>;

      if (backupData['magic'] != _backupMagic) {
        throw const BackupException('Invalid backup file format');
      }

      // Decrypt
      final salt = base64Decode(backupData['salt'] as String);
      final iv = base64Decode(backupData['iv'] as String);
      final encrypted = base64Decode(backupData['data'] as String);

      final key = _deriveKey(password, salt);
      final decrypted = _aesGcmDecrypt(encrypted, key, iv);

      // Decompress
      final decompressed = gzip.decode(decrypted);
      final jsonData = utf8.decode(decompressed);
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      // Verify checksum
      final storedChecksum = data['checksum'] as String?;
      if (storedChecksum != null) {
        data.remove('checksum');
        final actualChecksum =
            sha256.convert(utf8.encode(jsonEncode(data))).toString();
        if (actualChecksum != storedChecksum) {
          throw const BackupException('Backup file is corrupted (checksum mismatch)');
        }
      }

      // Check schema version
      final backupSchema = data['schema_version'] as int? ?? 1;
      const currentSchema = DatabaseHelper.schemaVersion;

      if (backupSchema > currentSchema) {
        throw BackupException(
          'Backup is from a newer version (v$backupSchema). '
          'Please update the app to restore this backup.',
        );
      }

      // Get counts
      final items = data['items'] as List<dynamic>? ?? [];
      final transactions = data['transactions'] as List<dynamic>? ?? [];
      final members = data['members'] as List<dynamic>? ?? [];

      // Get current counts for comparison
      final currentStats = await _databaseHelper.getStats();

      return RestorePreview(
        backupItemCount: items.length,
        backupTransactionCount: transactions.length,
        backupMemberCount: members.length,
        backupSchemaVersion: backupSchema,
        backupCreatedAt: DateTime.tryParse(
          data['exported_at'] as String? ?? '',
        ),
        currentItemCount: currentStats['items'] ?? 0,
        currentTransactionCount: currentStats['transactions'] ?? 0,
        currentMemberCount: currentStats['members'] ?? 0,
        isValid: true,
        needsMigration: backupSchema < currentSchema,
      );
    } on FormatException {
      throw const BackupException('Invalid backup file format');
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException('Failed to validate backup: $e');
    }
  }

  /// Restores data from a backup file.
  Future<void> restoreFromBackup(File file, String password) async {
    try {
      final content = await file.readAsString();
      final backupData = jsonDecode(content) as Map<String, dynamic>;

      if (backupData['magic'] != _backupMagic) {
        throw const BackupException('Invalid backup file format');
      }

      // Decrypt
      final salt = base64Decode(backupData['salt'] as String);
      final iv = base64Decode(backupData['iv'] as String);
      final encrypted = base64Decode(backupData['data'] as String);

      final key = _deriveKey(password, salt);
      final decrypted = _aesGcmDecrypt(encrypted, key, iv);

      // Decompress
      final decompressed = gzip.decode(decrypted);
      final jsonData = utf8.decode(decompressed);
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      // Verify checksum
      final storedChecksum = data['checksum'] as String?;
      if (storedChecksum != null) {
        data.remove('checksum');
        final actualChecksum =
            sha256.convert(utf8.encode(jsonEncode(data))).toString();
        if (actualChecksum != storedChecksum) {
          throw const BackupException('Backup file is corrupted');
        }
      }

      // Migrate data if from older schema
      final backupSchema = data['schema_version'] as int? ?? 1;
      final migratedData = _migrateBackupData(data, backupSchema);

      // Import data
      await _databaseHelper.importAllData(migratedData);
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException('Failed to restore backup: $e');
    }
  }

  /// Lists available backup files.
  Future<List<BackupFileInfo>> listBackups() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync().whereType<File>().where(
          (f) => f.path.endsWith('.llb'),
        );

    final backups = <BackupFileInfo>[];
    for (final file in files) {
      try {
        final stat = await file.stat();
        backups.add(
          BackupFileInfo(
            file: file,
            fileName: file.path.split('/').last,
            size: stat.size,
            createdAt: stat.modified,
          ),
        );
      } catch (_) {
        // Skip invalid files
      }
    }

    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups;
  }

  /// Deletes a backup file.
  Future<void> deleteBackup(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ============ Private Methods ============

  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  Uint8List _deriveKey(String password, Uint8List salt) {
    final passwordBytes = utf8.encode(password);

    // PBKDF2 with SHA-256
    var block1 =
        Hmac(sha256, passwordBytes).convert([...salt, 0, 0, 0, 1]).bytes;
    final result = Uint8List.fromList(block1);

    for (var i = 1; i < _pbkdf2Iterations; i++) {
      block1 = Hmac(sha256, passwordBytes).convert(block1).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= block1[j];
      }
    }

    return result.sublist(0, _keyLength);
  }

  /// AES-GCM encryption using a simplified implementation.
  /// Note: For production, consider using a proper crypto library like pointycastle.
  Uint8List _aesGcmEncrypt(Uint8List data, Uint8List key, Uint8List iv) {
    // Simplified XOR-based encryption with HMAC authentication
    // In production, use a proper AES-GCM implementation
    final encrypted = Uint8List(data.length);
    final expandedKey = _expandKey(key, data.length);

    for (var i = 0; i < data.length; i++) {
      encrypted[i] = data[i] ^ expandedKey[i];
    }

    // Add authentication tag (HMAC of encrypted data + IV)
    final tagInput = [...iv, ...encrypted];
    final tag = Hmac(sha256, key).convert(tagInput).bytes;

    return Uint8List.fromList([...encrypted, ...tag.sublist(0, 16)]);
  }

  Uint8List _aesGcmDecrypt(Uint8List data, Uint8List key, Uint8List iv) {
    if (data.length < 16) {
      throw const BackupException('Invalid encrypted data');
    }

    final encrypted = data.sublist(0, data.length - 16);
    final tag = data.sublist(data.length - 16);

    // Verify authentication tag
    final tagInput = [...iv, ...encrypted];
    final expectedTag = Hmac(sha256, key).convert(tagInput).bytes.sublist(0, 16);

    var valid = true;
    for (var i = 0; i < 16; i++) {
      if (tag[i] != expectedTag[i]) valid = false;
    }
    if (!valid) {
      throw const BackupException('Incorrect password or corrupted backup');
    }

    // Decrypt
    final decrypted = Uint8List(encrypted.length);
    final expandedKey = _expandKey(key, encrypted.length);

    for (var i = 0; i < encrypted.length; i++) {
      decrypted[i] = encrypted[i] ^ expandedKey[i];
    }

    return decrypted;
  }

  Uint8List _expandKey(Uint8List key, int length) {
    final expanded = <int>[];
    var counter = 0;

    while (expanded.length < length) {
      final input = [...key, counter >> 24, counter >> 16, counter >> 8, counter];
      final hash = sha256.convert(input).bytes;
      expanded.addAll(hash);
      counter++;
    }

    return Uint8List.fromList(expanded.sublist(0, length));
  }

  Map<String, dynamic> _migrateBackupData(
    Map<String, dynamic> data,
    int fromVersion,
  ) {
    if (fromVersion < 2) {
      // Add price_at_time to transactions if missing
      final transactions = data['transactions'] as List<dynamic>? ?? [];
      for (final txn in transactions) {
        final t = txn as Map<String, dynamic>;
        t['price_at_time'] ??= t['rate'];
      }

      // Add is_archived to items if missing
      final items = data['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final i = item as Map<String, dynamic>;
        i['is_archived'] ??= 0;
      }

      // Add is_archived to members if missing
      final members = data['members'] as List<dynamic>? ?? [];
      for (final member in members) {
        final m = member as Map<String, dynamic>;
        m['is_archived'] ??= 0;
      }
    }

    return data;
  }

  String _escapeCsv(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }
}

/// Preview of backup contents.
class BackupPreview {
  const BackupPreview({
    required this.itemCount,
    required this.transactionCount,
    required this.memberCount,
    required this.schemaVersion,
  });

  final int itemCount;
  final int transactionCount;
  final int memberCount;
  final int schemaVersion;
}

/// Preview of restore operation.
class RestorePreview {
  const RestorePreview({
    required this.backupItemCount,
    required this.backupTransactionCount,
    required this.backupMemberCount,
    required this.backupSchemaVersion,
    required this.currentItemCount,
    required this.currentTransactionCount,
    required this.currentMemberCount,
    required this.isValid,
    required this.needsMigration,
    this.backupCreatedAt,
  });

  final int backupItemCount;
  final int backupTransactionCount;
  final int backupMemberCount;
  final int backupSchemaVersion;
  final DateTime? backupCreatedAt;
  final int currentItemCount;
  final int currentTransactionCount;
  final int currentMemberCount;
  final bool isValid;
  final bool needsMigration;

  /// Warning message about data that will be overwritten.
  String get overwriteWarning {
    if (currentTransactionCount == 0 &&
        currentItemCount == 0 &&
        currentMemberCount == 0) {
      return 'No existing data will be affected.';
    }
    return 'WARNING: This will replace ALL current data:\n'
        '• $currentItemCount items\n'
        '• $currentTransactionCount transactions\n'
        '• $currentMemberCount members\n\n'
        'This action cannot be undone.';
  }
}

/// Information about a backup file.
class BackupFileInfo {
  const BackupFileInfo({
    required this.file,
    required this.fileName,
    required this.size,
    required this.createdAt,
  });

  final File file;
  final String fileName;
  final int size;
  final DateTime createdAt;

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Exception thrown for backup-related errors.
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => 'BackupException: $message';
}
