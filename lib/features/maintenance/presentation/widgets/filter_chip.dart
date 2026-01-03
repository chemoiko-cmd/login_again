import 'package:flutter/material.dart';
import 'package:login_again/styles/colors.dart';

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
    return ChoiceChip(
      selected: isActive,
      label: Text(label),
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}
