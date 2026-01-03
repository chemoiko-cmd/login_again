import 'package:flutter/material.dart';
import '../../../../styles/colors.dart';

class PaymentStatusIcon extends StatelessWidget {
  final String status; // 'paid' | 'pending' | 'overdue'
  const PaymentStatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'paid':
        return Icon(Icons.check_circle, size: 20, color: AppColors.success);
      case 'pending':
        return Icon(Icons.schedule, size: 20, color: AppColors.warning);
      case 'overdue':
      default:
        return Icon(Icons.error_outline, size: 20, color: AppColors.error);
    }
  }
}
