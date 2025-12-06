import 'package:flutter/material.dart';

import 'app.dart';
import 'core/database/database_bootstrap.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  // Initialize DB factory and Flutter bindings
  await DatabaseBootstrap.init();

  // Initialize dependency injection
  await configureDependencies();

  // Now it's safe to run the app and perform DB operations from repos/blocs.
  runApp(const LaundryLoggerApp());
}
