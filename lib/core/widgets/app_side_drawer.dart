import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:login_again/theme/app_theme.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/landlord/data/models/partner_profile.dart';

class AppSideDrawer extends StatefulWidget {
  const AppSideDrawer({super.key});

  @override
  State<AppSideDrawer> createState() => _AppSideDrawerState();
}

class _AppSideDrawerState extends State<AppSideDrawer> {
  PartnerProfile? _profile;
  bool _loadingProfile = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    if (_loadingProfile || _profile != null) return;

    setState(() => _loadingProfile = true);
    try {
      final repo = ProfileRepository(
        apiClient: context.read<AuthCubit>().apiClient,
      );
      final profile = await repo.fetchPartnerProfile(
        partnerId: authState.user.partnerId,
      );
      if (mounted) {
        setState(() {
          _profile = profile;
          _loadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouter.of(context).state.uri.path;
    final authState = context.watch<AuthCubit>().state;
    final scheme = Theme.of(context).colorScheme;
    final bool isAuthenticated = authState is Authenticated;
    final bool isTenant = authState is Authenticated && authState.isTenant;
    final bool isLandlord = authState is Authenticated && authState.isLandlord;
    final bool isMaintenance =
        authState is Authenticated && authState.isMaintenance;

    final String userName = authState is Authenticated
        ? authState.user.name
        : 'Guest';

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: AppGradients.primaryGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: scheme.surface,
                    backgroundImage: _profile?.imageBytes != null
                        ? MemoryImage(_profile!.imageBytes!)
                        : null,
                    child: _profile?.imageBytes == null
                        ? Icon(Icons.person, size: 32, color: scheme.primary)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_profile?.email.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _profile!.email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outline),
            Expanded(
              child: ListView(
                children: [
                  if (isAuthenticated) ...[
                    // Dashboard item switches destination based on role
                    ListTile(
                      leading: Icon(
                        Icons.dashboard_outlined,
                        color: scheme.primary,
                      ),
                      title: const Text('Dashboard'),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (isLandlord) {
                          context.go('/landlord-dashboard');
                        } else if (isTenant) {
                          context.go('/tenant-dashboard');
                        } else if (isMaintenance) {
                          context.go('/maintainer-tasks');
                        }
                      },
                      selected:
                          location == '/tenant-dashboard' ||
                          location == '/landlord-dashboard' ||
                          location == '/maintainer-tasks',
                      selectedTileColor: scheme.primary.withOpacity(0.08),
                    ),

                    // Tenant-only items
                    if (isTenant) ...[
                      ListTile(
                        leading: Icon(
                          Icons.credit_card,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                        title: const Text('Pay Rent'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/pay-rent');
                        },
                        selected: location == '/pay-rent',
                        selectedTileColor: scheme.primary.withOpacity(0.08),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.description_outlined,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                        title: const Text('Contract Info'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/contracts');
                        },
                        selected: location == '/contracts',
                        selectedTileColor: scheme.primary.withOpacity(0.08),
                      ),
                    ],

                    // Maintainer-only items
                    if (isMaintenance) ...[
                      ListTile(
                        leading: Icon(
                          Icons.build_outlined,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                        title: const Text('My Tasks'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/maintainer-tasks');
                        },
                        selected: location == '/maintainer-tasks',
                        selectedTileColor: scheme.primary.withOpacity(0.08),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.search_outlined,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                        title: const Text('Inspections'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/maintainer-inspections');
                        },
                        selected: location == '/maintainer-inspections',
                        selectedTileColor: scheme.primary.withOpacity(0.08),
                      ),
                    ],

                    // Landlord-only items
                    if (isLandlord) ...[
                      ListTile(
                        leading: Icon(
                          Icons.apartment_outlined,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                        title: const Text('My Properties'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/landlord-properties');
                        },
                        selected: location == '/landlord-properties',
                        selectedTileColor: scheme.primary.withOpacity(0.08),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.description_outlined,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                        title: const Text('Inspections'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/inspections');
                        },
                        selected: location == '/inspections',
                        selectedTileColor: scheme.primary.withOpacity(0.08),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.people_outline,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                        title: const Text('Tenants'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/landlord-tenants');
                        },
                        selected: location == '/landlord-tenants',
                        selectedTileColor: scheme.primary.withOpacity(0.08),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.build_outlined,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                        title: const Text('Maintenance Tasks'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/landlord-maintenance');
                        },
                        selected: location == '/landlord-maintenance',
                        selectedTileColor: scheme.primary.withOpacity(0.08),
                      ),
                    ],
                  ],
                  // ListTile(
                  //   leading: Icon(
                  //     Icons.notifications_outlined,
                  //     color: scheme.onSurface.withOpacity(0.7),
                  //   ),
                  //   title: const Text('Notices'),
                  //   onTap: () {
                  //     Navigator.of(context).pop();
                  //   },
                  // ),
                  ListTile(
                    leading: Icon(
                      Icons.person_outline,
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.of(context);
                      context.go('/profile');
                    },
                    selected: location == '/profile',
                    selectedTileColor: scheme.primary.withOpacity(0.08),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip_outlined,
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/privacy-policy');
                    },
                    selected: location == '/privacy-policy',
                    selectedTileColor: scheme.primary.withOpacity(0.08),
                  ),
                  // ListTile(
                  //   leading: const Icon(
                  //     Icons.notifications_outlined,
                  //     color: AppColors.textSecondary,
                  //   ),
                  //   title: const Text('Maintenance2'),
                  //   onTap: () {
                  //     Navigator.of(context).pop();
                  //     context.go('/maintenance2');
                  //   },
                  // ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outline),
            if (isAuthenticated)
              ListTile(
                leading: Icon(Icons.power_settings_new, color: scheme.error),
                title: const Text('Sign Out'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await context.read<AuthCubit>().logout();
                },
              ),
          ],
        ),
      ),
    );
  }
}
