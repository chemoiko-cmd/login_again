import 'package:dio/dio.dart';
import 'package:login_again/core/api/api_client.dart';

import '../models/maintenance_request_model.dart';

class MaintenanceRepository {
  final ApiClient apiClient;

  MaintenanceRepository({required this.apiClient});

  Future<List<MaintenanceRequestModel>> fetchRequests(int partnerId) async {
    try {
      // Replace with actual Odoo API call
      final payload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': 'rental.maintenance.task',
          'method': 'search_read',
          'args': [],
          'kwargs': {
            'domain': [
              ['requested_by', '=', partnerId],
            ],
            'fields': ['display_name'],
          },
        },
      };

      final resp = await apiClient.post('/web/dataset/call_kw', data: payload);
      final body = resp.data;
      final List rawList =
          (body is Map ? (body['result'] as List?) : null) ?? const [];
      return rawList
          .map((item) => MaintenanceRequestModel.fromMap(item))
          .toList();
    } on DioException catch (e, st) {
      print(st.toString());
      throw Exception('${e.message}');
    } catch (e, st) {
      print(st.toString());
      throw Exception('Unexpected error: $e');
    }
  }
}
