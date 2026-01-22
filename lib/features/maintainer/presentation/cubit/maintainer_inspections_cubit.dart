import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/maintainer_repository.dart';
import '../../../landlord/presentation/cubit/maintenance_tasks_state.dart';

class MaintainerInspectionsCubit extends Cubit<MaintenanceTasksState> {
  final MaintainerRepository repository;

  MaintainerInspectionsCubit(this.repository)
    : super(MaintenanceTasksInitial());

  Future<void> load({required int userId}) async {
    try {
      emit(MaintenanceTasksLoading());
      final inspections = await repository.fetchAssignedInspections(
        userId: userId,
      );
      emit(MaintenanceTasksLoaded(inspections));
    } catch (_) {
      emit(const MaintenanceTasksError('Failed to load assigned inspections'));
    }
  }

  Future<bool> setInspectionState({
    required int inspectionId,
    required String state,
    required int userId,
  }) async {
    final ok = await repository.updateInspectionState(
      inspectionId: inspectionId,
      state: state,
    );
    if (ok) {
      await load(userId: userId);
      return true;
    }
    emit(const MaintenanceTasksError('Failed to update inspection state'));
    return false;
  }

  Future<bool> updateInspectionDetails({
    required int inspectionId,
    required bool maintenanceRequired,
    required String conditionNotes,
    String? maintenanceDescription,
    String? state,
    required int userId,
  }) async {
    final ok = await repository.updateInspectionDetails(
      inspectionId: inspectionId,
      state: state,
      maintenanceRequired: maintenanceRequired,
      conditionNotes: conditionNotes,
      maintenanceDescription: maintenanceDescription,
    );
    if (ok) {
      await load(userId: userId);
      return true;
    }
    emit(const MaintenanceTasksError('Failed to update inspection details'));
    return false;
  }
}
