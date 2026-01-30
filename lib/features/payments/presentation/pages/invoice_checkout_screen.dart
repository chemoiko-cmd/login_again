import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/core/currency/currency_cubit.dart';
import 'package:login_again/core/utils/formatters.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/payments/data/payments_repository.dart';
import 'package:login_again/features/payments/domain/invoice.dart';
import 'package:login_again/features/payments/presentation/pages/payment_method_selection_screen.dart';
import 'package:login_again/features/payments/presentation/pages/payment_processing_screen.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;

class InvoiceCheckoutScreen extends StatefulWidget {
  final List<String> invoiceNames;

  const InvoiceCheckoutScreen({super.key, required this.invoiceNames});

  @override
  State<InvoiceCheckoutScreen> createState() => _InvoiceCheckoutScreenState();
}

class _InvoiceCheckoutScreenState extends State<InvoiceCheckoutScreen> {
  late PaymentsRepository _repo;
  bool _loading = true;
  String? _error;

  List<Invoice> _invoices = [];
  int? _selectedProviderIndex;
  String? _selectedProviderName;

  int? _partnerId;
  int? _currencyId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>();
    _repo = PaymentsRepository(apiClient: auth.apiClient, authCubit: auth);
    _loadData();
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Get partner ID
      final auth = context.read<AuthCubit>().state;
      if (auth is Authenticated) {
        final users = await _repo.searchRead(
          'res.users',
          domain: [
            ['login', '=', auth.user.username],
          ],
          fields: const ['partner_id'],
          limit: 1,
        );

        if (users.isNotEmpty) {
          final partnerData = (users.first as Map)['partner_id'];
          _partnerId = (partnerData is List)
              ? partnerData.first as int
              : partnerData as int;
        }
      }

      // Fetch invoices
      final invoices = await _repo.fetchInvoicesByNames(widget.invoiceNames);

      if (invoices.isEmpty) {
        throw Exception('No invoices found');
      }

      // Get currency from first invoice
      _currencyId = invoices.first.currencyId;

      setState(() {
        _invoices = invoices;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  double get _totalAmount {
    return _invoices.fold(0.0, (sum, inv) => sum + inv.amountResidual);
  }

  Future<void> _selectPaymentMethod() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentMethodSelectionScreen(
          repository: _repo,
          selectedIndex: _selectedProviderIndex,
          onSelected: (index, providerName) {
            setState(() {
              _selectedProviderIndex = index;
              _selectedProviderName = providerName;
            });
          },
        ),
      ),
    );
  }

  Future<void> _proceedToPayment() async {
    if (_selectedProviderIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    if (_partnerId == null || _currencyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing payment information')),
      );
      return;
    }

    final currencySymbol = context.read<CurrencyCubit>().state.symbol;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentProcessingScreen(
          invoices: _invoices,
          providerName: _selectedProviderName ?? 'Payment Provider',
          partnerId: _partnerId!,
          currencyId: _currencyId!,
          currencySymbol: currencySymbol ?? 'KSh',
          onProcessPayment: () async {
            return await _repo.processPayment(
              amount: _totalAmount,
              currencyId: _currencyId!,
              partnerId: _partnerId!,
              providerIndex: _selectedProviderIndex!,
              invoiceIds: _invoices.map((inv) => inv.id).toList(),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<CurrencyCubit>().state.symbol;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), elevation: 0),
      body: Builder(
        builder: (context) {
          if (_loading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              loading.Widgets.showLoader(context);
            });
            return const SizedBox.shrink();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            loading.Widgets.hideLoader(context);
          });

          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load checkout',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      onPressed: _loadData,
                      child: Text(
                        'Retry',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Invoices section
                        Text(
                          'Invoices to Pay',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        ..._invoices.map(
                          (invoice) => _buildInvoiceCard(
                            invoice,
                            currencySymbol ?? 'KSh',
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Payment method section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment Method',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            GradientTextButton(
                              onPressed: _selectPaymentMethod,
                              child: Text(
                                _selectedProviderIndex == null
                                    ? 'Select'
                                    : 'Change',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_selectedProviderIndex != null)
                          _buildPaymentMethodCard()
                        else
                          _buildSelectPaymentMethodCard(),

                        const SizedBox(height: 24),

                        // Summary section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Subtotal',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                  ),
                                  Text(
                                    formatMoney(
                                      _totalAmount,
                                      currencySymbol: currencySymbol,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Processing Fee',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                  ),
                                  Text(
                                    formatMoney(
                                      0,
                                      currencySymbol: currencySymbol,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    formatMoney(
                                      _totalAmount,
                                      currencySymbol: currencySymbol,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      onPressed: _selectedProviderIndex == null
                          ? null
                          : _proceedToPayment,
                      minHeight: 48,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Pay ${formatMoney(_totalAmount, currencySymbol: currencySymbol ?? 'KSh')}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice, String currencySymbol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.receipt_long,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (invoice.invoiceDateDue != null)
                  Text(
                    'Due: ${_formatDate(invoice.invoiceDateDue!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: invoice.isOverdue
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            formatMoney(invoice.amountResidual, currencySymbol: currencySymbol),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.payment, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedProviderName ??
                      'Provider ${_selectedProviderIndex! + 1}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selected payment method',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectPaymentMethodCard() {
    return GestureDetector(
      onTap: _selectPaymentMethod,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.payment, color: Colors.grey.shade600, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Select payment method',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
