import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:login_again/features/landlord/presentation/cubit/inspections_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class _DropdownItem {
  final int id;
  final String name;
  _DropdownItem(this.id, this.name);
  @override
  String toString() => name;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _DropdownItem &&
          runtimeType == other.runtimeType &&
          id == other.id;
  @override
  int get hashCode => id.hashCode;
}

class InspectionCreateScreen extends StatefulWidget {
  const InspectionCreateScreen({super.key});

  @override
  State<InspectionCreateScreen> createState() => _InspectionCreateScreenState();
}

class _InspectionCreateScreenState extends State<InspectionCreateScreen> {
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
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final partnerId = authState.user.partnerId;

    final repo = context.read<InspectionsCubit>().repository;
    final units = await repo.fetchUnits(partnerId: partnerId);
    final inspectorPartners = await repo.fetchInspectorPartners(
      landlordPartnerId: partnerId,
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

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final partnerId = authState.user.partnerId;

    final ok = await context.read<InspectionsCubit>().addInspection(
      partnerId: partnerId,
      unitId: _selectedUnitId!,
      date: _date!.toIso8601String().split('T').first,
      name: _nameCtrl.text.trim(),
      cleanliness: _cleanliness,
      inspectorId: _selectedInspectorId,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inspection submitted')));
      context.pop(true);
    }
  }

  Widget _buildUnitDropdown() {
    final unitItems = _units
        .map((u) => _DropdownItem(u['id'] as int, u['name'] as String))
        .toList();
    final outlineColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.5);
    final fillColor = Theme.of(context).colorScheme.surfaceContainerLow;

    return FormField<_DropdownItem>(
      initialValue: _selectedUnitId != null
          ? _DropdownItem(
              _selectedUnitId!,
              _units.firstWhere((u) => u['id'] == _selectedUnitId)['name']
                  as String,
            )
          : null,
      validator: (v) => v == null ? 'Please select a unit' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            child: CustomDropdown<_DropdownItem>(
              hintText: 'Unit',
              initialItem: field.value,
              items: unitItems,
              onChanged: (value) {
                field.didChange(value);
                if (value != null) setState(() => _selectedUnitId = value.id);
              },
              decoration: CustomDropdownDecoration(
                closedBorder: Border.all(color: outlineColor, width: 1),
                closedBorderRadius: BorderRadius.circular(12),
                closedFillColor: fillColor,
                closedShadow: [],
              ),
            ),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                field.errorText ?? '',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInspectorDropdown() {
    final validInspectors = _inspectorPartners
        .where((p) => p['user_id'] != null)
        .toList();
    final inspectorItems = validInspectors
        .map((p) => _DropdownItem(p['user_id'] as int, p['name'] as String))
        .toList();
    final outlineColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.5);
    final fillColor = Theme.of(context).colorScheme.surfaceContainerLow;

    return FormField<_DropdownItem>(
      initialValue: _selectedInspectorId != null
          ? _DropdownItem(
              _selectedInspectorId!,
              validInspectors.firstWhere(
                    (p) => p['user_id'] == _selectedInspectorId,
                  )['name']
                  as String,
            )
          : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            child: CustomDropdown<_DropdownItem>(
              hintText: 'Inspector',
              initialItem: field.value,
              items: inspectorItems,
              onChanged: (value) {
                field.didChange(value);
                if (value != null)
                  setState(() => _selectedInspectorId = value.id);
              },
              decoration: CustomDropdownDecoration(
                closedBorder: Border.all(color: outlineColor, width: 1),
                closedBorderRadius: BorderRadius.circular(12),
                closedFillColor: fillColor,
                closedShadow: [],
              ),
            ),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                field.errorText ?? '',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLists) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) loading.Widgets.showLoader(context);
      });
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox.shrink(),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) loading.Widgets.hideLoader(context);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUnitDropdown(),
                const SizedBox(height: 12),
                _buildInspectorDropdown(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Please enter a title' : null,
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
                  validator: (v) => _date == null ? 'Please pick a date' : null,
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
            ),
          ),
        ),
      ),
    );
  }
}
