import 'package:flutter/material.dart';

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: primary ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primary ? scheme.primary : scheme.outline,
            ),
            boxShadow: [
              if (primary)
                BoxShadow(
                  color: scheme.primary.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: primary ? scheme.onPrimary : scheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primary ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
