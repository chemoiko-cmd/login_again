import 'package:flutter/material.dart';
import 'package:login_again/styles/colors.dart';

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? state; // just the string from your Inspection model
  final VoidCallback? onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.state,
    this.onTap,
  });

  /// Badge color based on state string
  Color getBadgeColor(String? state) {
    switch (state) {
      case 'paid':
        return AppColors.success;
      case 'overdue':
        return AppColors.error;
      case 'draft':
      case 'pending':
        return AppColors.warning;
      case 'scheduled':
        return const Color.fromARGB(255, 255, 166, 0);
      case 'in_progress':
        return const Color.fromARGB(255, 0, 122, 255);
      case 'done':
        return Colors.green;
      case 'cancel':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Row(
          children: [
            Expanded(child: Text(title)),
            if (state != null)
              Chip(
                label: Text(
                  state!, // show string as-is
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: getBadgeColor(state),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
