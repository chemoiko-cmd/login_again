import 'package:equatable/equatable.dart';

class TenantDashboardState extends Equatable {
  final bool loading;
  final Map<String, dynamic>? data;
  final String? error;

  const TenantDashboardState({required this.loading, this.data, this.error});

  factory TenantDashboardState.initial() =>
      const TenantDashboardState(loading: true);

  TenantDashboardState copyWith({
    bool? loading,
    Map<String, dynamic>? data,
    String? error,
  }) {
    return TenantDashboardState(
      loading: loading ?? this.loading,
      data: data ?? this.data,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, data, error];
}
