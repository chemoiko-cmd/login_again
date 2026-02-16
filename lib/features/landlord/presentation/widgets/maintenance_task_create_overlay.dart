import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:login_again/features/landlord/presentation/cubit/maintenance_tasks_cubit.dart';
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
      other is _DropdownItem && runtimeType == other.runtimeType && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

class MaintenanceTaskCreateOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final int partnerId;

  const MaintenanceTaskCreateOverlay({
    super.key,
    required this.onClose,
    required this.partnerId,
  });

  @override
  State<MaintenanceTaskCreateOverlay> createState() =>
      _MaintenanceTaskCreateOverlayState();
}

class _MaintenanceTaskCreateOverlayState
    extends State<MaintenanceTaskCreateOverlay> {
  final _formKey = GlobalKey<FormBuilderState>();

  bool _loadingLists = true;
  List<Map<String, dynamic>> _units = const [];
  List<Map<String, dynamic>> _assignees = const [];

  int? _selectedUnitId;
  int? _selectedAssigneePartnerId;
  String _priority = '1';

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
            color: isActive ? scheme.primary : scheme.outline,
            width: 2,
          ),
          color: isActive ? scheme.primary.withOpacity(0.08) : null,
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
                  : scheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive
                    ? scheme.onSurface
                    : scheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    final repo = context.read<MaintenanceTasksCubit>().repository;
    final units = await repo.fetchUnits(partnerId: widget.partnerId);
    final assignees = await repo.fetchMaintenancePartners(
      landlordPartnerId: widget.partnerId,
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

    final formData = _formKey.currentState!.value;
    final title = (formData['title'] ?? '').toString().trim();

    final ok = await context.read<MaintenanceTasksCubit>().addTask(
      partnerId: widget.partnerId,
      unitId: _selectedUnitId!,
      name: title,
      assignedToPartnerId: _selectedAssigneePartnerId,
      priority: _priority,
    );

    if (!mounted) return;

    if (ok) {
      widget.onClose();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maintenance task created')));
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
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'New Maintenance Task',
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
                            const SizedBox.shrink()
                          else ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "What's the issue?",
                                style: t.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            FormBuilderTextField(
                              name: 'title',
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                              ]),
                              decoration: InputDecoration(
                                hintText: 'e.g., Fix leaking tap',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Unit',
                                style: t.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            FormField<_DropdownItem>(
                              initialValue: _selectedUnitId != null
                                  ? _DropdownItem(_selectedUnitId!, _units.firstWhere((u) => u['id'] == _selectedUnitId)['name'] as String)
                                  : null,
                              validator: (v) {
                                if (v == null) return 'Please select a unit';
                                return null;
                              },
                              builder: (field) {
                                final unitItems = _units.map((u) => _DropdownItem(u['id'] as int, u['name'] as String)).toList();
                                final outlineColor = Theme.of(context).colorScheme.outline.withValues(alpha: 0.5);
                                final fillColor = Theme.of(context).colorScheme.surfaceContainerLow;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                      child: CustomDropdown<_DropdownItem>(
                                        hintText: 'Select unit',
                                        initialItem: field.value,
                                        items: unitItems,
                                        onChanged: (value) {
                                          field.didChange(value);
                                          if (value != null) {
                                            setState(() => _selectedUnitId = value.id);
                                          }
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
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Assign To',
                              style: t.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FormField<_DropdownItem>(
                            initialValue: _selectedAssigneePartnerId != null
                                ? _DropdownItem(_selectedAssigneePartnerId!, _assignees.firstWhere((p) => p['id'] == _selectedAssigneePartnerId)['name'] as String)
                                : null,
                            validator: (v) {
                              if (v == null) return 'Please select a maintainer';
                              return null;
                            },
                            builder: (field) {
                              final assigneeItems = _assignees.map((p) => _DropdownItem(p['id'] as int, p['name'] as String)).toList();
                              final outlineColor = Theme.of(context).colorScheme.outline.withValues(alpha: 0.5);
                              final fillColor = Theme.of(context).colorScheme.surfaceContainerLow;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                    child: CustomDropdown<_DropdownItem>(
                                      hintText: 'Select maintainer',
                                      initialItem: field.value,
                                      items: assigneeItems,
                                      onChanged: (value) {
                                        field.didChange(value);
                                        if (value != null) {
                                          setState(() => _selectedAssigneePartnerId = value.id);
                                        }
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
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Priority',
                              style: t.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
