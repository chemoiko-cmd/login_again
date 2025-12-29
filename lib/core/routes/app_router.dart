// ============================================================================
// FILE: lib/core/routes/app_router.dart
// PURPOSE: Centralized app navigation using GoRouter.
// - Listens to AuthCubit state to protect routes and redirect after login.
// - Performs role-based redirection using the `User` domain helpers.
// - NO UI side-effects inside redirect (important).
// ============================================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/property_management_page.dart';
import '../../features/tenant/presentation/pages/tenant_dashboard_page.dart';

class AppRouter {
  final AuthCubit authCubit;

  AppRouter(this.authCubit);

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),

    redirect: (context, state) {
      final authState = authCubit.state;
      final location = state.matchedLocation;
      final isLoginRoute = location == '/login';

      // ───────── AUTHENTICATED ─────────
      if (authState is Authenticated && isLoginRoute) {
        final isTenant = authState.isTenant;
        final isLandlord = authState.isLandlord;

        if (isTenant) {
          return '/tenant-dashboard';
        }
        if (isLandlord) {
          return '/property-management';
        }

        // Unknown role → safe fallback
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          const SnackBar(content: Text('Unknown role. Logging out.')),
        );
        authCubit.logout();
        return '/login';
      }

      // ───────── UNAUTHENTICATED ─────────
      if (authState is! Authenticated && !isLoginRoute) {
        return '/login';
      }

      return null;
    },

    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/property-management',
        builder: (context, state) => const PropertyManagementPage(),
      ),
      GoRoute(
        path: '/tenant-dashboard',
        builder: (context, state) => const TenantDashboardPage(),
      ),
    ],
  );
}

/// Bridges a Bloc/Cubit stream with GoRouter's `refreshListenable`
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
