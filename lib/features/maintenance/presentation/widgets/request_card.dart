import 'package:flutter/material.dart';
import 'package:login_again/styles/colors.dart';
import '../../data/maintenance_repository.dart';

class MaintenanceRequestCard extends StatelessWidget {
  final MaintenanceRequestItem item;
  final int index;

  const MaintenanceRequestCard({
    super.key,
    required this.item,
    required this.index,
  });

  String _fmtShort(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'open':
        return AppColors.warning.withOpacity(0.15);
      case 'in_progress':
        return AppColors.secondary.withOpacity(0.15);
      case 'done':
        return AppColors.success.withOpacity(0.15);
      default:
        return AppColors.border;
    }
  }

  Color _statusFg(String status) {
    switch (status) {
      case 'open':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.secondary;
      case 'done':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Map<String, dynamic> _categoryConfig(String category) {
    return <String, Map<String, dynamic>>{
          'plumbing': {
            'icon': Icons.build,
            'bg': Colors.blueAccent.withOpacity(0.12),
            'fg': Colors.blue,
          },
          'electrical': {
            'icon': Icons.bolt,
            'bg': Colors.amber.withOpacity(0.12),
            'fg': Colors.amber,
          },
          'hvac': {
            'icon': Icons.thermostat,
            'bg': Colors.cyan.withOpacity(0.12),
            'fg': Colors.cyan,
          },
          'appliance': {
            'icon': Icons.settings,
            'bg': Colors.purple.withOpacity(0.12),
            'fg': Colors.purple,
          },
          'other': {
            'icon': Icons.build,
            'bg': AppColors.surface,
            'fg': AppColors.textSecondary,
          },
        }[category] ??
        {
          'icon': Icons.build,
          'bg': AppColors.surface,
          'fg': AppColors.textSecondary,
        };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final c = _categoryConfig('other');
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 30)),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c['bg'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              c['icon'] as IconData,
              color: c['fg'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBg(item.state),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.state == 'open'
                            ? 'Open'
                            : item.state == 'in_progress'
                            ? 'In Progress'
                            : item.state == 'done'
                            ? 'Done'
                            : item.state,
                        style: TextStyle(
                          color: _statusFg(item.state),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if ((item.unitName ?? '').isNotEmpty)
                  Text(
                    item.unitName!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                if (item.createdAt != null)
                  Text(
                    'Submitted ${_fmtShort(item.createdAt!)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
