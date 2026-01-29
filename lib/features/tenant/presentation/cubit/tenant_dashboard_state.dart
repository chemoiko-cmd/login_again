import 'package:equatable/equatable.dart';

class TenantDashboardState extends Equatable {
  final bool loading;
  final Map<String, dynamic>? data;
  final List<Map<String, dynamic>> announcements;
  final String? error;

  const TenantDashboardState({
    required this.loading,
    this.data,
    this.announcements = const <Map<String, dynamic>>[],
    this.error,
  });

  factory TenantDashboardState.initial() =>
      const TenantDashboardState(loading: true);

  TenantDashboardState copyWith({
    bool? loading,
    Map<String, dynamic>? data,
    List<Map<String, dynamic>>? announcements,
    String? error,
  }) {
    return TenantDashboardState(
      loading: loading ?? this.loading,
      data: data ?? this.data,
      announcements: announcements ?? this.announcements,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, data, announcements, error];
}
