import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laundry_logger/core/router/app_router.dart';
import 'package:laundry_logger/core/theme/app_theme.dart';

/// The root widget of the Laundry Logger application.
class LaundryLoggerApp extends StatelessWidget {
  /// Creates the Laundry Logger app.
  const LaundryLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Laundry Logger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
