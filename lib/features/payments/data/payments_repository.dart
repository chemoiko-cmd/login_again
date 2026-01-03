// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/cubit/auth_state.dart';
import '../domain/payment.dart';
import '../domain/payment_provider.dart';

typedef PaymentProcessor = Future<void> Function(PaymentItem payment);

class PaymentsRepository {
  final ApiClient apiClient;
  final AuthCubit authCubit;
  final PaymentProcessor _processor;

  PaymentsRepository({
    required this.apiClient,
    required this.authCubit,
    PaymentProcessor? processor,
  }) : _processor = processor ?? _fakeProcessor;

  static Future<void> _fakeProcessor(PaymentItem payment) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

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
    return (body is Map && body['result'] is List)
        ? body['result'] as List
        : const [];
  }

  Future<List<PaymentItem>> fetchPayments() async {
    try {
      // Get partner ID
      int? partnerId;
      final auth = authCubit.state;
      if (auth is Authenticated) {
        final users = await _searchRead(
          'res.users',
          domain: [
            ['login', '=', auth.user.username],
          ],
          fields: const ['partner_id'],
          limit: 1,
        );

        partnerId =
            (users.isNotEmpty
                        ? (users.first as Map)['partner_id'] as List?
                        : null)
                    ?.first
                as int?;
      }

      if (partnerId == null) return const [];

      // Get invoices
      final moves = await _searchRead(
        'account.move',
        domain: [
          ['partner_id', '=', partnerId],
          [
            'move_type',
            'in',
            ['out_invoice'],
          ],
          ['state', '=', 'posted'],
        ],
        fields: const [
          'name',
          'invoice_date_due',
          'invoice_date',
          'amount_total',
          'amount_residual',
          'payment_state',
        ],
        order: 'invoice_date_due desc',
        limit: 200,
      );

      final now = DateTime.now();

      // Map to PaymentItem
      return moves.map((raw) {
        final m = (raw as Map).cast<String, dynamic>();
        final id = (m['name'] ?? '').toString();
        final total = (m['amount_total'] as num?)?.toDouble() ?? 0.0;
        final residual = (m['amount_residual'] as num?)?.toDouble() ?? 0.0;
        final dueDate =
            DateTime.tryParse(m['invoice_date_due']?.toString() ?? '') ?? now;
        final paid = residual <= 0.0001;
        final status = paid
            ? 'paid'
            : (dueDate.isBefore(DateTime(now.year, now.month, now.day))
                  ? 'overdue'
                  : 'pending');

        return PaymentItem(
          id: id,
          amount: paid ? total : residual,
          dueDate: dueDate,
          paidDate: paid
              ? DateTime.tryParse(m['invoice_date']?.toString() ?? '')
              : null,
          status: status,
          type: 'rent',
          description: id,
        );
      }).toList();
    } catch (e, st) {
      print('Failed to fetch payments: $e\n$st');
      return const [];
    }
  }

  Future<void> pay(PaymentItem payment) async {
    // Delegates to configured processor (e.g., Stripe, Flutterwave, M-Pesa) injected at composition time.
    await _processor(payment);
  }

  Future<Uint8List> downloadPaymentReceiptByInvoiceName(
    String invoiceName,
  ) async {
    try {
      print('📄 Downloading receipt for invoice: $invoiceName');

      // Step 1: Find invoice ID by name
      final invoiceId = await _getInvoiceIdByName(invoiceName);

      // Step 2: Download PDF from portal
      final bytes = await _downloadInvoicePdf(invoiceId);

      print('✅ Receipt downloaded successfully (${bytes.length} bytes)');
      return bytes;
    } catch (e, stackTrace) {
      print('❌ Failed to download receipt for $invoiceName: $e');
      print(stackTrace);
      rethrow; // Let caller handle the error
    }
  }

  /// Find invoice ID by invoice name
  Future<int> _getInvoiceIdByName(String invoiceName) async {
    print('🔍 Searching for invoice: $invoiceName');

    final moves = await _searchRead(
      'account.move',
      domain: [
        ['name', '=', invoiceName],
        ['move_type', '=', 'out_invoice'],
      ],
      fields: const ['id'],
      limit: 1,
    );

    if (moves.isEmpty) {
      throw Exception('Invoice "$invoiceName" not found');
    }

    final invoiceId = (moves.first as Map<String, dynamic>)['id'] as int;
    print('✓ Found invoice ID: $invoiceId');
    return invoiceId;
  }

  /// Download invoice PDF from portal endpoint
  Future<Uint8List> _downloadInvoicePdf(int invoiceId) async {
    print('⬇️  Downloading PDF for invoice ID: $invoiceId');
    print('⬇️  receipt url ${apiClient.baseUrl}/my/invoices/$invoiceId');
    final response = await apiClient.dio.get(
      '/my/invoices/$invoiceId',
      queryParameters: {'report_type': 'pdf', 'download': 'true'},
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Download failed with status ${response.statusCode}');
    }

    if (response.data is! List<int>) {
      throw Exception('Invalid response type: ${response.data.runtimeType}');
    }

    return Uint8List.fromList(response.data as List<int>);
  }

  Future<List<PaymentProvider>> fetchProviders() async {
    // Try modern model first (Odoo 16+): payment.provider
    try {
      List<dynamic> rows = await _searchRead(
        'payment.provider',
        domain: [
          [
            'state',
            'in',
            ['is_published', 'test'],
          ],
        ],
        fields: const ['id', 'name', 'code', 'state'],
        order: 'name asc',
        limit: 100,
      );
      print('Payment provider guys: $rows');

      return rows.map((r) {
        final m = (r as Map).cast<String, dynamic>();
        return PaymentProvider(
          id: (m['id'] as int?) ?? 0,
          name: (m['name'] ?? '').toString(),
          code: (m['code'] ?? '').toString(),
          state: (m['state'] ?? '').toString(),
        );
      }).toList();
    } on Exception catch (e) {
      print('Error fetching payment providers: $e');
      return [];
    }
  }
}
