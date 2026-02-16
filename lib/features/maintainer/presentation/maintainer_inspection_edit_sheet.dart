import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/core/widgets/glass_surface.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;
import 'package:login_again/features/maintainer/presentation/cubit/maintainer_inspections_cubit.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class _StateDropdownItem {
  final String value;
  final String label;
  _StateDropdownItem(this.value, this.label);
  @override
  String toString() => label;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _StateDropdownItem && runtimeType == other.runtimeType && value == other.value;
  @override
  int get hashCode => value.hashCode;
}

class MaintainerInspectionEditSheet extends StatefulWidget {
  final int inspectionId;
  final int userId;
  final bool initialMaintenanceRequired;
  final String initialConditionNotes;
  final String initialMaintenanceDescription;
  final String initialState;

  const MaintainerInspectionEditSheet({
    super.key,
    required this.inspectionId,
    required this.userId,
    required this.initialMaintenanceRequired,
    required this.initialConditionNotes,
    required this.initialMaintenanceDescription,
    required this.initialState,
  });

  @override
  State<MaintainerInspectionEditSheet> createState() =>
      _MaintainerInspectionEditSheetState();
}

class _MaintainerInspectionEditSheetState
    extends State<MaintainerInspectionEditSheet> {
  late final TextEditingController _notesController;
  late final TextEditingController _descController;

  late bool _maintenanceRequired;
  late String _selectedState;
  late _StateDropdownItem _selectedStateItem;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.initialConditionNotes,
    );
    _descController = TextEditingController(
      text: widget.initialMaintenanceDescription,
    );
    _maintenanceRequired = widget.initialMaintenanceRequired;
    _selectedState = widget.initialState == 'open'
        ? 'draft'
        : (widget.initialState.isEmpty ? 'draft' : widget.initialState);
    _selectedStateItem = _StateDropdownItem(_selectedState, _getStateLabel(_selectedState));
  }

  String _getStateLabel(String state) {
    switch (state) {
      case 'draft':
        return 'Draft';
      case 'in_progress':
        return 'In Progress';
      case 'done':
        return 'Done';
      default:
        return state;
    }
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    _notesController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    loading.Widgets.showLoader(context);

    bool ok = false;
    try {
      ok = await context
          .read<MaintainerInspectionsCubit>()
          .updateInspectionDetails(
            inspectionId: widget.inspectionId,
            state: _selectedState,
            maintenanceRequired: _maintenanceRequired,
            conditionNotes: _notesController.text.trim(),
            maintenanceDescription: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            userId: widget.userId,
          );

      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Inspection saved' : 'Failed to save inspection'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
      loading.Widgets.hideLoader(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GlassSurface(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inspection Notes',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                child: CustomDropdown<_StateDropdownItem>(
                  hintText: 'Status',
                  initialItem: _selectedStateItem,
                  items: [
                    _StateDropdownItem('draft', 'Draft'),
                    _StateDropdownItem('in_progress', 'In Progress'),
                    _StateDropdownItem('done', 'Done'),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedStateItem = value;
                            _selectedState = value.value;
                          });
                        },
                  decoration: CustomDropdownDecoration(
                    closedBorder: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    closedFillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                    closedShadow: [],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GlassSurface(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(12),
                enableBlur: false,
                tint: scheme.surface.withValues(alpha: 0.6),
                child: SwitchListTile(
                  value: _maintenanceRequired,
                  onChanged: _saving
                      ? null
                      : (v) {
                          setState(() => _maintenanceRequired = v);
                        },
                  title: const Text('Maintenance required'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                enabled: !_saving,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Condition notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
