import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;
import 'package:login_again/features/maintainer/presentation/cubit/maintainer_inspections_cubit.dart';

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
            DropdownButtonFormField<String>(
              value: _selectedState,
              items: const [
                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('In Progress'),
                ),
                DropdownMenuItem(value: 'done', child: Text('Done')),
              ],
              onChanged: _saving
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => _selectedState = v);
                    },
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outline),
              ),
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
    );
  }
}
