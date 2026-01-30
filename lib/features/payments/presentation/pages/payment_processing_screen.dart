import 'package:flutter/material.dart';
import 'package:login_again/core/utils/formatters.dart';
import 'package:login_again/features/payments/domain/invoice.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
import 'package:login_again/theme/app_theme.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;

class PaymentProcessingScreen extends StatefulWidget {
  final List<Invoice> invoices;
  final String providerName;
  final int partnerId;
  final int currencyId;
  final String currencySymbol;
  final Future<bool> Function() onProcessPayment;

  const PaymentProcessingScreen({
    super.key,
    required this.invoices,
    required this.providerName,
    required this.partnerId,
    required this.currencyId,
    required this.currencySymbol,
    required this.onProcessPayment,
  });

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  bool _processing = false;
  bool _completed = false;
  bool _failed = false;
  String? _errorMessage;

  double get _totalAmount {
    return widget.invoices.fold(0.0, (sum, inv) => sum + inv.amountResidual);
  }

  Future<void> _processPayment() async {
    setState(() {
      _processing = true;
      _failed = false;
      _errorMessage = null;
    });

    try {
      // Simulate processing delay for better UX
      await Future.delayed(const Duration(seconds: 1));

      final success = await widget.onProcessPayment();

      setState(() {
        _processing = false;
        _completed = success;
        _failed = !success;
        if (!success) {
          _errorMessage = 'Payment processing failed. Please try again.';
        }
      });

      if (success) {
        // Navigate to confirmation screen after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PaymentConfirmationScreen(
                invoices: widget.invoices,
                totalAmount: _totalAmount,
                currencySymbol: widget.currencySymbol,
                providerName: widget.providerName,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _processing = false;
        _failed = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-start processing when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPayment();
    });
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_processing) {
        loading.Widgets.showLoader(context);
      } else {
        loading.Widgets.hideLoader(context);
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Payment'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_processing) ...[
                const SizedBox(height: 32),
                Text(
                  'Processing your payment...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please wait while we process your payment',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (_completed) ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: context.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Payment Successful!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.success,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (_failed) ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: scheme.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error, color: scheme.error, size: 48),
                ),
                const SizedBox(height: 32),
                Text(
                  'Payment Failed',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                GradientButton(
                  onPressed: () => Navigator.of(context).pop(),
                  minHeight: 48,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: Text(
                    'Try Again',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              // Payment summary card
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        Text(
                          formatMoney(
                            _totalAmount,
                            currencySymbol: widget.currencySymbol,
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('Payment Provider', widget.providerName),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Invoices',
                      '${widget.invoices.length} invoice${widget.invoices.length > 1 ? 's' : ''}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class PaymentConfirmationScreen extends StatelessWidget {
  final List<Invoice> invoices;
  final double totalAmount;
  final String currencySymbol;
  final String providerName;

  const PaymentConfirmationScreen({
    super.key,
    required this.invoices,
    required this.totalAmount,
    required this.currencySymbol,
    required this.providerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Confirmation'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Success icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: context.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: context.success,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Success message
                    Text(
                      'Payment Successful!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your payment has been processed successfully',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Payment details card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Details',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Total Paid',
                            formatMoney(
                              totalAmount,
                              currencySymbol: currencySymbol,
                            ),
                            valueStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.success,
                            ),
                          ),
                          const Divider(height: 24),
                          _buildDetailRow('Payment Provider', providerName),
                          const SizedBox(height: 12),
                          _buildDetailRow('Date', _formatDate(DateTime.now())),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Reference',
                            'TXN${DateTime.now().millisecondsSinceEpoch}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Invoices paid
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoices Paid (${invoices.length})',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          ...invoices.map(
                            (invoice) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          invoice.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if (invoice.invoiceDateDue != null)
                                          Text(
                                            'Due: ${_formatDate(invoice.invoiceDateDue!)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatMoney(
                                      invoice.amountResidual,
                                      currencySymbol: currencySymbol,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom action buttons
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
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      onPressed: () {
                        // Navigate back to payments list
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      minHeight: 48,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Done',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GradientTextButton(
                    onPressed: () {
                      // TODO: Implement download receipt
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Receipt download feature coming soon'),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.download),
                        SizedBox(width: 8),
                        Text('Download Receipt'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style:
                valueStyle ??
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
