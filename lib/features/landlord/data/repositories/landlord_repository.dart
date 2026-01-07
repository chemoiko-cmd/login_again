import 'package:dio/dio.dart';
import 'package:login_again/core/api/api_client.dart';
import 'package:login_again/features/landlord/data/models/landlord_inpsections_model.dart';
import '../models/landlord_metrics_model.dart';

class LandlordRepository {
  /// Fetch units owned by the landlord (via property owner partner)
  Future<List<Map<String, dynamic>>> fetchUnits({
    required int partnerId,
  }) async {
    try {
      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.unit',
            'method': 'search_read',
            'args': [],
            'kwargs': {
              'domain': [
                ['property_id.owner_id', '=', partnerId],
              ],
              'fields': ['name'],
              'limit': 200,
              'order': 'property_id, name',
            },
          },
          'id': 1,
        },
      );
      final list = (resp.data['result'] as List?) ?? [];
      return list.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e);
        return {'id': m['id'] as int, 'name': m['name'] as String? ?? 'Unit'};
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch maintenance partners (labels) with their linked user IDs (for inspector_id)
  Future<List<Map<String, dynamic>>> fetchInspectorPartners() async {
    try {
      // Find group id by name (Rental Maintenance Worker)
      final groupsResp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'res.groups',
            'method': 'search_read',
            'args': [],
            'kwargs': {
              'domain': [
                ['name', '=', 'Rental Maintenance Worker'],
              ],
              'fields': ['name'],
              'limit': 1,
            },
          },
          'id': 1,
        },
      );
      final groups = (groupsResp.data['result'] as List?) ?? [];
      if (groups.isEmpty) return [];
      final groupId = (groups.first as Map)['id'] as int;

      // Query partners whose related users belong to the group
      final partnersResp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'res.partner',
            'method': 'search_read',
            'args': [],
            'kwargs': {
              'domain': [
                [
                  'user_ids.groups_id',
                  'in',
                  [groupId],
                ],
              ],
              'fields': ['name', 'user_ids'],
              'limit': 200,
              'order': 'name',
            },
          },
          'id': 1,
        },
      );
      final partners = (partnersResp.data['result'] as List?) ?? [];
      return partners.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e);
        final List userIds = (m['user_ids'] as List?) ?? const [];
        return {
          'partner_id': m['id'] as int,
          'user_id': userIds.isNotEmpty ? (userIds.first as int) : null,
          'name': m['name'] as String? ?? 'Partner',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch inspectors: users in the Rental Maintenance Worker group
  Future<List<Map<String, dynamic>>> fetchInspectors() async {
    try {
      // 1) Find group id by name
      final groupsResp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'res.groups',
            'method': 'search_read',
            'args': [],
            'kwargs': {
              'domain': [
                ['name', '=', 'Rental Maintenance Worker'],
              ],
              'fields': ['name'],
              'limit': 1,
            },
          },
          'id': 1,
        },
      );
      final groups = (groupsResp.data['result'] as List?) ?? [];
      if (groups.isEmpty) return [];
      final groupId = (groups.first as Map)['id'] as int;

      // 2) Fetch users in that group
      final usersResp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'res.users',
            'method': 'search_read',
            'args': [],
            'kwargs': {
              'domain': [
                [
                  'groups_id',
                  'in',
                  [groupId],
                ],
              ],
              'fields': ['name', 'partner_id'],
              'limit': 200,
              'order': 'name',
            },
          },
          'id': 1,
        },
      );
      final users = (usersResp.data['result'] as List?) ?? [];
      return users.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e);
        final partnerTuple = m['partner_id'] as List?; // [id, display_name]
        final partnerName = partnerTuple != null && partnerTuple.length > 1
            ? partnerTuple[1] as String
            : null;
        return {
          'id': m['id'] as int, // res.users id
          'name': partnerName ?? (m['name'] as String? ?? 'User'),
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> createInspection({
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
    try {
      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.inspection',
            'method': 'create',
            'args': [
              {
                'unit_id': unitId,
                'date': date,
                if (name != null) 'name': name,
                if (inspectorId != null) 'inspector_id': inspectorId,
                if (contractId != null) 'contract_id': contractId,
                if (conditionNotes != null) 'condition_notes': conditionNotes,
                if (cleanliness != null) 'cleanliness': cleanliness.toString(),
                if (maintenanceRequired != null)
                  'maintenance_required': maintenanceRequired,
                if (maintenanceDescription != null)
                  'maintenance_description': maintenanceDescription,
              },
            ],
            'kwargs': {},
          },
          'id': 1,
        },
      );
      // Odoo returns the new record ID if successful
      return resp.data['result'] != null;
    } catch (e) {
      return false;
    }
  }

  final ApiClient apiClient;

  LandlordRepository({required this.apiClient});

  Future<LandlordMetricsModel> fetchMetrics({int? partnerId}) async {
    try {
      // 1) Fetch dashboard data from backend
      final Response dataResp = await apiClient.dio.post(
        '/rental/dashboard/data',
        data: const {},
      );

      final body = dataResp.data as Map? ?? {};
      final result = body['result'] as Map? ?? {};
      final data = result['data'] as Map? ?? {};
      final metrics = data['metrics'] as Map? ?? {};

      // 2) Extract metrics safely
      final int totalUnits = (metrics['total_units'] ?? 0) as int;
      final int occupiedUnits = (metrics['total_occupied'] ?? 0) as int;
      final double occupancyRate = ((metrics['avg_occupancy'] ?? 0) as num)
          .toDouble();
      final int totalRentCollected =
          ((metrics['total_rent_collected'] ?? 0) as num).toInt();
      final int totalRentDue = ((metrics['total_expected'] ?? 0) as num)
          .toInt();
      final int outstanding = ((metrics['outstanding_money'] ?? 0) as num)
          .toInt();
      final int openMaintenanceTasks =
          (metrics['open_maintenance_tasks'] ?? 0) as int;

      // 3) Map to model
      return LandlordMetricsModel(
        totalUnits: totalUnits,
        occupiedUnits: occupiedUnits,
        occupancyRate: occupancyRate,
        totalRentCollected: totalRentCollected,
        totalRentDue: totalRentDue,
        outstanding: outstanding,
        openMaintenanceTasks: openMaintenanceTasks,
        pendingApprovals: 0, // backend not yet exposing
      );
    } catch (e, s) {
      // Log the error for debugging
      print('Failed to fetch landlord metrics: $e\n$s');

      // Fallback: minimal safe defaults
      return LandlordMetricsModel(
        totalUnits: 0,
        occupiedUnits: 0,
        occupancyRate: 0,
        totalRentCollected: 0,
        totalRentDue: 0,
        outstanding: 0,
        openMaintenanceTasks: 0,
        pendingApprovals: 0,
      );
    }
  }

  Future<List<Inspection>> fetchInspections({required int partnerId}) async {
    try {
      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.inspection',
            'method': 'search_read',
            'args': [],
            'kwargs': {
              'domain': [
                ['property_id.owner_id', '=', partnerId],
              ],
              'fields': ['name', 'state', 'property_id', 'unit_id'],
              'limit': 100,
              'order': 'id desc',
            },
          },
          'id': 1,
        },
      );

      final list = (resp.data['result'] as List?) ?? [];

      return list.map((item) {
        final map = Map<String, dynamic>.from(item);

        map['property_name'] = (map['property_id'] as List?)?[1];
        map['unit_name'] = (map['unit_id'] as List?)?[1];

        return Inspection.fromJson(map);
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
