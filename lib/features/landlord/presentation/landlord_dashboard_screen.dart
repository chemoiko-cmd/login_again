import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:login_again/core/widgets/app_loading_indicator.dart';
import 'package:login_again/core/utils/formatters.dart';

import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';

import 'cubit/metrics_cubit.dart';
import 'cubit/metrics_state.dart';

import 'widgets/rent_card.dart';
import 'widgets/metric_card.dart';
import 'widgets/action_tile.dart';
import 'package:login_again/core/utils/formatters.dart';

class LandlordDashboardScreen extends StatefulWidget {
  const LandlordDashboardScreen({super.key});

  @override
  State<LandlordDashboardScreen> createState() =>
      _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends State<LandlordDashboardScreen> {
  @override
  void initState() {
    super.initState();

    final auth = context.read<AuthCubit>();
    final authState = auth.state;
    final partnerId = authState is Authenticated ? authState.user.partnerId : 0;

    if (partnerId > 0) {
      context.read<MetricsCubit>().load(partnerId: partnerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final auth = context.read<AuthCubit>();
    final authState = auth.state;
    final userName = authState is Authenticated ? authState.user.name : 'User';
    return BlocBuilder<MetricsCubit, MetricsState>(
      builder: (context, state) {
        if (state is MetricsLoading) {
          return const Center(child: AppLoadingIndicator());
        }

        if (state is MetricsError) {
          return Center(child: Text(state.message));
        }

        if (state is MetricsLoaded) {
          final metrics = state.metrics;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Welcome back,',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName.isEmpty ? 'Landlord' : capitalizeFirst(userName),
                  style: textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),

                RentCard(
                  totalCollected: metrics.totalRentCollected.toDouble(),
                  totalOverall: metrics.totalRentDue.toDouble(),
                ),

                const SizedBox(height: 24),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    MetricCard(
                      icon: Icons.apartment,
                      label: 'Occupancy',
                      value:
                          '${metrics.occupiedUnits}/${metrics.totalUnits} units',
                      iconColor: scheme.primary,
                      valueColor: Colors.black,
                    ),
                    MetricCard(
                      icon: Icons.attach_money,
                      label: 'Outstanding',
                      value: formatCurrency(
                        (metrics.totalRentDue - metrics.totalRentCollected < 0
                                ? 0
                                : metrics.totalRentDue -
                                      metrics.totalRentCollected)
                            .toDouble(),
                        currencySymbol: 'UGX',
                      ),
                      iconColor: Colors.amber.shade700,
                      valueColor: Colors.black,
                    ),
                    MetricCard(
                      icon: Icons.build,
                      label: 'Open Tasks',
                      value: '${metrics.openMaintenanceTasks}',
                      iconColor: scheme.error,
                      valueColor: Colors.black,
                    ),
                    MetricCard(
                      icon: Icons.group,
                      label: 'Pending Actions',
                      value: '${metrics.pendingApprovals}',
                      iconColor: Colors.green,
                      valueColor: Colors.black,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                ActionTile(
                  icon: Icons.playlist_add_check,
                  title: 'Start New Inspection',
                  subtitle: '',
                  onTap: () => context.go('/inspections'),
                ),

                const SizedBox(height: 12),

                ActionTile(
                  icon: Icons.build,
                  title: 'View Maintenance Tasks',
                  subtitle: '',
                  onTap: () => context.go('/landlord-maintenance'),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// ===============================
/// QUICK ACTION (Optional reusable)
/// ===============================
class QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;

  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}
