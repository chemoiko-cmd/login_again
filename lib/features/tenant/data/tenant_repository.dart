import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/cubit/auth_state.dart';

class TenantRepository {
  final ApiClient apiClient;
  final AuthCubit authCubit;

  TenantRepository({required this.apiClient, required this.authCubit});

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
      final Response resp = await apiClient.post(
        '/web/dataset/call_kw',
        data: payload,
      );
      final body = resp.data;
      return (body is Map && body['result'] is List)
          ? body['result'] as List
          : const [];
    } on DioException catch (e, st) {
      print(st.toString());
      throw Exception('${e.message}');
    } catch (e, st) {
      print(st.toString());
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> loadDashboard() async {
    final auth = authCubit.state;
    final int uid = auth is Authenticated ? auth.user.id : 0;

    final users = uid > 0
        ? await _searchRead(
            'res.users',
            domain: [
              ['id', '=', uid],
            ],
            fields: const ['name', 'partner_id', 'company_id'],
            limit: 1,
          )
        : const <dynamic>[];

    int? partnerId;
    String unitName = '';
    String propertyName = '';
    int? companyId;
    if (users.isNotEmpty) {
      final u = (users.first as Map).cast<String, dynamic>();
      final p = u['partner_id'];
      if (p is List && p.isNotEmpty && p.first is int)
        partnerId = p.first as int;
      final c = u['company_id'];
      if (c is List && c.isNotEmpty && c.first is int)
        companyId = c.first as int;

      if (partnerId != null) {
        final contracts = await _searchRead(
          'rental.contract',
          domain: [
            ['tenant_id', '=', partnerId],
            ['state', '=', 'active'],
          ],
          fields: const ['unit_id', 'property_id'],
          order: 'start_date desc, id desc',
          limit: 1,
        );
        if (contracts.isNotEmpty) {
          final c0 = (contracts.first as Map).cast<String, dynamic>();
          final u0 = c0['unit_id'];
          if (u0 is List && u0.length >= 2) unitName = (u0[1] ?? '').toString();
          final ppty = c0['property_id'];
          if (ppty is List && ppty.length >= 2)
            propertyName = (ppty[1] ?? '').toString();
        }
      }
    }

    double totalDue = 0.0;
    DateTime? nextDueDate;
    if (partnerId != null) {
      final invoices = await _searchRead(
        'account.move',
        domain: [
          ['partner_id', '=', partnerId],
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
        fields: const ['amount_residual', 'invoice_date_due', 'name'],
        order: 'invoice_date_due asc',
        limit: 200,
      );
      for (final inv in invoices) {
        final m = (inv as Map).cast<String, dynamic>();
        final residual = (m['amount_residual'] as num?)?.toDouble() ?? 0.0;
        totalDue += residual;
        final dueStr = m['invoice_date_due']?.toString();
        if (dueStr != null && dueStr.isNotEmpty) {
          final d = DateTime.tryParse(dueStr);
          if (d != null && (nextDueDate == null || d.isBefore(nextDueDate))) {
            nextDueDate = d;
          }
        }
      }
    }

    String? currencySymbol;
    String? currencyPosition;
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
          final curm = (currencies.first as Map).cast<String, dynamic>();
          currencySymbol = (curm['symbol'] ?? '').toString();
          currencyPosition = (curm['position'] ?? 'before').toString();
        }
      }
    }

    int? daysUntilDue;
    if (nextDueDate != null) {
      final now = DateTime.now();
      final base = DateTime(now.year, now.month, now.day);
      int d = nextDueDate!.difference(base).inDays;
      if (d < 0) d = 0;
      daysUntilDue = d;
    }

    return {
      'userName': (auth is Authenticated) ? (auth.user.name) : '',
      'partnerId': partnerId,
      'currentAmount': totalDue,
      'dueInDays': daysUntilDue,
      'currencySymbol': currencySymbol,
      'currencyPosition': currencyPosition,
      'unitName': unitName,
      'propertyName': propertyName,
    };
  }
}
