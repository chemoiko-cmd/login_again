import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/features/profile/presentation/widgets/profile_view.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/landlord/data/models/partner_profile.dart';
import 'package:login_again/features/profile/data/profile_repository.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  late final Future<PartnerProfile?> _future;

  @override
  void initState() {
    super.initState();
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

          return ProfileView(
            profile: snap.data,
            fallbackName: userName,
            userRole: userRole,
          );
        },
      ),
    );
  }
}
