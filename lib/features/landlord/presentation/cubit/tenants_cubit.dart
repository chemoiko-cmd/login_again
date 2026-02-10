import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';
import '../../data/repositories/landlord_repository.dart';
import 'tenants_state.dart';

class TenantsCubit extends Cubit<TenantsState> {
  final LandlordRepository repository;

  TenantsCubit(this.repository) : super(TenantsInitial());

  Future<bool> addTenant({
    required int partnerId,
    required int unitId,
    required int tenantPartnerId,
    String? name,
    required String startDate,
    required String endDate,
  }) async {
    emit(TenantsLoading());
    final ok = await repository.createRentalContract(
      tenantPartnerId: tenantPartnerId,
      unitId: unitId,
      name: name,
      startDate: startDate,
      endDate: endDate,
    );
    if (ok) {
      await load(partnerId: partnerId);
      return true;
    } else {
      emit(const TenantsError('Failed to add tenant'));
      return false;
    }
  }

  Future<bool> createTenantAndContract({
    required int partnerId,
    required int unitId,
    String? contractName,
    required String startDate,
    required String endDate,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? mobile,
    Uint8List? imageBytes,
  }) async {
    emit(TenantsLoading());
    final newPartnerId = await repository.createPartner(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      mobile: mobile,
      imageBytes: imageBytes,
    );
    if (newPartnerId == null) {
      emit(const TenantsError('Failed to create tenant'));
      return false;
    }

    final ok = await repository.createRentalContract(
      tenantPartnerId: newPartnerId,
      unitId: unitId,
      name: contractName,
      startDate: startDate,
      endDate: endDate,
    );

    if (ok) {
      await load(partnerId: partnerId);
      return true;
    } else {
      emit(const TenantsError('Failed to create contract'));
      return false;
    }
  }

  Future<void> load({required int partnerId}) async {
    try {
      emit(TenantsLoading());
      final tenants = await repository.fetchTenantsWithStatus(
        partnerId: partnerId,
      );
      emit(TenantsLoaded(tenants));
    } catch (_) {
      emit(const TenantsError('Failed to load tenants'));
    }
  }
}
