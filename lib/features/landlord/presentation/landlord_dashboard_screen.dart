import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/core/utils/formatters.dart';
import 'package:login_again/features/landlord/presentation/widgets/action_tile.dart';
import '../data/repositories/landlord_repository.dart';
import 'cubit/metrics_cubit.dart';
import 'cubit/metrics_state.dart';
import 'widgets/rent_card.dart';
import 'widgets/metric_card.dart';

class LandlordDashboardScreen extends StatefulWidget {
  const LandlordDashboardScreen({super.key});

  @override
  State<LandlordDashboardScreen> createState() =>
      _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends State<LandlordDashboardScreen> {
  late final MetricsCubit cubit;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>();
    cubit = MetricsCubit(LandlordRepository(apiClient: auth.apiClient));

    final authState = auth.state;
    int? partnerId;
    if (authState is Authenticated) {
      partnerId = authState.user.partnerId;
      print('names are ${authState.user.name}');
    }
    cubit.load(partnerId: partnerId);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('Landlord Dashboard')),
        body: BlocBuilder<MetricsCubit, MetricsState>(
          builder: (context, state) {
            if (state is MetricsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MetricsError) {
              return Center(child: Text(state.message));
            }

            if (state is MetricsLoaded) {
              final metrics = state.metrics;
              print('metrics ${metrics.occupiedUnits}');

              final authState = context.watch<AuthCubit>().state;
              final userName = authState is Authenticated
                  ? authState.user.name
                  : 'User';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello $userName'),
                    const SizedBox(height: 20),

                    /// ===============================            /// RENT CARD (Reusable)
                    ///
                    RentCard(
                      totalCollected: metrics.totalRentCollected.toDouble(),
                      totalOverall: metrics.totalRentDue.toDouble(),
                    ),
                    const SizedBox(height: 24),

                    /// METRICS GRID
                    /// ===============================
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      children: [
                        MetricCard(
                          icon: Icons.apartment,
                          label: 'Occupancy Rate',
                          value:
                              '${metrics.occupiedUnits}/${metrics.totalUnits} units',

                          iconColor: scheme.primary,
                          valueColor: Colors.black,
                        ),
                        MetricCard(
                          icon: Icons.attach_money,
                          label: 'Outstanding',
                          value: formatCurrency(
                            (metrics.totalRentDue - metrics.totalRentCollected <
                                        0
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

                    /// ===============================
                    /// QUICK ACTIONS
                    /// ===============================
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
                      onTap: () => (),
                    ),

                    ActionTile(
                      icon: Icons.build,
                      title: 'View Maintenance Tasks',
                      subtitle: '',
                      onTap: () => (),
                    ),

                    ActionTile(
                      icon: Icons.pending_actions,
                      title: 'Pending Approvals',
                      subtitle: '',
                      onTap: () => (),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

/// ===============================
/// QUICK ACTION
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
        color: scheme.surfaceVariant.withValues(alpha: 0.4),
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
