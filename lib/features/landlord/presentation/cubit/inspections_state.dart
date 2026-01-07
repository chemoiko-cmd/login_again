import 'package:equatable/equatable.dart';
import '../../data/models/landlord_inpsections_model.dart';

abstract class InspectionsState extends Equatable {
  const InspectionsState();
  @override
  List<Object?> get props => [];
}

class InspectionsInitial extends InspectionsState {}

class InspectionsLoading extends InspectionsState {}

class InspectionsLoaded extends InspectionsState {
  final List<Inspection> inspections;
  const InspectionsLoaded(this.inspections);
  @override
  List<Object?> get props => [inspections];
}

class InspectionsError extends InspectionsState {
  final String message;
  const InspectionsError(this.message);
  @override
  List<Object?> get props => [message];
}
