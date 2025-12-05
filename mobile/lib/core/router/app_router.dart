import 'package:go_router/go_router.dart';
import 'package:laundry_logger/features/home/presentation/pages/home_page.dart';
import 'package:laundry_logger/features/items/presentation/pages/items_page.dart';
import 'package:laundry_logger/features/journal/presentation/pages/journal_page.dart';
import 'package:laundry_logger/features/settings/presentation/pages/settings_page.dart';

/// Application router configuration.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/items',
      name: 'items',
      builder: (context, state) => const ItemsPage(),
    ),
    GoRoute(
      path: '/journal',
      name: 'journal',
      builder: (context, state) => const JournalPage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
