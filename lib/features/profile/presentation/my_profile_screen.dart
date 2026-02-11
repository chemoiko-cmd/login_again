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
    print('\n${"=" * 60}');
    print('ℹ️  _comingSoon called');
    print('${"=" * 60}');

    try {
      if (!mounted) {
        print('⚠️  Widget not mounted - cannot show snackbar');
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Coming soon')));
      print('✅ Coming soon snackbar shown');
    } catch (e, stackTrace) {
      print('\n${"!" * 60}');
      print('❌ ERROR in _comingSoon');
      print('${"!" * 60}');
      print('Error: $e');
      print('Type: ${e.runtimeType}');
      print('\nStack Trace:');
      print(stackTrace);
      print('${"!" * 60}\n');
    }
    print('${"=" * 60}\n');
  }

  void _reload() {
    print('\n${"=" * 60}');
    print('🔄 _reload STARTED');
    print('${"=" * 60}');

    try {
      print('🔍 Step 1: Get AuthCubit');
      final auth = context.read<AuthCubit>();
      print('   ✅ AuthCubit obtained');

      print('🔍 Step 2: Get auth state');
      final authState = auth.state;
      print('   ✅ Auth state obtained');
      print('   - Type: ${authState.runtimeType}');
      print('   - Is Authenticated: ${authState is Authenticated}');

      if (authState is Authenticated) {
        print('🔍 Step 3: User is authenticated');
        print('   - User ID: ${authState.user.id}');
        print('   - Partner ID: ${authState.user.partnerId}');
        print('   - User name: ${authState.user.name}');

        print('🔍 Step 4: Create ProfileRepository');
        final repo = ProfileRepository(apiClient: auth.apiClient);
        print('   ✅ Repository created');

        print('🔍 Step 5: Fetch partner profile');
        _future = repo.fetchPartnerProfile(partnerId: authState.user.partnerId);
        print(
          '   ✅ Future created for partner ID: ${authState.user.partnerId}',
        );
      } else {
        print('⚠️  User not authenticated - setting future to null');
        _future = Future.value(null);
      }

      print('✅ _reload COMPLETED');
    } catch (e, stackTrace) {
      print('\n${"!" * 60}');
      print('❌ ERROR in _reload');
      print('${"!" * 60}');
      print('Error: $e');
      print('Type: ${e.runtimeType}');
      print('\nStack Trace:');
      print(stackTrace);
      print('${"!" * 60}\n');

      _future = Future.error(e);
    }
    print('${"=" * 60}\n');
  }

  @override
  void initState() {
    super.initState();
    print('\n${"=" * 60}');
    print('🚀 MyProfileScreen.initState STARTED');
    print('${"=" * 60}');

    try {
      _reload();
      print('✅ initState COMPLETED');
    } catch (e, stackTrace) {
      print('\n${"!" * 60}');
      print('❌ ERROR in initState');
      print('${"!" * 60}');
      print('Error: $e');
      print('Type: ${e.runtimeType}');
      print('\nStack Trace:');
      print(stackTrace);
      print('${"!" * 60}\n');
    }
    print('${"=" * 60}\n');
  }

  @override
  void dispose() {
    print('\n${"=" * 60}');
    print('🗑️  MyProfileScreen.dispose STARTED');
    print('${"=" * 60}');

    try {
      print('🔧 Attempting to hide loader...');
      // Don't use context in dispose - it may not be available
      loading.Widgets.hideLoader(null);
      print('   ✅ Loader hidden');
    } catch (e) {
      print('   ⚠️  Error hiding loader: $e');
    }

    print('✅ dispose COMPLETED');
    print('${"=" * 60}\n');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('\n${"─" * 60}');
    print('🎨 MyProfileScreen.build STARTED');
    print('${"─" * 60}');

    try {
      print('🔍 Step 1: Watch AuthCubit state');
      final authState = context.watch<AuthCubit>().state;
      print('   ✅ Auth state obtained');
      print('   - Type: ${authState.runtimeType}');

      print('🔍 Step 2: Extract user info');
      final userName = authState is Authenticated ? authState.user.name : '';
      final userRole = authState is Authenticated
          ? authState.user.primaryGroup
          : '';
      print('   - User name: "$userName"');
      print('   - User role: "$userRole"');

      print('🔍 Step 3: Building Scaffold with FutureBuilder');
      final widget = Scaffold(
        backgroundColor: Colors.transparent,
        body: FutureBuilder<PartnerProfile?>(
          future: _future,
          builder: (context, snap) {
            print('\n   ┌─ FutureBuilder callback ─');
            print('   │ Connection state: ${snap.connectionState}');
            print('   │ Has error: ${snap.hasError}');
            print('   │ Has data: ${snap.hasData}');
            if (snap.hasError) {
              print('   │ Error: ${snap.error}');
            }
            if (snap.hasData) {
              print(
                '   │ Data: ${snap.data != null ? "Profile loaded" : "null"}',
              );
            }

            try {
              if (snap.connectionState == ConnectionState.waiting) {
                print('   │ State: WAITING - scheduling loader show');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  print('   │ PostFrameCallback: Show loader');
                  if (!mounted) {
                    print('   │ ⚠️  Not mounted - skipping loader');
                    return;
                  }
                  try {
                    loading.Widgets.showLoader(context);
                    print('   │ ✅ Loader shown');
                  } catch (e) {
                    print('   │ ❌ Failed to show loader: $e');
                  }
                });
                print('   └─────────────────────────');
                return const SizedBox.shrink();
              }

              print('   │ State: NOT WAITING - scheduling loader hide');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                print('   │ PostFrameCallback: Hide loader');
                if (!mounted) {
                  print('   │ ⚠️  Not mounted - skipping loader hide');
                  return;
                }
                try {
                  loading.Widgets.hideLoader(context);
                  print('   │ ✅ Loader hidden');
                } catch (e) {
                  print('   │ ❌ Failed to hide loader: $e');
                }
              });

              if (snap.hasError) {
                print('   │ Building error widget');
                print('   └─────────────────────────');
                return Center(
                  child: Text('Failed to load profile\n${snap.error}'),
                );
              }

              print('   │ Building profile UI');
              final profile = snap.data;
              final name = (profile?.name ?? userName).trim();
              final email = (profile?.email ?? '').trim();

              print('   │ Profile details:');
              print('   │   - Name: "$name"');
              print('   │   - Email: "$email"');
              print('   │   - Has image: ${profile?.imageBytes != null}');
              print('   └─────────────────────────');

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
                                          ?.withOpacity(
                                            0.8,
                                          ), // FIXED: withValues -> withOpacity
                                    ),
                              ),
                              const SizedBox(height: 6),
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
                      print('\n${"=" * 40}');
                      print('✏️  Edit Profile tapped');
                      print('${"=" * 40}');

                      try {
                        print('🔍 Navigating to /profile/edit...');
                        final didSave = await context.push<bool>(
                          '/profile/edit',
                          extra: profile,
                        );
                        print('   ✅ Returned from edit screen');
                        print('   - Did save: $didSave');

                        if (!mounted) {
                          print('   ⚠️  Widget not mounted after navigation');
                          return;
                        }

                        if (didSave == true) {
                          print('   🔄 Profile was saved - reloading...');
                          setState(_reload);
                          print('   ✅ Reload triggered');
                        }
                      } catch (e, stackTrace) {
                        print('\n${"!" * 40}');
                        print('❌ ERROR in Edit Profile nav');
                        print('${"!" * 40}');
                        print('Error: $e');
                        print('\nStack Trace:');
                        print(stackTrace);
                        print('${"!" * 40}\n');
                      }
                      print('${"=" * 40}\n');
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
            } catch (e, stackTrace) {
              print('\n   ${"!" * 40}');
              print('   ❌ ERROR in FutureBuilder');
              print('   ${"!" * 40}');
              print('   Error: $e');
              print('   Type: ${e.runtimeType}');
              print('   Stack: $stackTrace');
              print('   ${"!" * 40}\n');

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error building profile: $e'),
                  ],
                ),
              );
            }
          },
        ),
      );

      print('✅ build COMPLETED');
      print('${"─" * 60}\n');

      return widget;
    } catch (e, stackTrace) {
      print('\n${"!" * 60}');
      print('❌ ERROR in build');
      print('${"!" * 60}');
      print('Error: $e');
      print('Type: ${e.runtimeType}');
      print('\nStack Trace:');
      print(stackTrace);
      print('${"!" * 60}\n');

      return Scaffold(
        appBar: AppBar(title: const Text('Profile - Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  final dynamic imageBytes;
  final String fallbackName;

  const _ProfileAvatar({required this.imageBytes, required this.fallbackName});

  String _initials(String name) {
    print('   📝 Computing initials for: "$name"');
    try {
      final parts = name
          .split(' ')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (parts.isEmpty) {
        print('      ✅ Empty name - returning "U"');
        return 'U';
      }

      final first = parts.first[0];
      final second = parts.length > 1 ? parts[1][0] : '';
      final initials = (first + second).toUpperCase();
      print('      ✅ Initials: "$initials"');
      return initials;
    } catch (e) {
      print('      ❌ Error computing initials: $e - returning "U"');
      return 'U';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('   🎨 Building _ProfileAvatar');

    try {
      final bytes = imageBytes;
      print('      - Image bytes type: ${bytes?.runtimeType}');
      print('      - Is List<int>: ${bytes is List<int>}');
      if (bytes is List<int>) {
        print('      - Bytes length: ${bytes.length}');
      }

      if (bytes is List<int> && bytes.isNotEmpty) {
        print('      ✅ Building image avatar');
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            Uint8List.fromList(bytes),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('      ❌ Image.memory error: $error');
              return _buildFallbackAvatar(context);
            },
          ),
        );
      }

      print('      ℹ️  No valid image - building fallback avatar');
      return _buildFallbackAvatar(context);
    } catch (e, stackTrace) {
      print('      ❌ ERROR in _ProfileAvatar.build: $e');
      print('      Stack: $stackTrace');
      return _buildFallbackAvatar(context);
    }
  }

  Widget _buildFallbackAvatar(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.primary.withOpacity(
          0.12,
        ), // FIXED: withValues -> withOpacity
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
