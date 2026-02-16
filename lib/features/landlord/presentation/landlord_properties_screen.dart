import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/landlord/data/repositories/landlord_repository.dart';
import 'package:login_again/core/widgets/glass_surface.dart';
import 'package:login_again/core/widgets/gradient_floating_action_button.dart';
import 'package:login_again/theme/app_theme.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;
import 'dart:typed_data';

class LandlordPropertiesScreen extends StatefulWidget {
  const LandlordPropertiesScreen({super.key});

  @override
  State<LandlordPropertiesScreen> createState() =>
      _LandlordPropertiesScreenState();
}

class _LandlordPropertiesScreenState extends State<LandlordPropertiesScreen> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _properties = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthCubit>().state;
    if (auth is! Authenticated) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = LandlordRepository(
        apiClient: context.read<AuthCubit>().apiClient,
      );
      final list = await repo.fetchProperties(
        ownerPartnerId: auth.user.partnerId,
      );
      if (!mounted) return;
      setState(() {
        _properties = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load properties';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final authState = context.read<AuthCubit>().state;
    final isLandlord = authState is Authenticated && authState.isLandlord;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: Builder(
              builder: (context) {
                if (_loading) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    loading.Widgets.showLoader(context);
                  });
                  return const SizedBox.shrink();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  loading.Widgets.hideLoader(context);
                });

                if (_error != null) {
                  return Center(child: Text(_error!));
                }
                if (_properties.isEmpty) {
                  return const Center(child: Text('No properties found'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final p = _properties[index];
                    final propertyId = (p['id'] as int?) ?? 0;
                    final name = (p['name'] ?? '').toString();
                    final units = (p['units_count'] as int?) ?? 0;
                    final vacant = (p['vacant_count'] as int?) ?? 0;
                    final occ = (p['occupancy_rate'] as double?) ?? 0.0;
                    final Uint8List? imageBytes =
                        p['image_bytes'] as Uint8List?;
                    final addr = [p['street'], p['city']]
                        .where((e) => (e ?? '').toString().trim().isNotEmpty)
                        .map((e) => e.toString())
                        .join(', ');
                    return GlassSurface(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          context.push('/landlord-properties/$propertyId');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: imageBytes != null
                                        ? Image.memory(
                                            imageBytes,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(
                                            Icons.apartment,
                                            color: scheme.outline,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (addr.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: scheme.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        addr,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoPill(
                                      icon: Icons.home_work_outlined,
                                      label: 'Units',
                                      value: '$units',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _InfoPill(
                                      icon: Icons.meeting_room_outlined,
                                      label: 'Vacant',
                                      value: '$vacant',
                                      color: context.success,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _InfoPill(
                                      icon: Icons.person_2_rounded,
                                      label: '',
                                      value: '${occ.toStringAsFixed(0)}%',
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemCount: _properties.length,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isLandlord
          ? GradientFloatingActionButton(
              tooltip: 'Add Property',
              onPressed: () async {
                final result = await context.push<bool>(
                  '/landlord-properties/add',
                );
                if (result == true) {
                  _load();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon, size: 16, color: baseColor),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(color: baseColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: baseColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
