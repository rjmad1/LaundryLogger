import 'package:flutter/material.dart';
import 'package:laundry_logger/app.dart';
import 'package:laundry_logger/core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await configureDependencies();
  
  runApp(const LaundryLoggerApp());
}
