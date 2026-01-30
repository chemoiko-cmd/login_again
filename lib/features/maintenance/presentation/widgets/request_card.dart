import 'package:flutter/material.dart';
import 'package:login_again/theme/app_theme.dart';
import 'package:login_again/core/widgets/glass_surface.dart';
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

  Color _statusBg(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'open':
        return context.warning.withValues(alpha: 0.15);
      case 'in_progress':
        return scheme.secondary.withValues(alpha: 0.15);
      case 'done':
        return context.success.withValues(alpha: 0.15);
      default:
        return scheme.outline;
    }
  }

  Color _statusFg(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'open':
        return context.warning;
      case 'in_progress':
        return scheme.secondary;
      case 'done':
        return context.success;
      default:
        return scheme.onSurface.withValues(alpha: 0.7);
    }
  }

  Map<String, dynamic> _categoryConfig(BuildContext context, String category) {
    final scheme = Theme.of(context).colorScheme;
    return <String, Map<String, dynamic>>{
          'plumbing': {
            'icon': Icons.build,
            'bg': Colors.blueAccent.withValues(alpha: 0.12),
            'fg': Colors.blue,
          },
          'electrical': {
            'icon': Icons.bolt,
            'bg': Colors.amber.withValues(alpha: 0.12),
            'fg': Colors.amber,
          },
          'hvac': {
            'icon': Icons.thermostat,
            'bg': Colors.cyan.withValues(alpha: 0.12),
            'fg': Colors.cyan,
          },
          'appliance': {
            'icon': Icons.settings,
            'bg': Colors.purple.withValues(alpha: 0.12),
            'fg': Colors.purple,
          },
          'other': {
            'icon': Icons.build,
            'bg': scheme.surface,
            'fg': scheme.onSurface.withValues(alpha: 0.7),
          },
        }[category] ??
        {
          'icon': Icons.build,
          'bg': scheme.surface,
          'fg': scheme.onSurface.withValues(alpha: 0.7),
        };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = _categoryConfig(context, 'other');
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 30)),
      curve: Curves.easeOut,
      child: GlassSurface(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(16),
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
                          color: _statusBg(context, item.state),
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
                            color: _statusFg(context, item.state),
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
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  if (item.createdAt != null)
                    Text(
                      'Submitted ${_fmtShort(item.createdAt!)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
