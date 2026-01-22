import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/landlord_repository.dart';
import 'maintenance_tasks_state.dart';

class MaintenanceTasksCubit extends Cubit<MaintenanceTasksState> {
  final LandlordRepository repository;

  MaintenanceTasksCubit(this.repository) : super(MaintenanceTasksInitial());

  Future<void> load({required int partnerId}) async {
    try {
      emit(MaintenanceTasksLoading());
      final tasks = await repository.fetchMaintenanceTasks(
        partnerId: partnerId,
      );
      emit(MaintenanceTasksLoaded(tasks));
    } catch (_) {
      emit(const MaintenanceTasksError('Failed to load maintenance tasks'));
    }
  }

  Future<bool> addTask({
    required int partnerId,
    required int unitId,
    required String name,
    int? assignedToPartnerId,
    String? priority,
  }) async {
    emit(MaintenanceTasksLoading());
    final ok = await repository.createMaintenanceTask(
      landlordPartnerId: partnerId,
      unitId: unitId,
      name: name,
      assignedToPartnerId: assignedToPartnerId,
      priority: priority,
    );

    if (ok) {
      await load(partnerId: partnerId);
      return true;
    }

    emit(const MaintenanceTasksError('Failed to create maintenance task'));
    return false;
  }
}
