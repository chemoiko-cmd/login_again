import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/features/landlord/presentation/cubit/inspections_cubit.dart';
import 'package:login_again/core/widgets/gradient_button.dart';

class InspectionCreateOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final int partnerId;

  const InspectionCreateOverlay({
    super.key,
    required this.onClose,
    required this.partnerId,
  });

  @override
  State<InspectionCreateOverlay> createState() =>
      _InspectionCreateOverlayState();
}

class _InspectionCreateOverlayState extends State<InspectionCreateOverlay> {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _maintenanceDescCtrl = TextEditingController();

  DateTime? _date;
  int _cleanliness = 3;
  bool _maintenanceRequired = false;

  int? _selectedUnitId;
  int? _selectedInspectorId;

  bool _loadingLists = true;
  List<Map<String, dynamic>> _units = const [];
  // Partners labeled list with linked user_id for inspector_id
  List<Map<String, dynamic>> _inspectorPartners = const [];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _maintenanceDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    final repo = context.read<InspectionsCubit>().repository;
    final units = await repo.fetchUnits(partnerId: widget.partnerId);
    final inspectorPartners = await repo.fetchInspectorPartners();
    if (!mounted) return;
    setState(() {
      _units = units;
      _inspectorPartners = inspectorPartners;
      _loadingLists = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_selectedUnitId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a unit')));
      return;
    }
    if (_date == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please pick a date')));
      return;
    }

    final ok = await context.read<InspectionsCubit>().addInspection(
      partnerId: widget.partnerId,
      unitId: _selectedUnitId!,
      date: _date!.toIso8601String().split('T').first,
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      conditionNotes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
      cleanliness: _cleanliness,
      maintenanceRequired: _maintenanceRequired,
      maintenanceDescription: _maintenanceDescCtrl.text.trim().isEmpty
          ? null
          : _maintenanceDescCtrl.text.trim(),
      inspectorId: _selectedInspectorId,
    );

    if (!mounted) return;
    if (ok) {
      widget.onClose();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inspection submitted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          color: Colors.black.withValues(alpha: 0.4),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'New Inspection',
                              style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_loadingLists)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else ...[
                          DropdownButtonFormField<int>(
                            value: _selectedUnitId,
                            onChanged: (v) =>
                                setState(() => _selectedUnitId = v),
                            items: _units
                                .map(
                                  (u) => DropdownMenuItem<int>(
                                    value: u['id'] as int,
                                    child: Text(u['name'] as String),
                                  ),
                                )
                                .toList(),
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _selectedInspectorId,
                            onChanged: (v) =>
                                setState(() => _selectedInspectorId = v),
                            items: _inspectorPartners.map((p) {
                              final int? userId = p['user_id'] as int?;
                              return DropdownMenuItem<int>(
                                value: userId,
                                enabled: userId != null,
                                child: Text(p['name'] as String),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              labelText: 'Inspector (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Title (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GradientOutlinedButton(
                                  onPressed: _pickDate,
                                  minHeight: 48,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.event),
                                      const SizedBox(width: 8),
                                      Text(
                                        _date == null
                                            ? 'Pick Date'
                                            : _date!
                                                  .toIso8601String()
                                                  .split('T')
                                                  .first,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Condition notes',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: _maintenanceRequired,
                            onChanged: (v) => setState(
                              () => _maintenanceRequired = v ?? false,
                            ),
                            title: const Text('Maintenance required?'),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_maintenanceRequired) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: _maintenanceDescCtrl,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Maintenance description',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: GradientButton(
                              onPressed: _submit,
                              minHeight: 48,
                              borderRadius: BorderRadius.circular(24),
                              child: const Text('Submit Inspection'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
