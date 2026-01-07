import 'package:login_again/core/api/api_client.dart';

import '../models/maintenance_request_model.dart';

class MaintenanceRepository {
  final ApiClient apiClient;

  MaintenanceRepository({required this.apiClient});

  Future<List<MaintenanceRequestModel>> fetchRequests(int partnerId) async {
    // Replace with actual Odoo API call
    final payload = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': 'rental.maintenance.task',
        'method': 'search_read',
        'args': [],
        "kwargs": {
          "domain": [
            ["requested_by", "=", partnerId],
          ],
          "fields": ["display_name"], // optional
        },
      },
    };

    final resp = await apiClient.post('/web/dataset/call_kw', data: payload);
    final body = resp.data;
    print('this is the req; $body');
    final List rawList = body['result'];
    return rawList
        .map((item) => MaintenanceRequestModel.fromMap(item))
        .toList();
  }
}
