import 'package:flutter/material.dart';
import 'package:login_again/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (status) {
      case 'open':
        label = 'Open';
        bg = context.warning.withOpacity(0.15);
        fg = context.warning;
        break;
      case 'in_progress':
        label = 'In Progress';
        bg = scheme.secondary.withOpacity(0.15);
        fg = scheme.secondary;
        break;
      case 'done':
        label = 'Done';
        bg = context.success.withOpacity(0.15);
        fg = context.success;
        break;
      default:
        label = status;
        bg = scheme.outline;
        fg = scheme.onSurface.withOpacity(0.7);
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
