import 'package:get_it/get_it.dart';

/// Global service locator instance.
final getIt = GetIt.instance;

/// Configure all dependencies.
Future<void> configureDependencies() async {
  // TODO: Register dependencies
  // Example:
  // getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  // getIt.registerLazySingleton<ItemRepository>(() => ItemRepositoryImpl(getIt()));
}
