// ============================================================================
// FILE: lib/core/routes/app_router.dart
// PURPOSE: Centralized app navigation using GoRouter.
// - Listens to AuthCubit state to protect routes and redirect after login.
// - Performs role-based redirection using the `User` domain helpers.
// - NO UI side-effects inside redirect (important).
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:login_again/features/landlord/data/repositories/landlord_repository.dart';
import 'package:login_again/features/landlord/presentation/cubit/inspections_cubit.dart';
import 'package:login_again/features/landlord/presentation/cubit/maintenance_tasks_cubit.dart';
import 'package:login_again/features/landlord/presentation/cubit/tenants_cubit.dart';
import 'package:login_again/features/landlord/presentation/landlord_maintenance_screen.dart';
import 'package:login_again/features/landlord/presentation/inspection_screen.dart';
import 'package:login_again/features/landlord/presentation/landlord_tenant_profile_screen.dart';
import 'package:login_again/features/landlord/presentation/landlord_tenants_screen.dart';
import 'package:login_again/features/payments/presentation/pages/payments_page.dart';
import 'package:login_again/features/profile/presentation/my_profile_screen.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/landlord/presentation/landlord_dashboard_screen.dart';
import '../../features/tenant/presentation/pages/tenant_dashboard_page.dart';
import '../../features/maintenance/presentation/pages/maintenance_page.dart';
import '../../features/contracts/presentation/pages/contract_details_page.dart';
import '../../core/widgets/app_side_drawer.dart'; // Make sure this exists
import '../../features/maintenance2/presentation/maintenance_screen.dart';

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
        if (authState.isLandlord) return '/landlord-dashboard';

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
            path: '/inspections',
            builder: (context, state) {
              final auth = context.read<AuthCubit>();

              return BlocProvider(
                create: (_) {
                  final cubit = InspectionsCubit(
                    LandlordRepository(apiClient: auth.apiClient),
                  );

                  final authState = auth.state;
                  if (authState is Authenticated) {
                    cubit.load(partnerId: authState.user.partnerId);
                  }

                  return cubit;
                },
                child: const InspectionScreen(),
              );
            },
          ),

          GoRoute(
            path: '/landlord-maintenance',
            builder: (context, state) {
              final auth = context.read<AuthCubit>();

              return BlocProvider(
                create: (_) {
                  final cubit = MaintenanceTasksCubit(
                    LandlordRepository(apiClient: auth.apiClient),
                  );

                  final authState = auth.state;
                  if (authState is Authenticated) {
                    cubit.load(partnerId: authState.user.partnerId);
                  }

                  return cubit;
                },
                child: const LandlordMaintenanceScreen(),
              );
            },
          ),

          GoRoute(
            path: '/landlord-tenants',
            builder: (context, state) {
              final auth = context.read<AuthCubit>();

              return BlocProvider(
                create: (_) {
                  final cubit = TenantsCubit(
                    LandlordRepository(apiClient: auth.apiClient),
                  );

                  final authState = auth.state;
                  if (authState is Authenticated) {
                    cubit.load(partnerId: authState.user.partnerId);
                  }

                  return cubit;
                },
                child: const LandlordTenantsScreen(),
              );
            },
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
