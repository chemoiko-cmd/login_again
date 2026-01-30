import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:login_again/features/landlord/presentation/cubit/tenants_cubit.dart';
import 'package:login_again/features/landlord/presentation/cubit/tenants_state.dart';
import 'package:login_again/features/landlord/presentation/widgets/action_tile.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/landlord/presentation/widgets/tenant_create_overlay.dart';
import 'package:login_again/core/widgets/gradient_floating_action_button.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;

class LandlordTenantsScreen extends StatefulWidget {
  const LandlordTenantsScreen({super.key});

  @override
  State<LandlordTenantsScreen> createState() => _LandlordTenantsScreenState();
}

class _LandlordTenantsScreenState extends State<LandlordTenantsScreen> {
  bool _isCreating = false;
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    final partnerId = authState is Authenticated ? authState.user.partnerId : 0;
    if (partnerId > 0) {
      context.read<TenantsCubit>().load(partnerId: partnerId);
    }
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
      body: Stack(
        children: [
          BlocConsumer<TenantsCubit, TenantsState>(
            listener: (context, state) {
              final shouldShow = state is TenantsLoading && !_isCreating;
              if (shouldShow) {
                loading.Widgets.showLoader(context);
              } else {
                loading.Widgets.hideLoader(context);
              }
            },
            builder: (context, state) {
              if (state is TenantsLoading && !_isCreating) {
                return const SizedBox.shrink();
              }

              if (state is TenantsError) {
                return Center(child: Text(state.message));
              }

              if (state is TenantsLoaded) {
                if (state.tenants.isEmpty) {
                  return const Center(child: Text('No tenants found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.tenants.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final row = state.tenants[index];
                    return ActionTile(
                      icon: Icons.person_outline,
                      title: row.tenantName,
                      subtitle: '${row.propertyName} • ${row.unitName}',
                      state: row.status,
                      onTap: () {
                        context.go(
                          '/landlord-tenants/${row.tenantPartnerId}',
                          extra: {
                            'tenantName': row.tenantName,
                            'propertyName': row.propertyName,
                            'unitName': row.unitName,
                            'status': row.status,
                          },
                        );
                      },
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
          if (_isCreating)
            Builder(
              builder: (context) {
                final authState = context.read<AuthCubit>().state;
                final partnerId = authState is Authenticated
                    ? authState.user.partnerId
                    : 0;
                return TenantCreateOverlay(
                  partnerId: partnerId,
                  onClose: () => setState(() => _isCreating = false),
                );
              },
            ),
        ],
      ),
      floatingActionButton: _isCreating
          ? null
          : GradientFloatingActionButton(
              onPressed: () => setState(() => _isCreating = true),
              child: const Icon(Icons.person_add_alt_1),
            ),
    );
  }
}
