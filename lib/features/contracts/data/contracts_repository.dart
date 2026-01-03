import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/cubit/auth_state.dart';

class ContractDetails {
  final int id;
  final String name;
  final String unitName;
  final String propertyName;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? rentAmount;
  final String? currencySymbol;
  final String state; // active, done, etc.

  ContractDetails({
    required this.id,
    required this.name,
    required this.unitName,
    required this.propertyName,
    required this.startDate,
    required this.endDate,
    required this.rentAmount,
    required this.currencySymbol,
    required this.state,
  });
}

class ContractsRepository {
  final ApiClient apiClient;
  final AuthCubit authCubit;

  ContractsRepository({required this.apiClient, required this.authCubit});

  Future<List<dynamic>> _searchRead(
    String model, {
    required List<dynamic> domain,
    List<String>? fields,
    int? limit,
    String? order,
  }) async {
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
  }

  Future<int?> _currentPartnerId() async {
    final state = authCubit.state;
    if (state is! Authenticated) return null;
    final login = state.user.username;
    final users = await _searchRead(
      'res.users',
      domain: [
        ['login', '=', login],
      ],
      fields: const ['partner_id', 'company_id'],
      limit: 1,
    );
    if (users.isEmpty) return null;
    final u = (users.first as Map).cast<String, dynamic>();
    final p = u['partner_id'];
    if (p is List && p.isNotEmpty && p.first is int) return p.first as int;
    return null;
  }

  Future<String?> _currencySymbolFromId(int currencyId) async {
    final cur = await _searchRead(
      'res.currency',
      domain: [
        ['id', '=', currencyId],
      ],
      fields: const ['symbol'],
      limit: 1,
    );
    if (cur.isNotEmpty) {
      final m = (cur.first as Map).cast<String, dynamic>();
      return (m['symbol'] ?? '').toString();
    }
    return null;
  }

  Future<ContractDetails?> getCurrentContract() async {
    final partnerId = await _currentPartnerId();
    if (partnerId == null) return null;
    final rows = await _searchRead(
      'rental.contract',
      domain: [
        ['tenant_id', '=', partnerId],
        ['state', '=', 'active'],
      ],
      fields: const [
        'name',
        'unit_id',
        'property_id',
        'start_date',
        'end_date',
        'rent_amount',
        'currency_id',
        'state',
      ],
      order: 'start_date desc, id desc',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final m = (rows.first as Map).cast<String, dynamic>();

    String unitName = '';
    final unit = m['unit_id'];
    if (unit is List && unit.length >= 2) unitName = (unit[1] ?? '').toString();

    String propertyName = '';
    final ppty = m['property_id'];
    if (ppty is List && ppty.length >= 2)
      propertyName = (ppty[1] ?? '').toString();

    DateTime? start;
    final s = (m['start_date'] ?? '').toString();
    if (s.isNotEmpty) start = DateTime.tryParse(s);
    DateTime? end;
    final e = (m['end_date'] ?? '').toString();
    if (e.isNotEmpty) end = DateTime.tryParse(e);

    double? rent;
    final r = m['rent_amount'];
    if (r is num) rent = r.toDouble();

    String? currencySymbol;
    final curId = m['currency_id'];
    if (curId is List && curId.isNotEmpty && curId.first is int) {
      currencySymbol = await _currencySymbolFromId(curId.first as int);
    }

    return ContractDetails(
      id: (m['id'] as int?) ?? 0,
      name: (m['name'] ?? '').toString(),
      unitName: unitName,
      propertyName: propertyName,
      startDate: start,
      endDate: end,
      rentAmount: rent,
      currencySymbol: currencySymbol,
      state: (m['state'] ?? '').toString(),
    );
  }

  Future<Uint8List> downloadContractPdf({
    required int contractId,
    String reportExternalId = 'rental_management.report_rental_contract',
  }) async {
    final path = '/report/pdf/$reportExternalId/$contractId';
    final resp = await apiClient.dio.get(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    if (resp.statusCode == 200 && resp.data is List<int>) {
      return Uint8List.fromList(resp.data as List<int>);
    }
    throw Exception(
      'Failed to download contract PDF (status: ${resp.statusCode})',
    );
  }
}
