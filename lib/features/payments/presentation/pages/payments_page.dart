import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/core/currency/currency_cubit.dart';
import '../../../../styles/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/file_utils.dart';
import '../../domain/payment.dart';
import '../../domain/payment_provider.dart';
import '../cubit/payments_cubit.dart';
import '../cubit/payments_state.dart';
import '../widgets/payment_status_icon.dart';
import 'invoice_checkout_screen.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<PaymentsCubit, PaymentsState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(
                child: Text('Failed to load payments\n${state.error}'),
              );
            }
            final items = state.items;
            final pending = items
                .where((p) => p.status == 'pending' || p.status == 'overdue')
                .toList();
            final history = items.where((p) => p.status == 'paid').toList();
            final totalDue = pending.fold<double>(
              0.0,
              (sum, p) => sum + p.amount,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  if (pending.isNotEmpty)
                    _totalDueCard(context, totalDue, state.processing),

                  if (pending.isNotEmpty) const SizedBox(height: 16),
                  if (pending.isNotEmpty) _pendingSection(context, pending),

                  const SizedBox(height: 16),
                  _historySection(context, history),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _totalDueCard(BuildContext context, double amount, bool processing) {
    final c = context.watch<CurrencyCubit>().state;
    final pendingItems = context.select<PaymentsCubit, List<PaymentItem>>(
      (cubit) => cubit.state.items
          .where((p) => p.status == 'pending' || p.status == 'overdue')
          .toList(),
    );

    Future<void> _handlePayAll() async {
      // Navigate to checkout with all pending invoices
      final invoiceNames = pendingItems.map((p) => p.id).toList();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              InvoiceCheckoutScreen(invoiceNames: invoiceNames),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            const Color.fromARGB(255, 72, 76, 97).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Amount Due',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatMoney(amount, currencySymbol: c.symbol),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: processing ? null : _handlePayAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    processing ? 'Processing...' : 'Pay All',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pendingSection(BuildContext context, List<PaymentItem> pending) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Now',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            for (int i = 0; i < pending.length; i++)
              _pendingCard(context, pending[i], i),
          ],
        ),
      ],
    );
  }

  Widget _pendingCard(BuildContext context, PaymentItem p, int index) {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 60)),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.credit_card, color: AppColors.warning),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.description,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due ${formatDate(p.dueDate)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(p.amount),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      // Navigate to new checkout flow
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              InvoiceCheckoutScreen(invoiceNames: [p.id]),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Pay Now'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historySection(BuildContext context, List<PaymentItem> history) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment History',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (history.isEmpty)
          Text(
            'No payments yet',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < history.length; i++)
                _historyCard(context, history[i], i),
            ],
          ),
      ],
    );
  }

  Widget _historyCard(BuildContext context, PaymentItem p, int index) {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 60)),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          PaymentStatusIcon(status: p.status),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.description,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.paidDate != null ? 'Paid ${formatDate(p.paidDate!)}' : '—',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                formatMoney(p.amount),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  try {
                    // Show loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('⬇️  Downloading...')),
                    );

                    final bytes = await context
                        .read<PaymentsCubit>()
                        .repo
                        .downloadPaymentReceiptByInvoiceName(p.id);

                    final path = await savePdfToDocuments(
                      bytes,
                      'receipt_${p.id.replaceAll('/', '_')}.pdf',
                    );

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Receipt ready')),
                    );

                    await openFile(path);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('❌ Failed: $e')));
                  }
                },
                icon: Icon(Icons.download, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
