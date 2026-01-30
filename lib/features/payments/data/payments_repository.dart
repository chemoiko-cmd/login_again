// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/cubit/auth_state.dart';
import '../domain/payment.dart';
import '../domain/payment_provider.dart';
import '../domain/payment_transaction.dart';
import '../domain/payment_method.dart';
import '../domain/invoice.dart';
import '../domain/provider_with_method.dart';

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

  Future<int?> _currentPartnerId() async {
    final auth = authCubit.state;
    if (auth is! Authenticated) return null;

    final existingPartnerId = auth.user.partnerId;
    if (existingPartnerId > 0) {
      return existingPartnerId;
    }

    final uid = auth.user.id;
    final users = await searchRead(
      'res.users',
      domain: [
        ['id', '=', uid],
      ],
      fields: const ['partner_id'],
      limit: 1,
    );

    final partner = (users.isNotEmpty
        ? (users.first as Map)['partner_id'] as List?
        : null);
    final id = partner?.isNotEmpty == true ? partner!.first : null;
    return id is int ? id : null;
  }

  Future<List<dynamic>> searchRead(
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

  Future<List<PaymentItem>> fetchPayments() async {
    try {
      final partnerId = await _currentPartnerId();

      if (partnerId == null) return const [];

      // Get unpaid invoices
      final invoices = await searchRead(
        'account.move',
        domain: [
          ['partner_id', '=', partnerId],
          ['move_type', '=', 'out_invoice'],
          ['state', '=', 'posted'],
          ['payment_state', '!=', 'paid'],
        ],
        fields: const [
          'id',
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

      // Get ALL payment transactions for this partner (any state)
      final transactions = await searchRead(
        'payment.transaction',
        domain: [
          ['partner_id', '=', partnerId],
        ],
        fields: const ['reference', 'amount', 'invoice_ids', 'state'],
        order: 'create_date desc',
        limit: 200,
      );

      // Build map of invoice_id -> transaction state
      final invoiceToTxnState = <int, String>{};
      for (final txn in transactions) {
        final txnMap = txn as Map<String, dynamic>;
        final txnState = (txnMap['state'] ?? '').toString();
        final invoiceIds = txnMap['invoice_ids'] as List?;

        if (invoiceIds != null && invoiceIds.isNotEmpty) {
          for (final invId in invoiceIds) {
            final actualId = invId is int ? invId : null;
            if (actualId != null && !invoiceToTxnState.containsKey(actualId)) {
              // Store the first transaction state found for this invoice
              invoiceToTxnState[actualId] = txnState;
            }
          }
        }
      }

      final now = DateTime.now();
      final results = <PaymentItem>[];

      // Process each invoice
      for (final raw in invoices) {
        final inv = raw as Map<String, dynamic>;
        final invoiceId = inv['id'] as int;
        final txnState = invoiceToTxnState[invoiceId];

        // Only show if: no transaction OR transaction is in draft state
        if (txnState == null || txnState == 'draft') {
          final name = (inv['name'] ?? '').toString();
          final total = (inv['amount_total'] as num?)?.toDouble() ?? 0.0;
          final residual = (inv['amount_residual'] as num?)?.toDouble() ?? 0.0;
          final dueDate =
              DateTime.tryParse(inv['invoice_date_due']?.toString() ?? '') ??
              now;
          final paid = residual <= 0.0001;
          final status = paid
              ? 'paid'
              : (dueDate.isBefore(DateTime(now.year, now.month, now.day))
                    ? 'overdue'
                    : 'pending');

          results.add(
            PaymentItem(
              id: name,
              amount: paid ? total : residual,
              dueDate: dueDate,
              paidDate: paid
                  ? DateTime.tryParse(inv['invoice_date']?.toString() ?? '')
                  : null,
              status: status,
              type: 'rent',
              description: name,
            ),
          );
        }
      }

      return results;
    } catch (e, st) {
      print('Failed to fetch payments: $e\n$st');
      return const [];
    }
  }

  Future<List<PaymentItem>> fetchPaymentHistory() async {
    try {
      final partnerId = await _currentPartnerId();

      if (partnerId == null) return const [];

      // Get PAID invoices only
      final invoices = await searchRead(
        'account.move',
        domain: [
          ['partner_id', '=', partnerId],
          ['move_type', '=', 'out_invoice'],
          ['state', '=', 'posted'],
          ['payment_state', '=', 'paid'],
        ],
        fields: const [
          'id',
          'name',
          'invoice_date_due',
          'invoice_date',
          'amount_total',
          'amount_residual',
          'payment_state',
        ],
        order: 'invoice_date desc',
        limit: 200,
      );

      final results = <PaymentItem>[];
      final now = DateTime.now();

      // Process each paid invoice
      for (final raw in invoices) {
        final inv = raw as Map<String, dynamic>;
        final name = (inv['name'] ?? '').toString();
        final total = (inv['amount_total'] as num?)?.toDouble() ?? 0.0;
        final dueDate =
            DateTime.tryParse(inv['invoice_date_due']?.toString() ?? '') ?? now;
        final paidDate = DateTime.tryParse(
          inv['invoice_date']?.toString() ?? '',
        );

        results.add(
          PaymentItem(
            id: name,
            amount: total,
            dueDate: dueDate,
            paidDate: paidDate,
            status: 'paid',
            type: 'rent',
            description: name,
          ),
        );
      }

      return results;
    } catch (e, st) {
      print('Failed to fetch payment history: $e\n$st');
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

    final moves = await searchRead(
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

  /// Fetch providers with their payment methods from the API
  Future<List<ProviderWithMethod>> fetchProvidersWithMethods() async {
    try {
      print('🔍 Fetching payment providers...');

      final response = await apiClient.post(
        '/rental/api/v1/payment/providers',
        data: {},
      );
      final data = response.data as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      final providersList = result?['providers'] as List<dynamic>? ?? [];

      final providers = providersList
          .map((p) => ProviderWithMethod.fromJson(p as Map<String, dynamic>))
          .toList();

      print('✅ Got ${providers.length} provider-method combinations');
      return providers;
    } on DioException catch (e, st) {
      print(st.toString());
      print('❌ Error fetching providers: ${e.message}');
      return [];
    } catch (e, st) {
      print(st.toString());
      print('❌ Error fetching providers: $e');
      return [];
    }
  }

  /// Get unique providers from the list
  Future<List<PaymentProvider>> fetchProviders() async {
    try {
      final items = await fetchProvidersWithMethods();
      final seen = <int>{};
      final providers = <PaymentProvider>[];

      for (final item in items) {
        if (!seen.contains(item.providerId)) {
          seen.add(item.providerId);
          providers.add(
            PaymentProvider(
              id: item.providerId,
              name: item.providerName,
              code: item.providerCode,
              state: item.providerState,
            ),
          );
        }
      }
      return providers;
    } on DioException catch (e, st) {
      print(st.toString());
      print('Error fetching payment providers: ${e.message}');
      return [];
    } catch (e, st) {
      print(st.toString());
      print('Error fetching payment providers: $e');
      return [];
    }
  }

  /// Get payment methods for a specific provider
  Future<List<PaymentMethod>> fetchPaymentMethods(int providerId) async {
    try {
      final items = await fetchProvidersWithMethods();
      return items
          .where((item) => item.providerId == providerId)
          .map(
            (item) => PaymentMethod(
              id: item.paymentMethodId,
              name: item.paymentMethodName,
              code: item.paymentCode,
              providerId: item.providerId,
              providerName: item.providerName,
              active: true,
            ),
          )
          .toList();
    } on DioException catch (e, st) {
      print(st.toString());
      print('Error fetching payment methods: ${e.message}');
      return [];
    } catch (e, st) {
      print(st.toString());
      print('Error fetching payment methods: $e');
      return [];
    }
  }

  /// Fetch invoice details by ID
  Future<Invoice?> fetchInvoice(int invoiceId) async {
    try {
      final rows = await searchRead(
        'account.move',
        domain: [
          ['id', '=', invoiceId],
        ],
        fields: const [
          'id',
          'name',
          'amount_total',
          'amount_residual',
          'payment_state',
          'invoice_date',
          'invoice_date_due',
          'state',
          'move_type',
          'partner_id',
          'currency_id',
        ],
        limit: 1,
      );

      if (rows.isEmpty) return null;
      return Invoice.fromJson((rows.first as Map).cast<String, dynamic>());
    } on DioException catch (e, st) {
      print(st.toString());
      print('Error fetching invoice: ${e.message}');
      return null;
    } catch (e, st) {
      print(st.toString());
      print('Error fetching invoice: $e');
      return null;
    }
  }

  /// Fetch invoices by name
  Future<List<Invoice>> fetchInvoicesByNames(List<String> invoiceNames) async {
    try {
      final rows = await searchRead(
        'account.move',
        domain: [
          ['name', 'in', invoiceNames],
          ['state', '=', 'posted'],
        ],
        fields: const [
          'id',
          'name',
          'amount_total',
          'amount_residual',
          'payment_state',
          'invoice_date',
          'invoice_date_due',
          'state',
          'move_type',
          'partner_id',
          'currency_id',
        ],
        order: 'invoice_date_due asc',
      );

      return rows.map((r) {
        return Invoice.fromJson((r as Map).cast<String, dynamic>());
      }).toList();
    } on DioException catch (e, st) {
      print(st.toString());
      print('Error fetching invoices: ${e.message}');
      return [];
    } catch (e, st) {
      print(st.toString());
      print('Error fetching invoices: $e');
      return [];
    }
  }

  /// Create a payment transaction
  Future<int?> createPaymentTransaction(PaymentTransaction transaction) async {
    try {
      final payload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': 'payment.transaction',
          'method': 'create',
          'args': [transaction.toJson()],
          'kwargs': {},
        },
        'id': DateTime.now().millisecondsSinceEpoch,
      };

      print('Creating payment transaction: $payload');
      final resp = await apiClient.post('/web/dataset/call_kw', data: payload);
      final body = resp.data;

      if (body is Map && body['result'] != null) {
        final transactionId = body['result'] as int;
        print('✅ Payment transaction created with ID: $transactionId');
        return transactionId;
      }

      return null;
    } on DioException catch (e, st) {
      print(st.toString());
      throw Exception('${e.message}');
    } catch (e, st) {
      print(st.toString());
      throw Exception('Unexpected error: $e');
    }
  }

  /// Set payment transaction as done (simulate successful payment in demo mode)
  Future<bool> setPaymentTransactionDone(int transactionId) async {
    try {
      final payload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': 'payment.transaction',
          'method': 'action_demo_set_done',
          'args': [
            [transactionId],
          ],
          'kwargs': {},
        },
        'id': DateTime.now().millisecondsSinceEpoch,
      };

      print('Setting payment transaction $transactionId as done: $payload');
      final resp = await apiClient.post('/web/dataset/call_kw', data: payload);
      final body = resp.data;

      print('📥 Set done response: $body');

      // Success is indicated by absence of error key
      if (body is Map && !body.containsKey('error')) {
        print('✅ Payment transaction $transactionId set as done');
        return true;
      }

      // If there's an error, extract and log it
      if (body is Map && body['error'] != null) {
        final error = body['error'];
        print('❌ Error setting transaction as done: $error');
      }

      return false;
    } on DioException catch (e, st) {
      print(st.toString());
      throw Exception('${e.message}');
    } catch (e, st) {
      print(st.toString());
      throw Exception('Unexpected error: $e');
    }
  }

  /// Complete payment flow: create transaction and set as done
  Future<bool> processPayment({
    required double amount,
    required int currencyId,
    required int partnerId,
    required int providerIndex,
    required List<int> invoiceIds,
  }) async {
    try {
      // Fetch provider details using index
      final providers = await fetchProvidersWithMethods();
      if (providerIndex < 0 || providerIndex >= providers.length) {
        throw Exception('Invalid provider index: $providerIndex');
      }

      final selectedProvider = providers[providerIndex];

      // Step 1: Create payment transaction
      final transaction = PaymentTransaction(
        amount: amount,
        currencyId: currencyId,
        partnerId: partnerId,
        providerId: selectedProvider.providerId,
        paymentMethodId: selectedProvider.paymentMethodId,
        invoiceIds: invoiceIds,
        operation: 'online_direct',
      );

      final transactionId = await createPaymentTransaction(transaction);
      if (transactionId == null) {
        throw Exception('Failed to create payment transaction');
      }

      // Step 2: Set transaction as done
      final success = await setPaymentTransactionDone(transactionId);
      return success;
    } on DioException catch (e, st) {
      print(st.toString());
      throw Exception('${e.message}');
    } catch (e, st) {
      print(st.toString());
      throw Exception('Unexpected error: $e');
    }
  }
}
