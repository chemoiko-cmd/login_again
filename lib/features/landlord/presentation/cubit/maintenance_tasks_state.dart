import 'package:equatable/equatable.dart';

abstract class MaintenanceTasksState extends Equatable {
  const MaintenanceTasksState();

  @override
  List<Object?> get props => [];
}

class MaintenanceTasksInitial extends MaintenanceTasksState {}

class MaintenanceTasksLoading extends MaintenanceTasksState {}

class MaintenanceTasksLoaded extends MaintenanceTasksState {
  final List<Map<String, dynamic>> tasks;

  const MaintenanceTasksLoaded(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class MaintenanceTasksError extends MaintenanceTasksState {
  final String message;

  const MaintenanceTasksError(this.message);

  @override
  List<Object?> get props => [message];
}
