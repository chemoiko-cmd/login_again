import '../../data/models/maintenance_request_model.dart';

abstract class MaintenanceState {}

class MaintenanceInitial extends MaintenanceState {}

class MaintenanceLoading extends MaintenanceState {}

class MaintenanceLoaded extends MaintenanceState {
  final List<MaintenanceRequestModel> requests;

  MaintenanceLoaded(this.requests);
}

class MaintenanceError extends MaintenanceState {
  final String message;

  MaintenanceError(this.message);
}
