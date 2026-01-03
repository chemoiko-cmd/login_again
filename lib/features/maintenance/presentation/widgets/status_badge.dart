import 'package:flutter/material.dart';
import 'package:login_again/styles/colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (status) {
      case 'open':
        label = 'Open';
        bg = AppColors.warning.withOpacity(0.15);
        fg = AppColors.warning;
        break;
      case 'in_progress':
        label = 'In Progress';
        bg = AppColors.secondary.withOpacity(0.15);
        fg = AppColors.secondary;
        break;
      case 'done':
        label = 'Done';
        bg = AppColors.success.withOpacity(0.15);
        fg = AppColors.success;
        break;
      default:
        label = status;
        bg = AppColors.border;
        fg = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
