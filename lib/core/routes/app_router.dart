// ============================================================================
// FILE: lib/core/routes/app_router.dart
// PURPOSE: Centralized app navigation using GoRouter.
// - Listens to AuthCubit state to protect routes and redirect after login.
// - Performs role-based redirection using the `User` domain helpers.
// - NO UI side-effects inside redirect (important).
// ============================================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:login_again/features/payments/presentation/pages/payments_page.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/property_management_page.dart';
import '../../features/tenant/presentation/pages/tenant_dashboard_page.dart';
import '../../features/maintenance/presentation/pages/maintenance_page.dart';
import '../../features/contracts/presentation/pages/contract_details_page.dart';
import '../../core/widgets/app_side_drawer.dart'; // Make sure this exists

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
        if (authState.isTenant) return '/tenant-dashboard';
        if (authState.isLandlord) return '/property-management';

        // Unknown role → safe fallback
        authCubit.logout();
        return '/login';
      }

      // ───────── UNAUTHENTICATED ─────────
      if (authState is! Authenticated && !isLoginRoute) return '/login';

      return null;
    },

    routes: [
      // Global drawer shell
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            appBar: AppBar(),
            drawer: const AppSideDrawer(),
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/property-management',
            builder: (context, state) => const PropertyManagementPage(),
          ),
          GoRoute(
            path: '/tenant-dashboard',
            builder: (context, state) => const TenantDashboardPage(),
          ),
          GoRoute(
            path: '/maintenance',
            builder: (context, state) => const MaintenancePage(),
          ),
          GoRoute(
            path: '/pay-rent',
            builder: (context, state) => const PaymentsPage(),
          ),
          GoRoute(
            path: '/contracts',
            builder: (context, state) => const ContractPage(),
          ),
        ],
      ),

      // Login route outside the shell (no drawer)
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
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
