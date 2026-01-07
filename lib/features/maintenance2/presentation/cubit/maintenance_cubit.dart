import 'package:bloc/bloc.dart';
import '../../data/repositories/maintenance_repository.dart';
import 'maintenance_state.dart';

class MaintenanceCubit extends Cubit<MaintenanceState> {
  final MaintenanceRepository repository;

  MaintenanceCubit(this.repository) : super(MaintenanceInitial());

  // Load maintenance requests for a specific partner/user
  Future<void> loadRequests(int partnerId) async {
    try {
      emit(MaintenanceLoading());
      final requests = await repository.fetchRequests(partnerId);
      emit(MaintenanceLoaded(requests));
    } catch (e) {
      emit(MaintenanceError('Failed to load requests'));
    }
  }
}
