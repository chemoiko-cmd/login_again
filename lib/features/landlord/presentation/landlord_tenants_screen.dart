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
import 'package:login_again/core/widgets/app_loading_indicator.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocBuilder<TenantsCubit, TenantsState>(
            builder: (context, state) {
              if (state is TenantsLoading && !_isCreating) {
                return const Center(child: AppLoadingIndicator());
              }

              if (state is TenantsError) {
                return Center(child: Text(state.message));
              }

              if (state is TenantsLoaded) {
                if (state.tenants.isEmpty) {
                  return const Center(child: Text('No tenants found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.tenants.length,
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
