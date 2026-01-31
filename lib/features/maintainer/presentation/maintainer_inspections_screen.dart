import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/core/widgets/glass_surface.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/maintainer/presentation/cubit/maintainer_inspections_cubit.dart';
import 'package:login_again/features/maintainer/presentation/maintainer_inspection_edit_sheet.dart';
import 'package:login_again/features/landlord/presentation/cubit/maintenance_tasks_state.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;
import 'package:login_again/core/utils/formatters.dart';

class MaintainerInspectionsScreen extends StatefulWidget {
  const MaintainerInspectionsScreen({super.key});

  @override
  State<MaintainerInspectionsScreen> createState() =>
      _MaintainerInspectionsScreenState();
}

class _MaintainerInspectionsScreenState
    extends State<MaintainerInspectionsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthCubit>().state;
      if (auth is Authenticated) {
        context.read<MaintainerInspectionsCubit>().load(userId: auth.user.id);
      }
    });
  }

  String _tupleName(dynamic value) {
    if (value is List && value.length > 1) return value[1]?.toString() ?? '-';
    return '-';
  }

  Future<void> _setStateForInspection(int inspectionId, String newState) async {
    final auth = context.read<AuthCubit>().state;
    final userId = auth is Authenticated ? auth.user.id : 0;
    final ok = await context
        .read<MaintainerInspectionsCubit>()
        .setInspectionState(
          inspectionId: inspectionId,
          state: newState,
          userId: userId,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Inspection updated' : 'Failed to update inspection',
        ),
      ),
    );
  }

  Future<void> _openInspectionOverlay(Map<String, dynamic> item) async {
    final auth = context.read<AuthCubit>().state;
    final userId = auth is Authenticated ? auth.user.id : 0;
    final inspectionId = (item['id'] as num?)?.toInt() ?? 0;
    if (inspectionId == 0 || userId == 0) return;

    final initialRequired = (item['maintenance_required'] == true);
    final initialNotes = (item['condition_notes'] ?? '').toString();
    final initialDesc = (item['maintenance_description'] ?? '').toString();
    final initialState = (item['state'] ?? 'draft').toString();

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return MaintainerInspectionEditSheet(
          inspectionId: inspectionId,
          userId: userId,
          initialMaintenanceRequired: initialRequired,
          initialConditionNotes: initialNotes,
          initialMaintenanceDescription: initialDesc,
          initialState: initialState,
        );
      },
    );
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<MaintainerInspectionsCubit, MaintenanceTasksState>(
        listener: (context, state) {
          if (state is MaintenanceTasksLoading) {
            loading.Widgets.showLoader(context);
          } else {
            loading.Widgets.hideLoader(context);
          }
        },
        builder: (context, state) {
          if (state is MaintenanceTasksLoading) {
            return const SizedBox.shrink();
          }
          if (state is MaintenanceTasksError) {
            return Center(child: Text(state.message));
          }
          if (state is MaintenanceTasksLoaded) {
            if (state.tasks.isEmpty) {
              return const Center(child: Text('No inspections assigned'));
            }
            return RefreshIndicator(
              onRefresh: () async {
                final auth = context.read<AuthCubit>().state;
                final userId = auth is Authenticated ? auth.user.id : 0;
                await context.read<MaintainerInspectionsCubit>().load(
                  userId: userId,
                );
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.tasks.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = state.tasks[index];
                  final title = (item['name'] ?? 'Inspection').toString();
                  final unitName = _tupleName(item['unit_id']);
                  final dateStr = (item['date'] ?? '').toString();
                  final s = (item['state'] ?? '').toString();
                  final id = (item['id'] as num?)?.toInt() ?? 0;

                  return GlassSurface(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      onTap: () => _openInspectionOverlay(item),
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade50,
                        child: Icon(
                          Icons.search_outlined,
                          color: scheme.primary,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(title)),
                          Chip(
                            label: Text(
                              formatStateLabel(s),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: stateBadgeColor(s),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      subtitle: Text('$unitName • $dateStr'),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
