import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';

class CurrencyInfo {
  final String? symbol;
  final String position; // 'before' | 'after'
  const CurrencyInfo({this.symbol, this.position = 'before'});
}

class CurrencyRepository {
  final ApiClient apiClient;
  final AuthCubit authCubit;

  CurrencyRepository({required this.apiClient, required this.authCubit});

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
    final Response resp = await apiClient.post(
      '/web/dataset/call_kw',
      data: payload,
    );
    final body = resp.data;
    return (body is Map && body['result'] is List)
        ? body['result'] as List
        : const [];
  }

  Future<CurrencyInfo> fetchCurrency() async {
    int? companyId;
    final auth = authCubit.state;
    if (auth is Authenticated) {
      final users = await _searchRead(
        'res.users',
        domain: [
          ['login', '=', auth.user.username],
        ],
        fields: const ['company_id'],
        limit: 1,
      );
      if (users.isNotEmpty) {
        final u = (users.first as Map).cast<String, dynamic>();
        final c = u['company_id'];
        if (c is List && c.isNotEmpty && c.first is int)
          companyId = c.first as int;
      }
    }

    String? symbol;
    String position = 'before';

    if (companyId != null) {
      final companies = await _searchRead(
        'res.company',
        domain: [
          ['id', '=', companyId],
        ],
        fields: const ['currency_id'],
        limit: 1,
      );
      int? currencyId;
      if (companies.isNotEmpty) {
        final cm = (companies.first as Map).cast<String, dynamic>();
        final cur = cm['currency_id'];
        if (cur is List && cur.isNotEmpty && cur.first is int)
          currencyId = cur.first as int;
      }
      if (currencyId != null) {
        final currencies = await _searchRead(
          'res.currency',
          domain: [
            ['id', '=', currencyId],
          ],
          fields: const ['symbol', 'position'],
          limit: 1,
        );
        if (currencies.isNotEmpty) {
          final m = (currencies.first as Map).cast<String, dynamic>();
          symbol = (m['symbol'] ?? '').toString();
          position = (m['position'] ?? 'before').toString();
        }
      }
    }

    return CurrencyInfo(symbol: symbol, position: position);
  }
}
