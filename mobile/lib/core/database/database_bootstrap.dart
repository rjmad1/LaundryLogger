// lib/core/database/database_bootstrap.dart
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// DatabaseBootstrap ensures sqflite is configured for the current platform.
/// Call `DatabaseBootstrap.init()` before any database operations.
class DatabaseBootstrap {
  static bool _initialized = false;

  /// Initialize platform-specific database factory for desktop platforms.
  /// Safe to call multiple times; initialization is idempotent.
  static Future<void> init() async {
    if (_initialized) return;

    // Ensure Flutter bindings so platform channels and file IO are safe.
    WidgetsFlutterBinding.ensureInitialized();

    // Desktop: use sqlite ffi implementation
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // For mobile platforms, no change required (uses default sqflite factory).
    _initialized = true;
  }
}
