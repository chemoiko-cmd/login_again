import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/features/landlord/presentation/cubit/inspections_cubit.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;

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
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  final _nameCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  DateTime? _date;
  int _cleanliness = 3;

  int? _selectedUnitId;
  int? _selectedInspectorId;

  bool _loadingLists = true;
  List<Map<String, dynamic>> _units = const [];
  // Partners labeled list with linked user_id for inspector_id
  List<Map<String, dynamic>> _inspectorPartners = const [];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _date = DateTime(today.year, today.month, today.day);
    _dateCtrl.text = _formatDate(_date!);
    _loadDropdowns();
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    _nameCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    final repo = context.read<InspectionsCubit>().repository;
    final units = await repo.fetchUnits(partnerId: widget.partnerId);
    final inspectorPartners = await repo.fetchInspectorPartners(
      landlordPartnerId: widget.partnerId,
    );
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
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateCtrl.text = _formatDate(picked);
      });
      if (_autoValidateMode != AutovalidateMode.disabled) {
        _formKey.currentState?.validate();
      }
    }
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    final ok = await context.read<InspectionsCubit>().addInspection(
      partnerId: widget.partnerId,
      unitId: _selectedUnitId!,
      date: _date!.toIso8601String().split('T').first,
      name: _nameCtrl.text.trim(),
      cleanliness: _cleanliness,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_loadingLists) {
        loading.Widgets.showLoader(context);
      } else {
        loading.Widgets.hideLoader(context);
      }
    });
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
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidateMode,
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
                            Builder(
                              builder: (context) {
                                return const SizedBox.shrink();
                              },
                            )
                          else ...[
                            DropdownButtonFormField<int>(
                              value: _selectedUnitId,
                              onChanged: (v) =>
                                  setState(() => _selectedUnitId = v),
                              validator: (v) {
                                if (v == null) return 'Please select a unit';
                                return null;
                              },
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
                              validator: (v) {
                                if (v == null)
                                  return 'Please select an inspector';
                                return null;
                              },
                              items: _inspectorPartners.map((p) {
                                final int? userId = p['user_id'] as int?;
                                return DropdownMenuItem<int>(
                                  value: userId,
                                  enabled: userId != null,
                                  child: Text(p['name'] as String),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                labelText: 'Inspector',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _nameCtrl,
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty)
                                  return 'Please enter a title';
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _dateCtrl,
                              readOnly: true,
                              onTap: _pickDate,
                              validator: (v) {
                                if (_date == null) return 'Please pick a date';
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Scheduled Date',
                                suffixIcon: const Icon(Icons.event),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
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
      ),
    );
  }
}
