import 'package:get_it/get_it.dart';

import '../../features/household/data/repositories/household_member_repository_impl.dart';
import '../../features/household/domain/repositories/household_member_repository.dart';
import '../../features/household/presentation/bloc/household_bloc.dart';
import '../../features/items/data/repositories/item_repository_impl.dart';
import '../../features/items/domain/repositories/item_repository.dart';
import '../../features/items/presentation/bloc/item_bloc.dart';
import '../../features/journal/data/repositories/transaction_repository_impl.dart';
import '../../features/journal/domain/repositories/transaction_repository.dart';
import '../../features/journal/presentation/bloc/journal_bloc.dart';
import '../backup/backup_service.dart';
import '../database/database_helper.dart';
import '../security/security_service.dart';

/// Global service locator instance.
final getIt = GetIt.instance;

/// Configure all dependencies.
Future<void> configureDependencies() async {
  // Database
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);

  // Core Services
  getIt.registerLazySingleton<SecurityService>(SecurityService.new);
  getIt.registerLazySingleton<BackupService>(
    () => BackupService(databaseHelper: getIt()),
  );

  // Repositories
  getIt.registerLazySingleton<ItemRepository>(
    () => ItemRepositoryImpl(databaseHelper: getIt()),
  );
  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(databaseHelper: getIt()),
  );
  getIt.registerLazySingleton<HouseholdMemberRepository>(
    () => HouseholdMemberRepositoryImpl(databaseHelper: getIt()),
  );

  // BLoCs
  getIt.registerFactory<ItemBloc>(
    () => ItemBloc(itemRepository: getIt()),
  );
  getIt.registerFactory<JournalBloc>(
    () => JournalBloc(transactionRepository: getIt()),
  );
  getIt.registerFactory<HouseholdBloc>(
    () => HouseholdBloc(memberRepository: getIt()),
  );
}
