import 'package:equatable/equatable.dart';
import 'package:login_again/features/landlord/data/models/landlord_tenant_row.dart';

abstract class TenantsState extends Equatable {
  const TenantsState();

  @override
  List<Object?> get props => [];
}

class TenantsInitial extends TenantsState {}

class TenantsLoading extends TenantsState {}

class TenantsLoaded extends TenantsState {
  final List<LandlordTenantRow> tenants;

  const TenantsLoaded(this.tenants);

  @override
  List<Object?> get props => [tenants];
}

class TenantsError extends TenantsState {
  final String message;

  const TenantsError(this.message);

  @override
  List<Object?> get props => [message];
}
