// lib/core/database/database_bootstrap.dart
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

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

    // Web: use the ffi web factory (stores data in IndexedDB)
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      _initialized = true;
      return;
    }

    // Desktop platforms: use sqlite ffi implementation
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // For mobile platforms (iOS, Android), no change required (uses default sqflite factory).
    _initialized = true;
  }
}
