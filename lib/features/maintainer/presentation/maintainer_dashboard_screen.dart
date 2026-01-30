import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:login_again/core/utils/formatters.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/landlord/presentation/cubit/maintenance_tasks_state.dart';
import 'package:login_again/features/landlord/presentation/widgets/action_tile.dart';
import 'package:login_again/features/maintainer/presentation/cubit/maintainer_inspections_cubit.dart';
import 'package:login_again/features/maintainer/presentation/cubit/maintainer_tasks_cubit.dart';

class MaintainerDashboardScreen extends StatefulWidget {
  const MaintainerDashboardScreen({super.key});

  @override
  State<MaintainerDashboardScreen> createState() =>
      _MaintainerDashboardScreenState();
}

class _MaintainerDashboardScreenState extends State<MaintainerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>().state;
    if (auth is Authenticated) {
      context.read<MaintainerTasksCubit>().load(partnerId: auth.user.partnerId);
      context.read<MaintainerInspectionsCubit>().load(userId: auth.user.id);
    }
  }

  String _tupleName(dynamic value) {
    if (value is List && value.length > 1) return value[1]?.toString() ?? '-';
    return '-';
  }

  IconData _taskIcon(String status) {
    switch (status) {
      case 'in_progress':
        return Icons.build_outlined;
      case 'open':
        return Icons.warning_amber_rounded;
      case 'done':
        return Icons.check_circle_outline;
      default:
        return Icons.task_alt;
    }
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = context.watch<AuthCubit>().state;

    final userName = authState is Authenticated ? authState.user.name : 'User';
    final parts = userName
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .toList();
    final firstName = parts.isEmpty ? 'User' : parts.first;

    return MultiBlocListener(
      listeners: [
        BlocListener<MaintainerTasksCubit, MaintenanceTasksState>(
          listener: (context, state) {
            if (state is MaintenanceTasksLoading) {
              loading.Widgets.showLoader(context);
            } else {
              loading.Widgets.hideLoader(context);
            }
          },
        ),
        BlocListener<MaintainerInspectionsCubit, MaintenanceTasksState>(
          listener: (context, state) {
            if (state is MaintenanceTasksLoading) {
              loading.Widgets.showLoader(context);
            } else {
              loading.Widgets.hideLoader(context);
            }
          },
        ),
      ],
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            final auth = context.read<AuthCubit>().state;
            if (auth is Authenticated) {
              await context.read<MaintainerTasksCubit>().load(
                partnerId: auth.user.partnerId,
              );
              await context.read<MaintainerInspectionsCubit>().load(
                userId: auth.user.id,
              );
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24, top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${capitalizeFirst(firstName)}',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Overview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _StatsRow(),
                ),
                const SizedBox(height: 24),

                // Today's Tasks
                _SectionHeader(
                  title: "Today's Tasks",
                  onViewAll: () => context.go('/maintainer-tasks'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TodayTasksList(
                    tupleName: _tupleName,
                    iconForStatus: _taskIcon,
                  ),
                ),
                const SizedBox(height: 24),

                // Upcoming Inspections
                _SectionHeader(
                  title: 'Pending Inspections',
                  onViewAll: () => context.go('/maintainer-inspections'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _UpcomingInspectionsList(tupleName: _tupleName),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Quick Actions',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.build_outlined,
                          label: 'My Tasks',
                          onTap: () => context.go('/maintainer-tasks'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.search_outlined,
                          label: 'Inspections',
                          onTap: () => context.go('/maintainer-inspections'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<MaintainerTasksCubit, MaintenanceTasksState>(
      builder: (context, state) {
        final tasks = state is MaintenanceTasksLoaded ? state.tasks : const [];
        final draftCount = tasks
            .where((t) => (t['state'] ?? '') == 'draft')
            .length;
        final inProgressCount = tasks
            .where((t) => (t['state'] ?? '') == 'in_progress')
            .length;
        final doneCount = tasks
            .where((t) => (t['state'] ?? '') == 'done')
            .length;

        return Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.access_time,
                label: 'Draft',
                value: '$draftCount',
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.build_outlined,
                label: 'In Progress',
                value: '$inProgressCount',
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.check_circle_outline,
                label: 'Done',
                value: '$doneCount',
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          TextButton(onPressed: onViewAll, child: const Text('View All')),
        ],
      ),
    );
  }
}

class _TodayTasksList extends StatelessWidget {
  final String Function(dynamic value) tupleName;
  final IconData Function(String status) iconForStatus;

  const _TodayTasksList({required this.tupleName, required this.iconForStatus});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MaintainerTasksCubit, MaintenanceTasksState>(
      builder: (context, state) {
        if (state is MaintenanceTasksLoading) {
          return const SizedBox.shrink();
        }
        if (state is MaintenanceTasksError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(state.message),
          );
        }
        if (state is MaintenanceTasksLoaded) {
          final tasks = state.tasks.take(3).toList();
          if (tasks.isEmpty) {
            return const _EmptyCard(
              icon: Icons.build_outlined,
              text: 'No tasks assigned',
            );
          }

          return Column(
            children: tasks.map((task) {
              final title = (task['name'] ?? 'Task').toString();
              final unitName = tupleName(task['unit_id']);
              final rawState = (task['state'] ?? '').toString();

              return ActionTile(
                icon: iconForStatus(rawState),
                title: title,
                subtitle: unitName == '-' ? 'Unit' : unitName,
                state: rawState,
                onTap: () => context.go('/maintainer-tasks'),
              );
            }).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _UpcomingInspectionsList extends StatelessWidget {
  final String Function(dynamic value) tupleName;

  const _UpcomingInspectionsList({required this.tupleName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MaintainerInspectionsCubit, MaintenanceTasksState>(
      builder: (context, state) {
        if (state is MaintenanceTasksLoading) {
          return const SizedBox.shrink();
        }
        if (state is MaintenanceTasksError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(state.message),
          );
        }
        if (state is MaintenanceTasksLoaded) {
          final inspections = state.tasks.take(2).toList();
          if (inspections.isEmpty) {
            return const _EmptyCard(
              icon: Icons.search_outlined,
              text: 'No inspections scheduled',
            );
          }

          return Column(
            children: inspections.map((item) {
              final title = (item['name'] ?? 'Inspection').toString();
              final unitName = tupleName(item['unit_id']);
              final dateStr = (item['date'] ?? '').toString();
              final s = (item['state'] ?? '').toString();

              return ActionTile(
                icon: Icons.search_outlined,
                title: title,
                subtitle: '${unitName == '-' ? 'Unit' : unitName} • $dateStr',
                state: s,
                onTap: () => context.go('/maintainer-inspections'),
              );
            }).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primary.withOpacity(0.10),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primary.withOpacity(0.12),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
