import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/tenant_repository.dart';
import 'tenant_dashboard_state.dart';

class TenantDashboardCubit extends Cubit<TenantDashboardState> {
  final TenantRepository repo;
  TenantDashboardCubit({required this.repo})
    : super(TenantDashboardState.initial());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final data = await repo.loadDashboard().timeout(
        const Duration(seconds: 25),
      );
      List<Map<String, dynamic>> anns = const <Map<String, dynamic>>[];
      try {
        anns = await repo
            .loadAnnouncements(limit: 3)
            .timeout(const Duration(seconds: 25));
      } catch (_) {
        anns = const <Map<String, dynamic>>[];
      }
      emit(
        state.copyWith(
          loading: false,
          data: data,
          announcements: anns,
          error: null,
        ),
      );
    } on TimeoutException {
      emit(state.copyWith(loading: false, error: 'Request timed out'));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
