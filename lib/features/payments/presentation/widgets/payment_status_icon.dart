import 'package:flutter/material.dart';
import 'package:login_again/theme/app_theme.dart';

class PaymentStatusIcon extends StatelessWidget {
  final String status; // 'paid' | 'pending' | 'overdue'
  const PaymentStatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'paid':
        return Icon(Icons.check_circle, size: 20, color: context.success);
      case 'pending':
        return Icon(Icons.schedule, size: 20, color: context.warning);
      case 'overdue':
      default:
        return Icon(Icons.error_outline, size: 20, color: scheme.error);
    }
  }
}
