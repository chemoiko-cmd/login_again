import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../styles/colors.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';

class AppSideDrawer extends StatelessWidget {
  const AppSideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouter.of(context).state.uri.path; // FIXED
    final authState = context.watch<AuthCubit>().state;
    final bool isAuthenticated = authState is Authenticated;
    final bool isTenant = authState is Authenticated && authState.isTenant;
    final bool isLandlord = authState is Authenticated && authState.isLandlord;
    return Drawer(
      backgroundColor: AppColors.backgroundLight,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.backgroundLight,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                children: [
                  if (isAuthenticated) ...[
                    // Dashboard item switches destination based on role
                    ListTile(
                      leading: const Icon(
                        Icons.dashboard_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text('Dashboard'),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (isLandlord) {
                          context.go('/landlord-dashboard');
                        } else if (isTenant) {
                          context.go('/tenant-dashboard');
                        }
                      },
                      selected:
                          location == '/tenant-dashboard' ||
                          location == '/landlord-dashboard',
                      selectedTileColor: AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                    ),

                    // Tenant-only items
                    if (isTenant) ...[
                      ListTile(
                        leading: const Icon(
                          Icons.credit_card,
                          color: AppColors.textSecondary,
                        ),
                        title: const Text('Pay Rent'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/pay-rent');
                        },
                        selected: location == '/pay-rent',
                        selectedTileColor: AppColors.primary.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ],

                    // Landlord-only items
                    if (isLandlord) ...[
                      ListTile(
                        leading: const Icon(
                          Icons.description_outlined,
                          color: AppColors.textSecondary,
                        ),
                        title: const Text('Inspections'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/inspections');
                        },
                        selected: location == '/inspections',
                        selectedTileColor: AppColors.primary.withValues(
                          alpha: 0.08,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.people_outline,
                          color: AppColors.textSecondary,
                        ),
                        title: const Text('Tenants'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/landlord-tenants');
                        },
                        selected: location == '/landlord-tenants',
                        selectedTileColor: AppColors.primary.withValues(
                          alpha: 0.08,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.build_outlined,
                          color: AppColors.textSecondary,
                        ),
                        title: const Text('Maintenance Tasks'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/landlord-maintenance');
                        },
                        selected: location == '/landlord-maintenance',
                        selectedTileColor: AppColors.primary.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ],
                  ],
                  ListTile(
                    leading: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textSecondary,
                    ),
                    title: const Text('Notices'),
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  // ListTile(
                  //   leading: const Icon(
                  //     Icons.notifications_outlined,
                  //     color: AppColors.textSecondary,
                  //   ),
                  //   title: const Text('Maintenance2'),
                  //   onTap: () {
                  //     Navigator.of(context).pop();
                  //     context.go('/maintenance2');
                  //   },
                  // ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.border),
            if (isAuthenticated)
              ListTile(
                leading: const Icon(
                  Icons.power_settings_new,
                  color: AppColors.error,
                ),
                title: const Text('Sign Out'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await context.read<AuthCubit>().logout();
                },
              ),
          ],
        ),
      ),
    );
  }
}
