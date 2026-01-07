import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/landlord_repository.dart';
import 'metrics_state.dart';

class MetricsCubit extends Cubit<MetricsState> {
  final LandlordRepository repository;

  MetricsCubit(this.repository) : super(MetricsInitial());

  Future<void> load({int? partnerId}) async {
    try {
      emit(MetricsLoading());
      final metrics = await repository.fetchMetrics(partnerId: partnerId);
      emit(MetricsLoaded(metrics));
    } catch (_) {
      emit(const MetricsError('Failed to load metrics'));
    }
  }
}
