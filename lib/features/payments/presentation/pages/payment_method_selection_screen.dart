import 'package:flutter/material.dart';
import 'package:login_again/features/payments/domain/provider_with_method.dart';
import 'package:login_again/features/payments/data/payments_repository.dart';
import 'package:login_again/core/widgets/app_loading_indicator.dart';

class PaymentMethodSelectionScreen extends StatefulWidget {
  final PaymentsRepository repository;
  final int? selectedIndex;
  final Function(int index, String providerName) onSelected;

  const PaymentMethodSelectionScreen({
    super.key,
    required this.repository,
    this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<PaymentMethodSelectionScreen> createState() =>
      _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState
    extends State<PaymentMethodSelectionScreen> {
  List<ProviderWithMethod> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final items = await widget.repository.fetchProvidersWithMethods();

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load payment options: $e')),
        );
      }
    }
  }

  Widget _buildPaymentOptionCard(ProviderWithMethod item, int index) {
    final isSelected = widget.selectedIndex == index;
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        widget.onSelected(index, item.providerName);
        Navigator.of(context).pop();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? scheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIcon(item.paymentCode),
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.paymentMethodName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? scheme.primary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.providerName,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  if (item.providerState == 'test') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Test Mode',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: scheme.primary, size: 24)
            else
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

  IconData _getIcon(String? code) {
    switch (code?.toLowerCase()) {
      case 'card':
      case 'stripe':
        return Icons.credit_card;
      case 'bank_transfer':
      case 'wire_transfer':
        return Icons.account_balance;
      case 'mobile_money':
      case 'mpesa':
        return Icons.phone_android;
      case 'paypal':
        return Icons.account_balance_wallet;
      case 'demo':
        return Icons.payments;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Payment Option'), elevation: 0),
      body: _loading
          ? const Center(child: AppLoadingIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose your payment option',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_items.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No payment options available',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    else
                      ..._items.asMap().entries.map(
                        (entry) =>
                            _buildPaymentOptionCard(entry.value, entry.key),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
