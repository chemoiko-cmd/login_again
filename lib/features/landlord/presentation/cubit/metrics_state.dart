import 'package:equatable/equatable.dart';
import '../../data/models/landlord_metrics_model.dart';

abstract class MetricsState extends Equatable {
  const MetricsState();
  @override
  List<Object?> get props => [];
}

class MetricsInitial extends MetricsState {}

class MetricsLoading extends MetricsState {}

class MetricsLoaded extends MetricsState {
  final LandlordMetricsModel metrics;
  const MetricsLoaded(this.metrics);
  @override
  List<Object?> get props => [metrics];
}

class MetricsError extends MetricsState {
  final String message;
  const MetricsError(this.message);
  @override
  List<Object?> get props => [message];
}
