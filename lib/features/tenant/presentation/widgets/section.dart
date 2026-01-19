import 'package:flutter/material.dart';

class Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  const Section({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
