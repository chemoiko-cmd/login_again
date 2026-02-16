import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/landlord/presentation/cubit/maintenance_tasks_cubit.dart';
import 'package:login_again/features/landlord/presentation/cubit/maintenance_tasks_state.dart';
import 'package:login_again/features/landlord/presentation/widgets/action_tile.dart';
import 'package:login_again/core/widgets/gradient_floating_action_button.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;

class LandlordMaintenanceScreen extends StatefulWidget {
  const LandlordMaintenanceScreen({super.key});

  @override
  State<LandlordMaintenanceScreen> createState() =>
      _LandlordMaintenanceScreenState();
}

class _LandlordMaintenanceScreenState extends State<LandlordMaintenanceScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      final partnerId = authState is Authenticated
          ? authState.user.partnerId
          : 0;
      if (partnerId > 0) {
        context.read<MaintenanceTasksCubit>().load(partnerId: partnerId);
      }
    });
  }

  String _tupleName(dynamic value) {
    if (value is List && value.length > 1) return value[1]?.toString() ?? '-';
    return '-';
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          BlocConsumer<MaintenanceTasksCubit, MaintenanceTasksState>(
            listener: (context, state) {
              final shouldShow = state is MaintenanceTasksLoading;
              if (shouldShow) {
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
                  return const Center(
                    child: Text('No maintenance tasks found'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.tasks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = state.tasks[index];
                    final unitName = _tupleName(task['unit_id']);
                    final assignedName = _tupleName(task['assigned_to']);

                    return ActionTile(
                      icon: Icons.build_outlined,
                      title: (task['name'] ?? 'Task').toString(),
                      subtitle: '$unitName • $assignedName',
                      state: (task['state'] ?? '').toString(),
                      onTap: () {},
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      floatingActionButton: GradientFloatingActionButton(
        onPressed: () async {
          final result = await context.push<bool>('/landlord-maintenance/add');
          if (result == true) {
            final authState = context.read<AuthCubit>().state;
            final partnerId = authState is Authenticated
                ? authState.user.partnerId
                : 0;
            if (partnerId > 0) {
              context.read<MaintenanceTasksCubit>().load(partnerId: partnerId);
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
