import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/database/enums.dart';
import '../core/providers.dart';
import '../features/accounts/presentation/account_detail_screen.dart';
import '../features/accounts/presentation/account_form_screen.dart';
import '../features/backup/presentation/backup_screen.dart';
import '../features/backup/presentation/restore_screen.dart';
import '../features/home/home_screen.dart';
import '../features/money/money_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/planner/planner_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/security/pin_setup_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/transactions/presentation/categories_screen.dart';
import '../features/transactions/presentation/recurring_screen.dart';
import '../features/transactions/presentation/transaction_detail_screen.dart';
import '../features/transactions/presentation/transaction_form_screen.dart';
import '../features/updates/presentation/update_screen.dart';
import 'app_shell.dart';
import 'extra_routes.dart';
import 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Re-evaluates redirects when onboarding completes or is replayed.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(
      preferencesProvider.select((p) => p.onboardingComplete),
      (_, _) => notifyListeners(),
    );
  }
}

GoRoute _page(String path, Widget Function(GoRouterState state) builder) =>
    GoRoute(
      path: path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => builder(state),
    );

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final done = ref.read(preferencesProvider).onboardingComplete;
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      // A backup can be restored instead of going through the guide.
      if (!done && state.matchedLocation == Routes.restore) return null;
      if (!done && !atOnboarding) return Routes.onboarding;
      if (done && atOnboarding) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.money,
                builder: (context, state) =>
                    MoneyScreen(initialTab: state.uri.queryParameters['tab']),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.planner,
                builder: (context, state) =>
                    PlannerScreen(initialTab: state.uri.queryParameters['tab']),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.reports,
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Transactions
      _page('/transactions/new', (s) {
        final q = s.uri.queryParameters;
        return TransactionFormScreen(
          initialType:
              TransactionType.values
                  .where((t) => t.name == q['type'])
                  .firstOrNull ??
              TransactionType.expense,
          initialAccountId: q['account'],
          duplicateOf: q['duplicate'],
        );
      }),
      _page(
        '/transactions/:id',
        (s) => TransactionDetailScreen(id: s.pathParameters['id']!),
      ),
      _page(
        '/transactions/:id/edit',
        (s) => TransactionFormScreen(editId: s.pathParameters['id']),
      ),
      _page(Routes.categories, (_) => const CategoriesScreen()),
      _page(Routes.recurring, (_) => const RecurringScreen()),
      // Accounts
      _page(Routes.newAccount, (_) => const AccountFormScreen()),
      _page(
        '/accounts/:id',
        (s) => AccountDetailScreen(accountId: s.pathParameters['id']!),
      ),
      _page(
        '/accounts/:id/edit',
        (s) => AccountFormScreen(accountId: s.pathParameters['id']),
      ),
      _page(Routes.privacy, (_) => const PrivacyScreen()),
      _page(Routes.backup, (_) => const BackupScreen()),
      _page(Routes.restore, (_) => const RestoreScreen()),
      _page(Routes.updates, (_) => const UpdateScreen()),
      _page(
        '/settings/pin',
        (s) => PinSetupScreen(
          mode:
              PinSetupMode.values
                  .where((m) => m.name == s.uri.queryParameters['mode'])
                  .firstOrNull ??
              PinSetupMode.create,
        ),
      ),
      ...extraRoutes(_page),
    ],
  );
});
