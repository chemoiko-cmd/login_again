import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/core/currency/currency_cubit.dart';
import '../../../../styles/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/payments_repository.dart';
import '../../domain/payment.dart';
import '../../domain/payment_provider.dart';
import '../cubit/payments_cubit.dart';
import '../cubit/payments_state.dart';
import '../widgets/payment_status_icon.dart';
import '../../../../core/widgets/app_side_drawer.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  late PaymentsRepository _repo;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>();
    // Use default processor; inject a real payment processor here when available.
    _repo = PaymentsRepository(apiClient: auth.apiClient, authCubit: auth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppSideDrawer(),
      body: SafeArea(
        child: BlocProvider(
          create: (_) => PaymentsCubit(repo: _repo)..load(),
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
              final c = context.watch<CurrencyCubit>().state;

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
                    _methodsSection(context, state.providers),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _totalDueCard(BuildContext context, double amount, bool processing) {
    final c = context.watch<CurrencyCubit>().state;
    final selectedProviderId = context.select<PaymentsCubit, int?>(
      (cubit) => cubit.state.selectedProviderId,
    );
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
                  onPressed: processing
                      ? null
                      : () {
                          if (selectedProviderId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select a payment method first',
                                ),
                              ),
                            );
                            return;
                          }
                          context.read<PaymentsCubit>().payAllPending();
                        },
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
              TextButton(
                onPressed: () => context.read<PaymentsCubit>().pay(p),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: const Text('Pay'),
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

  Widget _methodsSection(
    BuildContext context,
    List<PaymentProvider> providers,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final selectedId = context.select<PaymentsCubit, int?>(
      (cubit) => cubit.state.selectedProviderId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Methods',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Add New'),
            ),
          ],
        ),
        if (providers.isEmpty)
          Text(
            'No payment methods available',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          Column(
            children: [
              for (final p in providers)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Radio<int>(
                            value: p.id,
                            groupValue: selectedId,
                            onChanged: (val) => context
                                .read<PaymentsCubit>()
                                .selectProvider(val),
                          ),
                          Container(
                            width: 40,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              p.code.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.displayAs?.isNotEmpty == true
                                    ? p.displayAs!
                                    : p.name,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                p.code,
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () =>
                            context.read<PaymentsCubit>().selectProvider(p.id),
                        icon: Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
