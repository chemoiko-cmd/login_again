import 'package:dio/dio.dart';
import 'package:login_again/core/api/api_client.dart';

class MaintainerRepository {
  final ApiClient apiClient;
  MaintainerRepository({required this.apiClient});

  Future<List<Map<String, dynamic>>> fetchAssignedTasks({
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
                ['assigned_to', '=', partnerId],
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
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> updateTaskState({
    required int taskId,
    required String state,
  }) async {
    try {
      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.maintenance.task',
            'method': 'write',
            'args': [
              [taskId],
              {'state': state},
            ],
            'kwargs': {},
          },
          'id': 1,
        },
      );
      return resp.data['result'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAssignedInspections({
    required int userId,
  }) async {
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
                ['inspector_id', '=', userId],
              ],
              'fields': [
                'name',
                'state',
                'date',
                'unit_id',
                'contract_id',
                'condition_notes',
                'maintenance_required',
                'maintenance_description',
              ],
              'limit': 200,
              'order': 'date desc, id desc',
            },
          },
          'id': 1,
        },
      );
      final list = (resp.data['result'] as List?) ?? [];
      return list
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> updateInspectionState({
    required int inspectionId,
    required String state,
  }) async {
    try {
      final resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'rental.inspection',
            'method': 'write',
            'args': [
              [inspectionId],
              {'state': state},
            ],
            'kwargs': {},
          },
          'id': 1,
        },
      );
      return resp.data['result'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateInspectionDetails({
    required int inspectionId,
    required bool maintenanceRequired,
    required String conditionNotes,
    String? maintenanceDescription,
    String? state,
  }) async {
    try {
      final resp = await apiClient
          .post(
            '/web/dataset/call_kw',
            data: {
              'jsonrpc': '2.0',
              'method': 'call',
              'params': {
                'model': 'rental.inspection',
                'method': 'write',
                'args': [
                  [inspectionId],
                  {
                    if (state != null) 'state': state,
                    'maintenance_required': maintenanceRequired,
                    'condition_notes': conditionNotes,
                    if (maintenanceDescription != null)
                      'maintenance_description': maintenanceDescription,
                  },
                ],
                'kwargs': {},
              },
              'id': 1,
            },
          )
          .timeout(const Duration(seconds: 20));
      return resp.data['result'] == true;
    } catch (_) {
      return false;
    }
  }
}
