import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/features/profile/presentation/widgets/profile_view.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/landlord/data/models/partner_profile.dart';
import 'package:login_again/features/landlord/data/repositories/landlord_repository.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;

class LandlordTenantProfileScreen extends StatefulWidget {
  final int tenantPartnerId;
  final String tenantName;
  final String propertyName;
  final String unitName;
  final String? status;

  const LandlordTenantProfileScreen({
    super.key,
    required this.tenantPartnerId,
    required this.tenantName,
    required this.propertyName,
    required this.unitName,
    this.status,
  });

  @override
  State<LandlordTenantProfileScreen> createState() =>
      _LandlordTenantProfileScreenState();
}

class _LandlordTenantProfileScreenState
    extends State<LandlordTenantProfileScreen> {
  late final Future<PartnerProfile?> _future;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>();
    final repo = LandlordRepository(apiClient: auth.apiClient);
    _future = repo.fetchPartnerProfile(partnerId: widget.tenantPartnerId);
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            return Center(child: Text('Failed to load tenant\n${snap.error}'));
          }

          return ProfileView(
            profile: snap.data,
            fallbackName: widget.tenantName,
            userRole: 'Tenant',
            propertyContext: widget.propertyName,
            unitContext: widget.unitName,
            statusBadge: widget.status,
          );
        },
      ),
    );
  }
}
