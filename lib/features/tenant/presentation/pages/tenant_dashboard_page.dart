// =============================================================================
// FILE: lib/features/tenant/presentation/pages/tenant_dashboard_page.dart
// Adapted from bloc_nav_app TenantDashboard: uses this app's AuthCubit/apiClient
// to fetch Odoo data via JSON-RPC and renders a modern tenant dashboard.
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:login_again/core/utils/formatters.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
import 'package:login_again/core/widgets/glass_surface.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;
import 'package:login_again/features/contracts/presentation/widgets/widgets.dart';
import '../widgets/section.dart';
import '../cubit/tenant_dashboard_cubit.dart';
import '../cubit/tenant_dashboard_state.dart';

class TenantDashboardPage extends StatefulWidget {
  const TenantDashboardPage({super.key});

  @override
  State<TenantDashboardPage> createState() => _TenantDashboardPageState();
}

class _TenantDashboardPageState extends State<TenantDashboardPage> {
  String _formatShortDate(String iso) {
    if (iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      loading.Widgets.showLoader(context);
      context.read<TenantDashboardCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return BlocConsumer<TenantDashboardCubit, TenantDashboardState>(
      listener: (context, state) {
        if (!state.loading) {
          loading.Widgets.hideLoader(context);
        }
      },
      builder: (context, state) {
        if (state.loading) {
          return const SizedBox.shrink();
        }
        if (state.error != null) {
          return Center(
            child: Text('Failed to load tenant data\n${state.error}'),
          );
        }
        final data = state.data ?? const {};
        final userName = (data['userName'] ?? '').toString();
        final unitName = (data['unitName'] ?? '').toString();
        final propertyName = (data['propertyName'] ?? '').toString();
        final announcements = state.announcements;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassSurface(
                padding: const EdgeInsets.all(14),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName.isEmpty ? 'Tenant' : capitalizeFirst(userName),
                      style: textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${unitName.isEmpty ? 'Your unit' : unitName} • ${propertyName.isEmpty ? 'Your property' : propertyName}',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions grid
              const SizedBox(height: 12),
              GlassSurface(
                padding: const EdgeInsets.all(12),
                borderRadius: BorderRadius.circular(16),
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _ActionCircle(
                      icon: Icons.build_outlined,
                      label: 'Maintenance ',
                      onTap: () => context.go('/maintenance'),
                      color: Colors.orange,
                    ),
                    _ActionCircle(
                      icon: Icons.description_outlined,
                      label: 'Contract-info',
                      onTap: () => context.go('/contracts'),
                      color: Colors.teal,
                    ),
                    _ActionCircle(
                      icon: Icons.receipt_long,
                      label: 'Receipts',
                      onTap: () => context.go('/pay-rent'),
                      color: Colors.indigo,
                    ),
                    _ActionCircle(
                      icon: Icons.credit_card,
                      label: 'Pay Rent',
                      onTap: () => context.go('/pay-rent'),
                      color: scheme.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Section(
                title: 'Property Announcements',
                trailing: GradientTextButton(
                  onPressed: () => context.go('/announcements'),
                  child: const Text('View all'),
                ),
                children: [
                  if (announcements.isEmpty)
                    Text(
                      'No announcements yet.',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    )
                  else
                    ...announcements.map((a) {
                      final title = (a['title'] ?? '').toString();
                      final property = (a['property_name'] ?? '').toString();
                      final publishedAt = (a['published_at'] ?? '').toString();
                      final subtitleParts = <String>[];
                      if (property.isNotEmpty) subtitleParts.add(property);
                      if (publishedAt.isNotEmpty) {
                        subtitleParts.add(_formatShortDate(publishedAt));
                      }
                      final subtitle = subtitleParts.join(' • ');

                      return ActionTile(
                        title: title,
                        subtitle: subtitle,
                        icon: Icons.notifications,
                      );
                    }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionCircle({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
