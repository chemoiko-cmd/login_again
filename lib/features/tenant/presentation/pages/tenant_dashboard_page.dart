// =============================================================================
// FILE: lib/features/tenant/presentation/pages/tenant_dashboard_page.dart
// Adapted from bloc_nav_app TenantDashboard: uses this app's AuthCubit/apiClient
// to fetch Odoo data via JSON-RPC and renders a modern tenant dashboard.
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../styles/colors.dart';
import '../widgets/section.dart';
import '../cubit/tenant_dashboard_cubit.dart';
import '../cubit/tenant_dashboard_state.dart';
import '../../../../core/widgets/app_side_drawer.dart';

class TenantDashboardPage extends StatefulWidget {
  const TenantDashboardPage({super.key});

  @override
  State<TenantDashboardPage> createState() => _TenantDashboardPageState();
}

class _TenantDashboardPageState extends State<TenantDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<TenantDashboardCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      drawer: const AppSideDrawer(),
      body: BlocBuilder<TenantDashboardCubit, TenantDashboardState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(
              child: Text('Failed to load tenant data\n${state.error}'),
            );
          }
          final data = state.data ?? const {};
          final userName = (data['userName'] ?? '').toString();
          final unitName = (data['unitName'] ?? '').toString();
          final propertyName = (data['propertyName'] ?? '').toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName.isEmpty ? 'Tenant' : userName,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${unitName.isEmpty ? 'Your unit' : unitName} • ${propertyName.isEmpty ? 'Your property' : propertyName}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions grid
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _ActionCircle(
                        icon: Icons.build_outlined,
                        label: 'Maintenance Request',
                        onTap: () => context.go('/maintenance'),
                        color: Colors.orange,
                      ),
                      _ActionCircle(
                        icon: Icons.description_outlined,
                        label: 'Contract-info',
                        onTap: () => context.go('/contracts'),
                        color: Colors.teal,
                      ),
                      _ActionCircle(
                        icon: Icons.receipt_long,
                        label: 'Receipts',
                        onTap: () => context.go('/pay-rent'),
                        color: Colors.indigo,
                      ),
                      _ActionCircle(
                        icon: Icons.credit_card,
                        label: 'Pay Rent',
                        onTap: () => context.go('/pay-rent'),
                        color: AppColors.primary,
                      ),
                      _ActionCircle(
                        icon: Icons.announcement,
                        label: 'Announcements',
                        onTap: () {},
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Section(
                  title: 'Announcements',
                  children: [
                    Text(
                      'No announcements',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  trailing: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text('View All'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionCircle({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
