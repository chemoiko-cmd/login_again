import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:login_again/features/landlord/presentation/widgets/action_tile.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/core/widgets/glass_surface.dart';
import 'package:login_again/features/landlord/data/models/partner_profile.dart';
import 'package:login_again/features/profile/data/profile_repository.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  Future<PartnerProfile?>? _future;

  void _comingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  void _reload() {
    final auth = context.read<AuthCubit>();
    final authState = auth.state;

    if (authState is Authenticated) {
      final repo = ProfileRepository(apiClient: auth.apiClient);
      _future = repo.fetchPartnerProfile(partnerId: authState.user.partnerId);
    } else {
      _future = Future.value(null);
    }
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final userName = authState is Authenticated ? authState.user.name : '';
    final userRole = authState is Authenticated
        ? authState.user.primaryGroup
        : '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<PartnerProfile?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
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

          if (snap.hasError) {
            return Center(child: Text('Failed to load profile\n${snap.error}'));
          }

          final profile = snap.data;
          final name = (profile?.name ?? userName).trim();
          final email = (profile?.email ?? '').trim();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassSurface(
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    _ProfileAvatar(
                      imageBytes: profile?.imageBytes,
                      fallbackName: name,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'User' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email.isEmpty ? ' ' : email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withValues(alpha: 0.8),
                                ),
                          ),
                          const SizedBox(height: 6),
                          // if (userRole.isNotEmpty)
                          //   Text(
                          //     userRole,
                          //     maxLines: 1,
                          //     overflow: TextOverflow.ellipsis,
                          //     style: Theme.of(context).textTheme.labelSmall
                          //         ?.copyWith(fontWeight: FontWeight.w700),
                          //   ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ActionTile(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                subtitle: 'Update your details',
                onTap: () async {
                  final didSave = await context.push<bool>(
                    '/profile/edit',
                    extra: profile,
                  );
                  if (!mounted) return;
                  if (didSave == true) {
                    setState(_reload);
                  }
                },
              ),
              const SizedBox(height: 12),
              ActionTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Subscription',
                subtitle: 'Manage your subscription',
                onTap: _comingSoon,
              ),

              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final dynamic imageBytes;
  final String fallbackName;

  const _ProfileAvatar({required this.imageBytes, required this.fallbackName});

  String _initials(String name) {
    final parts = name
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;
    if (bytes is List<int> && bytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          Uint8List.fromList(bytes),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      ),
      child: Text(
        _initials(fallbackName),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}
