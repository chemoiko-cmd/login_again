import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/maintainer/presentation/cubit/maintainer_tasks_cubit.dart';
import 'package:login_again/features/landlord/presentation/cubit/maintenance_tasks_state.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;
import 'package:login_again/core/utils/formatters.dart';

class MaintainerTasksScreen extends StatefulWidget {
  const MaintainerTasksScreen({super.key});

  @override
  State<MaintainerTasksScreen> createState() => _MaintainerTasksScreenState();
}

class _MaintainerTasksScreenState extends State<MaintainerTasksScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>().state;
    if (auth is Authenticated) {
      context.read<MaintainerTasksCubit>().load(partnerId: auth.user.partnerId);
    }
  }

  String _tupleName(dynamic value) {
    if (value is List && value.length > 1) return value[1]?.toString() ?? '-';
    return '-';
  }

  Future<void> _setStateForTask(int taskId, String newState) async {
    final auth = context.read<AuthCubit>().state;
    final partnerId = auth is Authenticated ? auth.user.partnerId : 0;
    final ok = await context.read<MaintainerTasksCubit>().setTaskState(
      taskId: taskId,
      state: newState,
      partnerId: partnerId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Task updated' : 'Failed to update task')),
    );
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: BlocConsumer<MaintainerTasksCubit, MaintenanceTasksState>(
        listener: (context, state) {
          if (state is MaintenanceTasksLoading) {
            loading.Widgets.showLoader(context);
          } else {
            loading.Widgets.hideLoader(context);
          }
        },
        builder: (context, state) {
          if (state is MaintenanceTasksLoading) {
            return const SizedBox.shrink();
          }
          if (state is MaintenanceTasksError) {
            return Center(child: Text(state.message));
          }
          if (state is MaintenanceTasksLoaded) {
            if (state.tasks.isEmpty) {
              return const Center(child: Text('No tasks assigned'));
            }
            return RefreshIndicator(
              onRefresh: () async {
                final auth = context.read<AuthCubit>().state;
                final partnerId = auth is Authenticated
                    ? auth.user.partnerId
                    : 0;
                await context.read<MaintainerTasksCubit>().load(
                  partnerId: partnerId,
                );
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: state.tasks.length,
                itemBuilder: (context, index) {
                  final task = state.tasks[index];
                  final unitName = _tupleName(task['unit_id']);
                  final title = (task['name'] ?? 'Task').toString();
                  final assignedName = _tupleName(task['assigned_to']);
                  final taskId = (task['id'] as num?)?.toInt() ?? 0;
                  final s = (task['state'] ?? '').toString();

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade50,
                        child: Icon(
                          Icons.build_outlined,
                          color: scheme.primary,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(title)),
                          Chip(
                            label: Text(
                              formatStateLabel(s),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: stateBadgeColor(s),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      subtitle: Text('$unitName • $assignedName'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'in_progress') {
                            _setStateForTask(taskId, 'in_progress');
                          } else if (value == 'done') {
                            _setStateForTask(taskId, 'done');
                          } else if (value == 'open') {
                            _setStateForTask(taskId, 'open');
                          }
                        },
                        itemBuilder: (context) {
                          final items = <PopupMenuEntry<String>>[];
                          if (s != 'in_progress') {
                            items.add(
                              const PopupMenuItem(
                                value: 'in_progress',
                                child: Text('Start (In Progress)'),
                              ),
                            );
                          }
                          if (s != 'done') {
                            items.add(
                              const PopupMenuItem(
                                value: 'done',
                                child: Text('Mark Done'),
                              ),
                            );
                          }
                          if (s != 'open') {
                            items.add(
                              const PopupMenuItem(
                                value: 'open',
                                child: Text('Reopen'),
                              ),
                            );
                          }
                          return items;
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
