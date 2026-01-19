import 'package:flutter/material.dart';

class MaintenanceFilterChip extends StatelessWidget {
  final String id;
  final String label;
  final bool isActive;
  final ValueChanged<bool> onSelected;

  const MaintenanceFilterChip({
    super.key,
    required this.id,
    required this.label,
    required this.isActive,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      selected: isActive,
      label: Text(label),
      onSelected: onSelected,
      selectedColor: scheme.primary,
      labelStyle: TextStyle(
        color: isActive ? scheme.onPrimary : scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isActive ? scheme.primary : scheme.outline),
      ),
    );
  }
}
