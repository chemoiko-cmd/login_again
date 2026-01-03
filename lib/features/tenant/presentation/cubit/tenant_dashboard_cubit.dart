import 'package:bloc/bloc.dart';
import '../../data/tenant_repository.dart';
import 'tenant_dashboard_state.dart';

class TenantDashboardCubit extends Cubit<TenantDashboardState> {
  final TenantRepository repo;
  TenantDashboardCubit({required this.repo})
    : super(TenantDashboardState.initial());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final data = await repo.loadDashboard();
      emit(state.copyWith(loading: false, data: data, error: null));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
