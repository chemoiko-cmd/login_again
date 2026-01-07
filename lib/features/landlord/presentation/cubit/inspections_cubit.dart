import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/landlord_repository.dart';
import '../../data/models/landlord_inpsections_model.dart';
import 'inspections_state.dart';

class InspectionsCubit extends Cubit<InspectionsState> {
  Future<bool> addInspection({
    required int partnerId,
    required int unitId,
    required String date,
    String? name,
    int? inspectorId,
    int? contractId,
    String? conditionNotes,
    int? cleanliness,
    bool? maintenanceRequired,
    String? maintenanceDescription,
  }) async {
    emit(InspectionsLoading());
    final success = await repository.createInspection(
      unitId: unitId,
      date: date,
      name: name,
      inspectorId: inspectorId,
      contractId: contractId,
      conditionNotes: conditionNotes,
      cleanliness: cleanliness,
      maintenanceRequired: maintenanceRequired,
      maintenanceDescription: maintenanceDescription,
    );
    if (success) {
      await load(partnerId: partnerId);
      return true;
    } else {
      emit(const InspectionsError('Failed to create inspection'));
      return false;
    }
  }

  final LandlordRepository repository;

  InspectionsCubit(this.repository) : super(InspectionsInitial());

  Future<void> load({required int partnerId}) async {
    try {
      emit(InspectionsLoading());
      final List<Inspection> items = await repository.fetchInspections(
        partnerId: partnerId,
      );
      emit(InspectionsLoaded(items));
    } catch (_) {
      emit(const InspectionsError('Failed to load inspections'));
    }
  }
}
