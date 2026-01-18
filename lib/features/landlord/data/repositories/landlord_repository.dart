import 'package:dio/dio.dart';
import 'package:login_again/core/api/api_client.dart';
import 'package:login_again/features/landlord/data/models/landlord_inpsections_model.dart';
import 'package:login_again/features/landlord/data/models/landlord_tenant_row.dart';
import 'package:login_again/features/landlord/data/models/partner_profile.dart';
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
    } on DioException catch (e, st) {
      print(st.toString());
      return [];
    } catch (e, st) {
      print(st.toString());
      return [];
    }
  }

  /// Fetch maintenance partners (for rental.maintenance.task.assigned_to)
  Future<List<Map<String, dynamic>>> fetchMaintenancePartners() async {
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

      // Partners whose related users belong to the group
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
              'fields': ['name'],
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
        return {
          'id': m['id'] as int,
          'name': m['name'] as String? ?? 'Partner',
        };
      }).toList();
    } on DioException catch (e, st) {
      print(st.toString());
      return [];
    } catch (e, st) {
      print(st.toString());
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchMaintenanceTasks({
    required int partnerId,
  }) async {
    try {
      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.maintenance.task',
            'method': 'search_read',
            'args': [],
            'kwargs': {
              'domain': [
                ['property_id.owner_id', '=', partnerId],
              ],
              'fields': [
                'name',
                'state',
                'priority',
                'unit_id',
                'assigned_to',
                'create_date',
              ],
              'limit': 200,
              'order': 'create_date desc',
            },
          },
          'id': 1,
        },
      );

      final list = (resp.data['result'] as List?) ?? [];
      return list
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (e, st) {
      print(st.toString());
      return [];
    } catch (e, st) {
      print(st.toString());
      return [];
    }
  }

  Future<bool> createMaintenanceTask({
    required int landlordPartnerId,
    required int unitId,
    required String name,
    int? assignedToPartnerId,
    String? priority,
  }) async {
    try {
      final vals = <String, dynamic>{
        'name': name,
        'unit_id': unitId,
        'requested_by': landlordPartnerId,
        if (assignedToPartnerId != null) 'assigned_to': assignedToPartnerId,
        if (priority != null) 'priority': priority,
      };

      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.maintenance.task',
            'method': 'create',
            'args': [vals],
            'kwargs': {},
          },
          'id': 1,
        },
      );

      return resp.data['result'] != null;
    } on DioException catch (e, st) {
      print(st.toString());
      return false;
    } catch (e, st) {
      print(st.toString());
      return false;
    }
  }

  Future<List<LandlordTenantRow>> fetchTenantsWithStatus({
    required int partnerId,
  }) async {
    try {
      final contractsResp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.contract',
            'method': 'search_read',
            'args': [],
            'kwargs': {
              'domain': [
                ['property_id.owner_id', '=', partnerId],
                ['state', '=', 'active'],
              ],
              'fields': ['name', 'tenant_id', 'unit_id', 'property_id'],
              'limit': 500,
              'order': 'id desc',
            },
          },
          'id': 1,
        },
      );

      final rawContracts = (contractsResp.data['result'] as List?) ?? [];
      if (rawContracts.isEmpty) return const [];

      final rows = rawContracts.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final tenantTuple = m['tenant_id'] as List?;
        final unitTuple = m['unit_id'] as List?;
        final propertyTuple = m['property_id'] as List?;

        final tenantPartnerId = (tenantTuple != null && tenantTuple.isNotEmpty)
            ? (tenantTuple.first as int?)
            : null;

        return LandlordTenantRow(
          contractId: (m['id'] as int?) ?? 0,
          contractName: (m['name'] ?? '').toString(),
          tenantPartnerId: tenantPartnerId ?? 0,
          tenantName: tenantTuple != null && tenantTuple.length > 1
              ? (tenantTuple[1] ?? '').toString()
              : 'Tenant',
          propertyName: propertyTuple != null && propertyTuple.length > 1
              ? (propertyTuple[1] ?? '').toString()
              : 'Property',
          unitName: unitTuple != null && unitTuple.length > 1
              ? (unitTuple[1] ?? '').toString()
              : 'Unit',
          status: null,
        );
      }).toList();

      final tenantIds = rows
          .map((r) => r.tenantPartnerId)
          .where((id) => id > 0)
          .toSet()
          .toList();

      if (tenantIds.isEmpty) return rows;

      // Fetch ALL unpaid/partial invoices for all tenants in one call.
      final invoicesResp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'account.move',
            'method': 'search_read',
            'args': [],
            'kwargs': {
              'domain': [
                ['partner_id', 'in', tenantIds],
                [
                  'move_type',
                  'in',
                  ['out_invoice'],
                ],
                ['state', '=', 'posted'],
                [
                  'payment_state',
                  'in',
                  ['not_paid', 'partial'],
                ],
              ],
              'fields': ['partner_id', 'amount_residual', 'invoice_date_due'],
              'limit': 2000,
              'order': 'invoice_date_due asc, id asc',
            },
          },
          'id': 1,
        },
      );

      final rawInvoices = (invoicesResp.data['result'] as List?) ?? [];
      final Map<int, DateTime?> earliestDueByTenant = {};

      for (final inv in rawInvoices) {
        final m = (inv as Map).cast<String, dynamic>();
        final partnerTuple = m['partner_id'] as List?;
        final tenantId = (partnerTuple != null && partnerTuple.isNotEmpty)
            ? (partnerTuple.first as int?)
            : null;
        if (tenantId == null) continue;

        final residual = (m['amount_residual'] as num?)?.toDouble() ?? 0.0;
        if (residual <= 0.0001) continue;

        final dueStr = m['invoice_date_due']?.toString();
        final due = (dueStr != null && dueStr.isNotEmpty)
            ? DateTime.tryParse(dueStr)
            : null;
        if (due == null) {
          earliestDueByTenant.putIfAbsent(tenantId, () => null);
          continue;
        }

        final existing = earliestDueByTenant[tenantId];
        if (existing == null || due.isBefore(existing)) {
          earliestDueByTenant[tenantId] = due;
        }
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      String statusForTenant(int tenantId) {
        final due = earliestDueByTenant[tenantId];
        if (!earliestDueByTenant.containsKey(tenantId)) return 'paid';
        if (due == null) return 'pending';
        return due.isBefore(today) ? 'overdue' : 'pending';
      }

      return rows
          .map((r) => r.copyWith(status: statusForTenant(r.tenantPartnerId)))
          .toList();
    } on DioException catch (e, st) {
      print(st.toString());
      return const [];
    } catch (e, st) {
      print(st.toString());
      return const [];
    }
  }

  Future<PartnerProfile?> fetchPartnerProfile({required int partnerId}) async {
    try {
      final payload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': 'res.partner',
          'method': 'search_read',
          'args': [
            [
              ['id', '=', partnerId],
            ],
          ],
          'kwargs': {
            'fields': [
              'id',
              'name',
              'email',
              'email_normalized',
              'image_128',
              'phone',
              'mobile',
              'street',
              'city',
              'country_id',
            ],
            'limit': 1,
          },
        },
        'id': 1,
      };

      print('fetchPartnerProfile partnerId=$partnerId payload=$payload');

      final resp = await apiClient.post('/web/dataset/call_kw', data: payload);

      final list = (resp.data['result'] as List?) ?? [];
      print(
        'fetchPartnerProfile result count=${list.length} first=${list.isNotEmpty ? list.first : null}',
      );
      if (list.isEmpty) return null;
      final m = Map<String, dynamic>.from(list.first as Map);
      return PartnerProfile.fromOdoo(m);
    } on DioException catch (e, st) {
      print(st.toString());
      throw Exception('${e.message}');
    } catch (e, st) {
      print(st.toString());
      throw Exception('Unexpected error: $e');
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
    } on DioException catch (e, st) {
      print(st.toString());
      return [];
    } catch (e, st) {
      print(st.toString());
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
    } on DioException catch (e, st) {
      print(st.toString());
      return [];
    } catch (e, st) {
      print(st.toString());
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

      // Fetch pending approvals (expenses in submitted state) via RPC
      int pendingApprovals = 0;
      if (partnerId != null) {
        try {
          pendingApprovals = await fetchSubmittedExpensesCount(partnerId);
        } catch (e) {
          print('Failed to fetch submitted expenses count: $e');
        }
      }

      // 3) Map to model
      return LandlordMetricsModel(
        totalUnits: totalUnits,
        occupiedUnits: occupiedUnits,
        occupancyRate: occupancyRate,
        totalRentCollected: totalRentCollected,
        totalRentDue: totalRentDue,
        outstanding: outstanding,
        openMaintenanceTasks: openMaintenanceTasks,
        pendingApprovals: pendingApprovals,
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

  /// Simple helper: count expenses in 'submitted' state for this landlord's properties.
  Future<int> fetchSubmittedExpensesCount(int partnerId) async {
    try {
      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.expense',
            'method': 'search_count',
            'args': [
              [
                ['state', '=', 'submitted'],
                ['property_id.owner_id', '=', partnerId],
              ],
            ],
            'kwargs': {},
          },
          'id': 1,
        },
      );

      final result = resp.data['result'];
      if (result is num) {
        return result.toInt();
      }
      return 0;
    } catch (e) {
      print('Error fetching submitted expenses count: $e');
      return 0;
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
    } on DioException catch (e, st) {
      print(st.toString());
      return [];
    } catch (e, st) {
      print(st.toString());
      return [];
    }
  }
}
