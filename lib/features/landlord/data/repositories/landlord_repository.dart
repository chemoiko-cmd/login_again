import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:typed_data';
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
                ['state', '=', 'vacant'],
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

  Future<Map<String, dynamic>?> createMaintainer({
    required String name,
    String? email,
    String? phone,
    String? street,
    String? imageBase64,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/mobile/landlord/create_maintainer',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'name': name,
            if (email != null) 'email': email,
            if (phone != null) 'phone': phone,
            if (street != null) 'street': street,
            if (imageBase64 != null) 'image_base64': imageBase64,
          },
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final rpcResult = response.data['result'];
      if (rpcResult is! Map) {
        return null;
      }

      final ok = rpcResult['success'] == true;
      if (!ok) {
        final msg = (rpcResult['error'] ?? 'Failed to create maintainer')
            .toString();
        throw Exception(msg);
      }

      final result = rpcResult['result'];
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on DioException catch (e) {
      final msg = e.message ?? _extractOdooErrorMessage(e.response?.data);
      throw Exception(msg);
    } catch (e) {
      rethrow;
    }
  }

  String _extractOdooErrorMessage(dynamic body) {
    try {
      if (body is Map) {
        final error = body['error'];
        if (error is Map) {
          final data = error['data'];
          final name = data is Map ? data['name']?.toString() : null;
          final message = error['message']?.toString();
          final detailMessage = data is Map
              ? data['message']?.toString()
              : null;
          return [name, detailMessage, message]
              .where((e) => (e ?? '').toString().trim().isNotEmpty)
              .map((e) => e.toString())
              .join(': ');
        }
      }
    } catch (_) {}
    return 'Odoo Server Error';
  }

  Future<bool> createProperty({
    required int ownerPartnerId,
    required String name,
    String? code,
    String? street,
    String? city,
  }) async {
    try {
      final vals = <String, dynamic>{
        'owner_id': ownerPartnerId,
        'name': name,
        if (code != null && code.isNotEmpty) 'code': code,
        if (street != null && street.isNotEmpty) 'street': street,
        if (city != null && city.isNotEmpty) 'city': city,
      };

      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.property',
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

  Future<int?> createPropertyReturningId({
    required int ownerPartnerId,
    required String name,
    required double defaultRentAmount,
    required double defaultDepositAmount,
    Uint8List? imageBytes,
    String? code,
    String? street,
    String? city,
  }) async {
    try {
      final vals = <String, dynamic>{
        'owner_id': ownerPartnerId,
        'name': name,
        'default_rent_amount': defaultRentAmount,
        'default_deposit_amount': defaultDepositAmount,
        if (imageBytes != null && imageBytes.isNotEmpty)
          'image_1920': base64Encode(imageBytes),
        if (code != null && code.isNotEmpty) 'code': code,
        if (street != null && street.isNotEmpty) 'street': street,
        if (city != null && city.isNotEmpty) 'city': city,
      };

      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.property',
            'method': 'create',
            'args': [vals],
            'kwargs': {},
          },
          'id': 1,
        },
      );

      final body = resp.data;
      if (body is Map && body['error'] != null) {
        throw Exception(_extractOdooErrorMessage(body));
      }

      final result = body is Map ? body['result'] : null;
      return result is num ? result.toInt() : null;
    } on DioException catch (e, st) {
      print(st.toString());
      return null;
    } catch (e, st) {
      print(st.toString());
      return null;
    }
  }

  Future<int?> _createFloor({
    required int propertyId,
    required int floorNumber,
  }) async {
    try {
      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.floor',
            'method': 'create',
            'args': [
              {
                'name': 'Floor $floorNumber',
                'building_id': propertyId,
                'sequence': floorNumber * 10,
              },
            ],
            'kwargs': {},
          },
          'id': 1,
        },
      );
      final result = resp.data['result'];
      return result is num ? result.toInt() : null;
    } catch (e, st) {
      print(st.toString());
      return null;
    }
  }

  String _unitNameLikeBackend({
    required String propertyName,
    required int floorNumber,
    required int unitNumber,
    String baseName = 'Unit',
  }) {
    final prefixSource = propertyName.trim();
    final prefix = prefixSource.isNotEmpty
        ? prefixSource.substring(0, 1).toUpperCase()
        : '';
    final f = floorNumber.toString().padLeft(2, '0');
    final u = unitNumber.toString().padLeft(2, '0');
    return prefix.isNotEmpty ? '$baseName-$prefix$f$u' : '$baseName-$f$u';
  }

  Future<bool> generateUnitsForProperty({
    required int propertyId,
    required String propertyName,
    required int totalUnits,
  }) async {
    if (totalUnits <= 0) return true;

    try {
      const floorNumber = 1;
      final floorId = await _createFloor(
        propertyId: propertyId,
        floorNumber: floorNumber,
      );
      if (floorId == null) return false;

      final unitsVals = <Map<String, dynamic>>[];
      for (var unitNumber = 1; unitNumber <= totalUnits; unitNumber++) {
        unitsVals.add({
          'name': _unitNameLikeBackend(
            propertyName: propertyName,
            floorNumber: floorNumber,
            unitNumber: unitNumber,
          ),
          'property_id': propertyId,
          'floor_id': floorId,
          'created_from_template': true,
        });
      }

      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.unit',
            'method': 'create',
            'args': [unitsVals],
            'kwargs': {},
          },
          'id': 1,
        },
      );

      final body = resp.data;
      if (body is Map && body['error'] != null) {
        throw Exception(_extractOdooErrorMessage(body));
      }

      final result = body is Map ? body['result'] : null;
      return result != null;
    } catch (e, st) {
      print(st.toString());
      return false;
    }
  }

  Future<Map<String, int?>> _fetchUnitContext(int unitId) async {
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
                ['id', '=', unitId],
              ],
              'fields': ['company_id', 'currency_id'],
              'limit': 1,
            },
          },
          'id': 1,
        },
      );
      final list = (resp.data['result'] as List?) ?? const [];
      if (list.isEmpty) return const {'company_id': null, 'currency_id': null};
      final m = Map<String, dynamic>.from(list.first as Map);
      int? companyId;
      int? currencyId;
      final comp = m['company_id'];
      if (comp is List && comp.isNotEmpty)
        companyId = (comp.first as num).toInt();
      final curr = m['currency_id'];
      if (curr is List && curr.isNotEmpty)
        currencyId = (curr.first as num).toInt();
      return {'company_id': companyId, 'currency_id': currencyId};
    } catch (e) {
      return const {'company_id': null, 'currency_id': null};
    }
  }

  Future<List<Map<String, dynamic>>> fetchProperties({
    required int ownerPartnerId,
  }) async {
    try {
      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.property',
            'method': 'search_read',
            'args': [],
            'kwargs': {
              'domain': [
                ['owner_id', '=', ownerPartnerId],
              ],
              'fields': [
                'name',
                'code',
                'units_count',
                'vacant_count',
                'occupancy_rate',
                'street',
                'city',
                'image_128',
              ],
              'limit': 500,
              'order': 'name',
            },
          },
          'id': 1,
        },
      );
      final list = (resp.data['result'] as List?) ?? [];
      return list.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);

        Uint8List? imageBytes;
        final img = m['image_128'];
        if (img is String && img.trim().isNotEmpty) {
          try {
            imageBytes = base64Decode(img);
          } catch (_) {}
        }
        return {
          'id': (m['id'] as num).toInt(),
          'name': (m['name'] ?? '').toString(),
          'code': (m['code'] ?? '').toString(),
          'units_count': (m['units_count'] as num?)?.toInt() ?? 0,
          'vacant_count': (m['vacant_count'] as num?)?.toInt() ?? 0,
          'occupancy_rate': (m['occupancy_rate'] as num?)?.toDouble() ?? 0.0,
          'street': (m['street'] ?? '').toString(),
          'city': (m['city'] ?? '').toString(),
          'image_bytes': imageBytes,
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

  /// Fetch maintenance partners (for rental.maintenance.task.assigned_to)
  Future<List<Map<String, dynamic>>> fetchMaintenancePartners({
    required int landlordPartnerId,
  }) async {
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
                ['maintenance_landlord_id', '=', landlordPartnerId],
              ],
              'fields': ['name', 'street', 'image_128'],
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
        final street = (m['street'] ?? '').toString().trim();
        final address = street;
        List<int>? avatarBytes;
        final img = m['image_128'];
        if (img is String && img.isNotEmpty) {
          try {
            avatarBytes = base64Decode(img);
          } catch (_) {
            avatarBytes = null;
          }
        }
        return {
          'id': m['id'] as int,
          'name': m['name'] as String? ?? 'Partner',
          'address': address,
          'avatarBytes': avatarBytes,
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

      // Fetch tenant avatars (small image) in one call.
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
                ['id', 'in', tenantIds],
              ],
              'fields': ['image_128'],
              'limit': tenantIds.length,
            },
          },
          'id': 1,
        },
      );

      final partnerList = (partnersResp.data['result'] as List?) ?? [];
      final Map<int, List<int>?> avatarByPartnerId = {};
      for (final e in partnerList) {
        final m = Map<String, dynamic>.from(e as Map);
        final id = (m['id'] as num?)?.toInt();
        if (id == null) continue;
        final img = m['image_128'];
        if (img is String && img.isNotEmpty) {
          try {
            avatarByPartnerId[id] = base64Decode(img);
          } catch (_) {
            avatarByPartnerId[id] = null;
          }
        } else {
          avatarByPartnerId[id] = null;
        }
      }

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
          .map(
            (r) => r.copyWith(
              status: statusForTenant(r.tenantPartnerId),
              avatarBytes: avatarByPartnerId[r.tenantPartnerId],
            ),
          )
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
  Future<List<Map<String, dynamic>>> fetchInspectorPartners({
    required int landlordPartnerId,
  }) async {
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
                ['maintenance_landlord_id', '=', landlordPartnerId],
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

  /// List candidate tenant partners to assign to a unit/contract.
  /// Returns minimal label list: [{id, name}]
  Future<List<Map<String, dynamic>>> fetchTenantPartners() async {
    try {
      final resp = await apiClient.post(
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
                ['is_tenant', '=', true],
              ],
              'fields': ['name', 'tenant_code'],
              'limit': 200,
              'order': 'name',
            },
          },
          'id': 1,
        },
      );
      final list = (resp.data['result'] as List?) ?? [];
      return list.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final code = (m['tenant_code'] as String?)?.trim();
        final name = (m['name'] as String?) ?? 'Partner';
        return {
          'id': (m['id'] as num).toInt(),
          'name': code != null && code.isNotEmpty ? '[$code] $name' : name,
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

  /// List tenant partners scoped to a landlord: tenants that appear in contracts
  /// on properties owned by the given landlord partner.
  Future<List<Map<String, dynamic>>> fetchTenantPartnersForLandlord({
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
              'fields': ['tenant_id'],
              'limit': 500,
              'order': 'id desc',
            },
          },
          'id': 1,
        },
      );

      final rawContracts = (contractsResp.data['result'] as List?) ?? [];
      final tenantIds = <int>{};
      for (final e in rawContracts) {
        final m = Map<String, dynamic>.from(e as Map);
        final tenantTuple = m['tenant_id'] as List?;
        final id = (tenantTuple != null && tenantTuple.isNotEmpty)
            ? (tenantTuple.first as int?)
            : null;
        if (id != null && id > 0) tenantIds.add(id);
      }
      if (tenantIds.isEmpty) return const [];

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
                ['id', 'in', tenantIds.toList()],
                ['is_tenant', '=', true],
              ],
              'fields': ['name', 'tenant_code'],
              'limit': 500,
              'order': 'name',
            },
          },
          'id': 1,
        },
      );

      final list = (partnersResp.data['result'] as List?) ?? [];
      return list.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final code = (m['tenant_code'] as String?)?.trim();
        final name = (m['name'] as String?) ?? 'Tenant';
        return {
          'id': (m['id'] as num).toInt(),
          'name': code != null && code.isNotEmpty ? '[$code] $name' : name,
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

  /// Inspect res.partner model fields to include optional values safely.
  Future<Map<String, dynamic>> fetchPartnerFields() async {
    try {
      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'res.partner',
            'method': 'fields_get',
            'args': [],
            'kwargs': {
              'attributes': ['string', 'type', 'required'],
            },
          },
          'id': 1,
        },
      );
      final result = resp.data['result'];
      if (result is Map) return result.cast<String, dynamic>();
      return const {};
    } catch (e, st) {
      print(st.toString());
      return const {};
    }
  }

  /// Create a minimal customer partner (tenant) with dynamic support for
  /// firstname/lastname when the model exposes them.
  Future<int?> createPartner({
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? mobile,
    Uint8List? imageBytes,
  }) async {
    try {
      final fields = await fetchPartnerFields();
      // Always send a display name. Prefer explicit name, else compose.
      final displayName = (name != null && name.isNotEmpty)
          ? name
          : [
              firstName,
              lastName,
            ].where((s) => (s ?? '').trim().isNotEmpty).join(' ').trim();

      final vals = <String, dynamic>{
        if (displayName.isNotEmpty) 'name': displayName,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
        if (imageBytes != null && imageBytes.isNotEmpty)
          'image_1920': base64Encode(imageBytes),
        // Many DBs mark customers by customer_rank >= 1
        'customer_rank': 1,
        // Ensure partner is flagged as tenant for rental module hooks
        'is_tenant': true,
        // Be explicit; create override also defaults this when is_tenant is true
        'tenant_state': 'active',
      };

      // Map split name fields if supported by the DB schema
      if (firstName != null && firstName.isNotEmpty) {
        if (fields.containsKey('firstname')) {
          vals['firstname'] = firstName;
        } else if (fields.containsKey('first_name')) {
          vals['first_name'] = firstName;
        }
      }
      if (lastName != null && lastName.isNotEmpty) {
        if (fields.containsKey('lastname')) {
          vals['lastname'] = lastName;
        } else if (fields.containsKey('last_name')) {
          vals['last_name'] = lastName;
        }
      }

      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'res.partner',
            'method': 'create',
            'args': [vals],
            'kwargs': {},
          },
          'id': 1,
        },
      );

      final result = resp.data['result'];
      if (result is num) return result.toInt();
      return null;
    } on DioException catch (e, st) {
      print(st.toString());
      return null;
    } catch (e, st) {
      print(st.toString());
      return null;
    }
  }

  /// Inspect rental.contract model fields to include optional values safely.
  Future<Map<String, dynamic>> fetchRentalContractFields() async {
    try {
      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.contract',
            'method': 'fields_get',
            'args': [],
            'kwargs': {
              'attributes': ['string', 'type', 'required'],
            },
          },
          'id': 1,
        },
      );
      final result = resp.data['result'];
      if (result is Map) {
        return result.cast<String, dynamic>();
      }
      return const {};
    } catch (e, st) {
      print(st.toString());
      return const {};
    }
  }

  /// Helper: fetch unit pricing (rent & deposit) to seed contract values.
  Future<Map<String, double>> _fetchUnitPricing(int unitId) async {
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
                ['id', '=', unitId],
              ],
              'fields': ['rent_amount', 'deposit_amount'],
              'limit': 1,
            },
          },
          'id': 1,
        },
      );
      final list = (resp.data['result'] as List?) ?? const [];
      if (list.isEmpty)
        return const {'rent_amount': 0.0, 'deposit_amount': 0.0};
      final m = Map<String, dynamic>.from(list.first as Map);
      return {
        'rent_amount': (m['rent_amount'] as num?)?.toDouble() ?? 0.0,
        'deposit_amount': (m['deposit_amount'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      return const {'rent_amount': 0.0, 'deposit_amount': 0.0};
    }
  }

  Future<Map<String, double>> _fetchPropertyDefaultsForUnit(int unitId) async {
    try {
      // 1) Get property_id from unit
      final unitResp = await apiClient.post(
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
                ['id', '=', unitId],
              ],
              'fields': ['property_id'],
              'limit': 1,
            },
          },
          'id': 1,
        },
      );
      final unitList = (unitResp.data['result'] as List?) ?? const [];
      if (unitList.isEmpty) {
        return const {'rent_amount': 0.0, 'deposit_amount': 0.0};
      }
      final unitMap = Map<String, dynamic>.from(unitList.first as Map);
      final propTuple = unitMap['property_id'] as List?;
      final int? propertyId = (propTuple != null && propTuple.isNotEmpty)
          ? propTuple.first as int
          : null;
      if (propertyId == null) {
        return const {'rent_amount': 0.0, 'deposit_amount': 0.0};
      }

      // 2) Read defaults from property
      final propResp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.property',
            'method': 'search_read',
            'args': [],
            'kwargs': {
              'domain': [
                ['id', '=', propertyId],
              ],
              'fields': ['default_rent_amount', 'default_deposit_amount'],
              'limit': 1,
            },
          },
          'id': 1,
        },
      );
      final propList = (propResp.data['result'] as List?) ?? const [];
      if (propList.isEmpty) {
        return const {'rent_amount': 0.0, 'deposit_amount': 0.0};
      }
      final propMap = Map<String, dynamic>.from(propList.first as Map);
      return {
        'rent_amount':
            (propMap['default_rent_amount'] as num?)?.toDouble() ?? 0.0,
        'deposit_amount':
            (propMap['default_deposit_amount'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      return const {'rent_amount': 0.0, 'deposit_amount': 0.0};
    }
  }

  Future<Map<String, int?>> getUnitCompanyAndCurrency(int unitId) async {
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
                ['id', '=', unitId],
              ],
              'fields': ['company_id', 'currency_id'],
              'limit': 1,
            },
          },
          'id': 1,
        },
      );
      final list = (resp.data['result'] as List?) ?? const [];
      if (list.isEmpty) return const {'company_id': null, 'currency_id': null};
      final m = Map<String, dynamic>.from(list.first as Map);
      int? companyId;
      int? currencyId;
      final comp = m['company_id'];
      if (comp is List && comp.isNotEmpty)
        companyId = (comp.first as num).toInt();
      final curr = m['currency_id'];
      if (curr is List && curr.isNotEmpty)
        currencyId = (curr.first as num).toInt();
      return {'company_id': companyId, 'currency_id': currencyId};
    } catch (e) {
      return const {'company_id': null, 'currency_id': null};
    }
  }

  /// Create a rental.contract record to link a tenant (partner) to a unit.
  /// Uses the backend endpoint that creates and confirms in one transaction.
  Future<bool> createRentalContract({
    required int tenantPartnerId,
    required int unitId,
    required String startDate,
    required String endDate,
    String? name,
    double? rentAmount,
    double? depositAmount,
    String? billingCycle,
    String? contractType,
  }) async {
    try {
      // Ensure mandatory pricing is present - prefer property defaults
      double rent = rentAmount ?? 0.0;
      double deposit = depositAmount ?? 0.0;
      if (rent <= 0.0 || deposit <= 0.0) {
        final prop = await _fetchPropertyDefaultsForUnit(unitId);
        if (rent <= 0.0) rent = prop['rent_amount'] ?? 0.0;
        if (deposit <= 0.0) deposit = prop['deposit_amount'] ?? 0.0;
      }
      // Fallback to unit pricing if property defaults are not set
      if (rent <= 0.0 || deposit <= 0.0) {
        final pricing = await _fetchUnitPricing(unitId);
        if (rent <= 0.0) rent = pricing['rent_amount'] ?? 0.0;
        if (deposit <= 0.0) deposit = pricing['deposit_amount'] ?? 0.0;
      }
      final unitCtx = await getUnitCompanyAndCurrency(unitId);

      // Use the backend endpoint that creates and confirms in one transaction
      final resp = await apiClient.post(
        '/rental/api/v1/contract/create_and_confirm',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'tenant_id': tenantPartnerId,
            'unit_id': unitId,
            'start_date': startDate,
            'end_date': endDate,
            'rent_amount': rent,
            'deposit_amount': deposit,
            if (name != null && name.isNotEmpty) 'name': name,
            'billing_cycle': (billingCycle != null && billingCycle.isNotEmpty)
                ? billingCycle
                : 'monthly',
            'contract_type': (contractType != null && contractType.isNotEmpty)
                ? contractType
                : 'long_term',
            if (unitCtx['company_id'] != null) 'company_id': unitCtx['company_id'],
            if (unitCtx['currency_id'] != null) 'currency_id': unitCtx['currency_id'],
          },
          'id': 1,
        },
      );

      final result = resp.data['result'];
      if (result is Map) {
        final success = result['success'] == true;
        if (!success) {
          final error = result['error'] ?? 'Unknown error';
          print('Contract creation failed: $error');
        }
        return success;
      }
      return false;
    } on DioException catch (e, st) {
      print('DioException creating contract: ${e.message}');
      print(st.toString());
      return false;
    } catch (e, st) {
      print('Exception creating contract: $e');
      print(st.toString());
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
