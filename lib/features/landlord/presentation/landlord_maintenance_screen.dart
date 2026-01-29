import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/landlord/presentation/cubit/maintenance_tasks_cubit.dart';
import 'package:login_again/features/landlord/presentation/cubit/maintenance_tasks_state.dart';
import 'package:login_again/features/landlord/presentation/widgets/action_tile.dart';
import 'package:login_again/features/landlord/presentation/widgets/maintenance_task_create_overlay.dart';
import 'package:login_again/core/widgets/gradient_floating_action_button.dart';
import 'package:login_again/core/widgets/app_loading_indicator.dart';

class LandlordMaintenanceScreen extends StatefulWidget {
  const LandlordMaintenanceScreen({super.key});

  @override
  State<LandlordMaintenanceScreen> createState() =>
      _LandlordMaintenanceScreenState();
}

class _LandlordMaintenanceScreenState extends State<LandlordMaintenanceScreen> {
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    final partnerId = authState is Authenticated ? authState.user.partnerId : 0;
    if (partnerId > 0) {
      context.read<MaintenanceTasksCubit>().load(partnerId: partnerId);
    }
  }

  String _tupleName(dynamic value) {
    if (value is List && value.length > 1) return value[1]?.toString() ?? '-';
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocBuilder<MaintenanceTasksCubit, MaintenanceTasksState>(
            builder: (context, state) {
              if (state is MaintenanceTasksLoading && !_isCreating) {
                return const Center(child: AppLoadingIndicator());
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

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.tasks.length,
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
          if (_isCreating)
            Builder(
              builder: (context) {
                final authState = context.read<AuthCubit>().state;
                final partnerId = authState is Authenticated
                    ? authState.user.partnerId
                    : 0;

                return MaintenanceTaskCreateOverlay(
                  partnerId: partnerId,
                  onClose: () => setState(() => _isCreating = false),
                );
              },
            ),
        ],
      ),
      floatingActionButton: _isCreating
          ? null
          : GradientFloatingActionButton(
              onPressed: () => setState(() => _isCreating = true),
              child: const Icon(Icons.add),
            ),
    );
  }
}
