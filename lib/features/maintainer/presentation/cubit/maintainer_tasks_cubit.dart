import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/maintainer_repository.dart';
import '../../../landlord/presentation/cubit/maintenance_tasks_state.dart';

class MaintainerTasksCubit extends Cubit<MaintenanceTasksState> {
  final MaintainerRepository repository;

  MaintainerTasksCubit(this.repository) : super(MaintenanceTasksInitial());

  Future<void> load({required int partnerId}) async {
    try {
      emit(MaintenanceTasksLoading());
      final tasks = await repository.fetchAssignedTasks(partnerId: partnerId);
      emit(MaintenanceTasksLoaded(tasks));
    } catch (_) {
      emit(const MaintenanceTasksError('Failed to load assigned tasks'));
    }
  }

  Future<bool> setTaskState({
    required int taskId,
    required String state,
    required int partnerId,
  }) async {
    final ok = await repository.updateTaskState(taskId: taskId, state: state);
    if (ok) {
      await load(partnerId: partnerId);
      return true;
    }
    emit(const MaintenanceTasksError('Failed to update task state'));
    return false;
  }
}
