import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/cubit/auth_state.dart';

class MaintenanceRequestItem {
  final int id;
  final String name;
  final String state; // open | in_progress | done | cancelled
  final String priority; // '0'..'3'
  final String? unitName;
  final int? unitId;
  final DateTime? createdAt;

  MaintenanceRequestItem({
    required this.id,
    required this.name,
    required this.state,
    required this.priority,
    this.unitName,
    this.unitId,
    this.createdAt,
  });
}

class MaintenanceRepository {
  final ApiClient apiClient;
  final AuthCubit authCubit;

  MaintenanceRepository({required this.apiClient, required this.authCubit});

  Future<List<dynamic>> _searchRead(
    String model, {
    required List<dynamic> domain,
    List<String>? fields,
    int? limit,
    String? order,
  }) async {
    try {
      final payload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': model,
          'method': 'search_read',
          'args': [domain],
          'kwargs': {
            if (fields != null) 'fields': fields,
            if (limit != null) 'limit': limit,
            if (order != null) 'order': order,
          },
        },
      };
      final resp = await apiClient.post('/web/dataset/call_kw', data: payload);
      final body = resp.data;
      if (body is Map && body['result'] is List) return body['result'] as List;
      return const [];
    } on DioException catch (e, st) {
      print(st.toString());
      throw Exception('${e.message}');
    } catch (e, st) {
      print(st.toString());
      throw Exception('Unexpected error: $e');
    }
  }

  Future<dynamic> _callKw(
    String model,
    String method, {
    List<dynamic>? args,
    Map<String, dynamic>? kwargs,
  }) async {
    try {
      final payload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': model,
          'method': method,
          'args': args ?? const [],
          'kwargs': kwargs ?? const {},
        },
      };
      final resp = await apiClient.post('/web/dataset/call_kw', data: payload);
      final body = resp.data;
      if (body is Map && body.containsKey('result')) return body['result'];
      return null;
    } on DioException catch (e, st) {
      print(st.toString());
      throw Exception('${e.message}');
    } catch (e, st) {
      print(st.toString());
      throw Exception('Unexpected error: $e');
    }
  }

  int? _currentPartnerIdCache;

  Future<int?> _currentPartnerId() async {
    if (_currentPartnerIdCache != null) return _currentPartnerIdCache;
    final state = authCubit.state;
    if (state is! Authenticated) return null;
    final login = state.user.username;
    final users = await _searchRead(
      'res.users',
      domain: [
        ['login', '=', login],
      ],
      fields: const ['partner_id'],
      limit: 1,
    );
    if (users.isEmpty) return null;
    final u = (users.first as Map).cast<String, dynamic>();
    final p = u['partner_id'];
    if (p is List && p.isNotEmpty && p.first is int) {
      _currentPartnerIdCache = p.first as int;
      return _currentPartnerIdCache;
    }
    return null;
  }

  Future<List<MaintenanceRequestItem>> listMyRequests() async {
    final partnerId = await _currentPartnerId();
    if (partnerId == null) return [];
    final records = await _searchRead(
      'rental.maintenance.task',
      domain: [
        ['requested_by', '=', partnerId],
      ],
      fields: const ['name', 'state', 'priority', 'unit_id', 'create_date'],
      order: 'create_date desc',
      limit: 200,
    );
    return records.map((e) {
      final m = (e as Map).cast<String, dynamic>();
      final unit = m['unit_id'];
      int? unitId;
      String? unitName;
      if (unit is List && unit.length >= 2) {
        unitId = unit.first as int;
        unitName = unit[1]?.toString();
      }
      final createdStr = (m['create_date'] ?? '').toString();
      DateTime? createdAt;
      if (createdStr.isNotEmpty) {
        createdAt = DateTime.tryParse(createdStr);
      }
      return MaintenanceRequestItem(
        id: (m['id'] as int?) ?? 0,
        name: (m['name'] ?? '').toString(),
        state: (m['state'] ?? 'open').toString(),
        priority: (m['priority'] ?? '1').toString(),
        unitId: unitId,
        unitName: unitName,
        createdAt: createdAt,
      );
    }).toList();
  }

  Future<int> createRequest({required String name, int? unitId}) async {
    final partnerId = await _currentPartnerId();
    final vals = <String, dynamic>{'name': name};
    if (partnerId != null) vals['requested_by'] = partnerId;
    if (unitId != null) {
      vals['unit_id'] = unitId;
      try {
        final units = await _searchRead(
          'rental.unit',
          domain: [
            ['id', '=', unitId],
          ],
          fields: const ['property_id'],
          limit: 1,
        );
        if (units.isNotEmpty) {
          final u = (units.first as Map).cast<String, dynamic>();
          final p = u['property_id'];
          if (p is List && p.isNotEmpty && p.first is int) {
            vals['property_id'] = p.first as int;
          }
        }
      } catch (_) {}
    }
    final res = await _callKw(
      'rental.maintenance.task',
      'create',
      args: [vals],
    );
    if (res is int) return res;
    throw Exception('Unexpected create result: $res');
  }

  Future<void> attachImage({
    required int taskId,
    required List<int> bytes,
    required String filename,
    String? mimetype,
  }) async {
    final String b64 = base64Encode(bytes);
    final vals = <String, dynamic>{
      'name': filename,
      'res_model': 'rental.maintenance.task',
      'res_id': taskId,
      'datas': b64,
      'mimetype': mimetype ?? 'image/jpeg',
    };
    final res = await _callKw('ir.attachment', 'create', args: [vals]);
    if (res is! int) {
      throw Exception('Failed to create attachment: $res');
    }
  }
}
