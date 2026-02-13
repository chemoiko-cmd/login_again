import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:login_again/core/widgets/gradient_floating_action_button.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/landlord/data/repositories/landlord_repository.dart';
import 'package:login_again/features/landlord/presentation/widgets/action_tile.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;

class LandlordMaintainersScreen extends StatefulWidget {
  const LandlordMaintainersScreen({super.key});

  @override
  State<LandlordMaintainersScreen> createState() =>
      _LandlordMaintainersScreenState();
}

class _LandlordMaintainersScreenState
    extends State<LandlordMaintainersScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated || !authState.isLandlord) {
      return const [];
    }

    final repo =
        LandlordRepository(apiClient: context.read<AuthCubit>().apiClient);

    try {
      // All maintenance partners for this landlord
      final list = await repo.fetchMaintenancePartners(
        landlordPartnerId: authState.user.partnerId,
      );
      return list;
    } catch (e) {
      return const [];
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (isLoading) {
                  loading.Widgets.showLoader(context);
                } else {
                  loading.Widgets.hideLoader(context);
                }
              });

              if (isLoading) {
                return const SizedBox.shrink();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Failed to load maintainers',
                    style: textTheme.bodyMedium,
                  ),
                );
              }

              final items = snapshot.data ?? const [];

              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.engineering_outlined,
                          size: 64,
                          color: scheme.onSurface.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No maintainers yet',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first maintainer to start assigning maintenance tasks.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final m = items[index];
                  final name = (m['name'] ?? '').toString();
                  final subtitle = (m['address'] ?? '').toString();
                  final avatarBytes = m['avatarBytes'] as List<int>?;

                  return ActionTile(
                    icon: Icons.engineering_outlined,
                    avatarBytes: avatarBytes,
                    title: name.isEmpty ? 'Maintainer' : name,
                    subtitle:
                        subtitle.isEmpty ? 'Maintenance partner' : subtitle,
                    state: null,
                    onTap: null,
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: GradientFloatingActionButton(
        onPressed: () => context.go('/landlord-maintainers/add'),
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }
}

