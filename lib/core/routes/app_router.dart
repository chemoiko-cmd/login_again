// ============================================================================
// FILE: lib/core/routes/app_router.dart
// PURPOSE: Centralized app navigation using GoRouter.
// - Listens to AuthCubit state to protect routes and redirect after login.
// - Performs role-based redirection using the `User` domain helpers.
// - NO UI side-effects inside redirect (important).
// ============================================================================
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:login_again/core/widgets/glass_background.dart';
import 'package:login_again/features/landlord/presentation/landlord_maintenance_screen.dart';
import 'package:login_again/features/landlord/presentation/inspection_screen.dart';
import 'package:login_again/features/landlord/presentation/landlord_tenant_profile_screen.dart';
import 'package:login_again/features/landlord/presentation/landlord_tenants_screen.dart';
import 'package:login_again/features/landlord/presentation/landlord_properties_screen.dart';
import 'package:login_again/features/maintainer/presentation/maintainer_tasks_screen.dart';
import 'package:login_again/features/maintainer/presentation/maintainer_inspections_screen.dart';
import 'package:login_again/features/maintainer/presentation/maintainer_dashboard_screen.dart';
import 'package:login_again/features/payments/presentation/pages/payments_page.dart';
import 'package:login_again/features/profile/presentation/my_profile_screen.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/landlord/presentation/landlord_dashboard_screen.dart';
import '../../features/tenant/presentation/pages/tenant_dashboard_page.dart';
import '../../features/maintenance/presentation/pages/maintenance_page.dart';
import '../../features/contracts/presentation/pages/contract_details_page.dart';
import '../../core/widgets/app_side_drawer.dart'; // Make sure this exists
import '../../features/maintenance2/presentation/maintenance_screen.dart';
import 'package:login_again/screens/privacy_policy_screen.dart';

String _shellTitleForLocation(BuildContext context, String location) {
  final authState = context.read<AuthCubit>().state;
  final userName = authState is Authenticated ? authState.user.name : 'User';

  switch (location) {
    case '/tenant-dashboard':
      return 'Hello $userName';
    case '/landlord-dashboard':
      return 'Hello $userName';
    case '/maintainer-dashboard':
      return 'Hello $userName';
    case '/landlord-properties':
      return 'Properties';
    case '/landlord-tenants':
      return 'Tenants';
    case '/landlord-maintenance':
      return 'Maintenance';
    case '/inspections':
      return 'Inspections';
    case '/pay-rent':
      return 'Payments';
    case '/contracts':
      return 'Contracts';
    case '/profile':
      return 'My Profile';
    case '/maintainer-tasks':
      return 'Tasks';
    case '/maintainer-inspections':
      return 'Inspections';
    default:
      return 'Odoo Property Management';
  }
}

class AppRouter {
  final AuthCubit authCubit;

  AppRouter(this.authCubit);

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),

    redirect: (context, state) {
      final authState = authCubit.state;
      final location = state.matchedLocation;
      final isLoginRoute = location == '/login';
      final isSplashRoute = location == '/splash';

      // While checking/restoring session, always remain on splash.
      if (authState is AuthInitial || authState is AuthChecking) {
        return isSplashRoute ? null : '/splash';
      }

      // ───────── AUTHENTICATED ─────────
      if (authState is Authenticated && (isLoginRoute || isSplashRoute)) {
        if (authState.isTenant) return '/tenant-dashboard';
        if (authState.isLandlord) return '/landlord-dashboard';
        if (authState.isMaintenance) return '/maintainer-dashboard';

        // Unknown role → safe fallback
        authCubit.logout();
        return '/login';
      }

      // ───────── UNAUTHENTICATED ─────────
      if (authState is Unauthenticated && (isSplashRoute)) {
        return '/login';
      }

      if (authState is! Authenticated && !(isLoginRoute || isSplashRoute)) {
        return '/login';
      }

      return null;
    },

    routes: [
      // Splash route (no drawer)
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),

      // Global drawer shell
      ShellRoute(
        builder: (context, state, child) {
          final title = _shellTitleForLocation(context, state.matchedLocation);
          return Stack(
            children: [
              const Positioned.fill(
                child: GlassBackground(child: SizedBox.expand()),
              ),
              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(title),
                  toolbarHeight: 72,
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(8),
                    child: SizedBox(height: 8),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                ),
                drawer: const AppSideDrawer(),
                body: child,
              ),
            ],
          );
        },
        routes: [
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
          GoRoute(
            path: '/maintenance2',
            builder: (context, state) => const MaintenanceScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const MyProfileScreen(),
          ),
          GoRoute(
            path: '/landlord-dashboard',
            builder: (context, state) => const LandlordDashboardScreen(),
          ),
          GoRoute(
            path: '/landlord-properties',
            builder: (context, state) => const LandlordPropertiesScreen(),
          ),
          GoRoute(
            path: '/inspections',
            builder: (context, state) => const InspectionScreen(),
          ),

          GoRoute(
            path: '/landlord-maintenance',
            builder: (context, state) => const LandlordMaintenanceScreen(),
          ),

          GoRoute(
            path: '/landlord-tenants',
            builder: (context, state) => const LandlordTenantsScreen(),
          ),

          GoRoute(
            path: '/landlord-tenants/:tenantPartnerId',
            builder: (context, state) {
              final idStr = state.pathParameters['tenantPartnerId'] ?? '0';
              final tenantPartnerId = int.tryParse(idStr) ?? 0;
              final extra = state.extra;
              final m = extra is Map ? extra.cast<String, dynamic>() : const {};

              return LandlordTenantProfileScreen(
                tenantPartnerId: tenantPartnerId,
                tenantName: (m['tenantName'] ?? '').toString(),
                propertyName: (m['propertyName'] ?? '').toString(),
                unitName: (m['unitName'] ?? '').toString(),
                status: (m['status'] as String?),
              );
            },
          ),
          GoRoute(
            path: '/privacy-policy',
            builder: (context, state) => const PrivacyPolicyScreen(),
          ),

          // Maintainer routes
          GoRoute(
            path: '/maintainer-dashboard',
            builder: (context, state) => const MaintainerDashboardScreen(),
          ),
          GoRoute(
            path: '/maintainer-tasks',
            builder: (context, state) => const MaintainerTasksScreen(),
          ),
          GoRoute(
            path: '/maintainer-inspections',
            builder: (context, state) => const MaintainerInspectionsScreen(),
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

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
