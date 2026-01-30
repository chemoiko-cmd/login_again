import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/features/landlord/presentation/widgets/action_tile.dart';
import 'package:login_again/features/landlord/presentation/cubit/inspections_cubit.dart';
import 'package:login_again/features/landlord/presentation/cubit/inspections_state.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/landlord/presentation/widgets/inspection_create_overlay.dart';
import 'package:login_again/core/widgets/gradient_floating_action_button.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    final partnerId = authState is Authenticated ? authState.user.partnerId : 0;
    if (partnerId > 0) {
      context.read<InspectionsCubit>().load(partnerId: partnerId);
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
          BlocConsumer<InspectionsCubit, InspectionsState>(
            listener: (context, state) {
              final shouldShow = state is InspectionsLoading && !_isCreating;
              if (shouldShow) {
                loading.Widgets.showLoader(context);
              } else {
                loading.Widgets.hideLoader(context);
              }
            },
            builder: (context, state) {
              if (state is InspectionsLoading && !_isCreating) {
                return const SizedBox.shrink();
              }

              if (state is InspectionsError) {
                return Center(child: Text(state.message));
              }

              if (state is InspectionsLoaded) {
                if (state.inspections.isEmpty) {
                  return const Center(child: Text('No inspections found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.inspections.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final inspection = state.inspections[index];

                    return ActionTile(
                      icon: Icons.assignment,
                      title: inspection.name,
                      subtitle:
                          '${inspection.propertyName} • ${inspection.unitName}',
                      state: inspection.state,
                      onTap: () {},
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
                return InspectionCreateOverlay(
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
              child: const Icon(Icons.add),
            ),
    );
  }
}
