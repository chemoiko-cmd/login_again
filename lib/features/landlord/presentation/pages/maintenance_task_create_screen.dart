import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:login_again/features/landlord/presentation/cubit/maintenance_tasks_cubit.dart';
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

class MaintenanceTaskCreateScreen extends StatefulWidget {
  const MaintenanceTaskCreateScreen({super.key});

  @override
  State<MaintenanceTaskCreateScreen> createState() =>
      _MaintenanceTaskCreateScreenState();
}

class _MaintenanceTaskCreateScreenState
    extends State<MaintenanceTaskCreateScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  bool _loadingLists = true;
  List<Map<String, dynamic>> _units = const [];
  List<Map<String, dynamic>> _assignees = const [];

  int? _selectedUnitId;
  int? _selectedAssigneePartnerId;
  String _priority = '1';

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final partnerId = authState.user.partnerId;

    final repo = context.read<MaintenanceTasksCubit>().repository;
    final units = await repo.fetchUnits(partnerId: partnerId);
    final assignees = await repo.fetchMaintenancePartners(
      landlordPartnerId: partnerId,
    );

    if (!mounted) return;
    setState(() {
      _units = units;
      _assignees = assignees;
      _loadingLists = false;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final partnerId = authState.user.partnerId;

    final formData = _formKey.currentState!.value;
    final title = (formData['title'] ?? '').toString().trim();

    final ok = await context.read<MaintenanceTasksCubit>().addTask(
      partnerId: partnerId,
      unitId: _selectedUnitId!,
      name: title,
      assignedToPartnerId: _selectedAssigneePartnerId,
      priority: _priority,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maintenance task created')));
      context.pop(true);
    }
  }

  Widget _priorityChip(String id, String label) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = _priority == id;
    return InkWell(
      onTap: () => setState(() => _priority = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.7),
            width: 2,
          ),
          color: isActive ? scheme.primary.withValues(alpha: 0.08) : null,
        ),
        child: Row(
          children: [
            Icon(
              id == '0'
                  ? Icons.low_priority
                  : id == '1'
                  ? Icons.flag_outlined
                  : id == '2'
                  ? Icons.priority_high
                  : Icons.warning_amber_rounded,
              size: 18,
              color: isActive
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive
                    ? scheme.onSurface
                    : scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
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
              hintText: 'Select unit',
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

  Widget _buildAssigneeDropdown() {
    final assigneeItems = _assignees
        .map((p) => _DropdownItem(p['id'] as int, p['name'] as String))
        .toList();
    final outlineColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.5);
    final fillColor = Theme.of(context).colorScheme.surfaceContainerLow;

    return FormField<_DropdownItem>(
      initialValue: _selectedAssigneePartnerId != null
          ? _DropdownItem(
              _selectedAssigneePartnerId!,
              _assignees.firstWhere(
                    (p) => p['id'] == _selectedAssigneePartnerId,
                  )['name']
                  as String,
            )
          : null,
      validator: (v) => v == null ? 'Please select a maintainer' : null,
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
              hintText: 'Select maintainer',
              initialItem: field.value,
              items: assigneeItems,
              onChanged: (value) {
                field.didChange(value);
                if (value != null)
                  setState(() => _selectedAssigneePartnerId = value.id);
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
    final t = Theme.of(context).textTheme;

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
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What's the issue?",
                  style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                FormBuilderTextField(
                  name: 'title',
                  validator: FormBuilderValidators.required(),
                  decoration: InputDecoration(
                    hintText: 'e.g., Fix leaking tap',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Unit',
                  style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                _buildUnitDropdown(),
                const SizedBox(height: 12),
                Text(
                  'Assign To',
                  style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                _buildAssigneeDropdown(),
                const SizedBox(height: 12),
                Text(
                  'Priority',
                  style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 3.2,
                  ),
                  children: [
                    _priorityChip('0', 'Low'),
                    _priorityChip('1', 'Normal'),
                    _priorityChip('2', 'High'),
                    _priorityChip('3', 'Urgent'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    onPressed: _submit,
                    minHeight: 48,
                    borderRadius: BorderRadius.circular(24),
                    child: const Text('Create Task'),
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
