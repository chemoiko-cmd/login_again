import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/landlord/presentation/cubit/tenants_cubit.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'dart:typed_data';

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

class TenantCreateScreen extends StatefulWidget {
  const TenantCreateScreen({super.key});

  @override
  State<TenantCreateScreen> createState() => _TenantCreateScreenState();
}

class _TenantCreateScreenState extends State<TenantCreateScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _imagePicker = ImagePicker();
  Uint8List? _tenantImageBytes;

  bool _loadingLists = true;
  List<Map<String, dynamic>> _units = const [];
  List<Map<String, dynamic>> _tenantPartners = const [];

  int? _selectedUnitId;
  int? _selectedTenantPartnerId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _createNewTenant = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _startDate = DateTime(today.year, today.month, today.day);
    _loadDropdowns();
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    super.dispose();
  }

  Future<void> _pickTenantImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _tenantImageBytes = bytes);
  }

  Future<void> _loadDropdowns() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final partnerId = authState.user.partnerId;

    final repo = context.read<TenantsCubit>().repository;
    final units = await repo.fetchUnits(partnerId: partnerId);
    final tenants = await repo.fetchTenantPartnersForLandlord(
      partnerId: partnerId,
    );
    if (!mounted) return;
    setState(() {
      _units = units;
      _tenantPartners = tenants;
      _loadingLists = false;
    });
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _formKey.currentState?.fields['startDate']?.didChange(
          _formatDate(picked),
        );
        if (_endDate != null && !_endDate!.isAfter(picked)) {
          _endDate = null;
          _formKey.currentState?.fields['endDate']?.didChange('');
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _formKey.currentState?.fields['endDate']?.didChange(
          _formatDate(picked),
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    if (_startDate == null || _endDate == null) return;
    if (!_endDate!.isAfter(_startDate!)) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final partnerId = authState.user.partnerId;

    final formData = _formKey.currentState!.value;
    bool ok = false;
    if (_createNewTenant) {
      ok = await context.read<TenantsCubit>().createTenantAndContract(
        partnerId: partnerId,
        unitId: _selectedUnitId!,
        contractName: (formData['contractName'] ?? '').toString().trim().isEmpty
            ? null
            : (formData['contractName'] ?? '').toString().trim(),
        startDate: _startDate!.toIso8601String().split('T').first,
        endDate: _endDate!.toIso8601String().split('T').first,
        firstName: (formData['firstName'] ?? '').toString().trim().isEmpty
            ? null
            : (formData['firstName'] ?? '').toString().trim(),
        lastName: (formData['lastName'] ?? '').toString().trim().isEmpty
            ? null
            : (formData['lastName'] ?? '').toString().trim(),
        email: (formData['email'] ?? '').toString().trim().isEmpty
            ? null
            : (formData['email'] ?? '').toString().trim(),
        phone: (formData['phone'] ?? '').toString().trim().isEmpty
            ? null
            : (formData['phone'] ?? '').toString().trim(),
        mobile: (formData['mobile'] ?? '').toString().trim().isEmpty
            ? null
            : (formData['mobile'] ?? '').toString().trim(),
        imageBytes: _tenantImageBytes,
      );
    } else {
      ok = await context.read<TenantsCubit>().addTenant(
        partnerId: partnerId,
        unitId: _selectedUnitId!,
        tenantPartnerId: _selectedTenantPartnerId!,
        name: (formData['contractName'] ?? '').toString().trim().isEmpty
            ? null
            : (formData['contractName'] ?? '').toString().trim(),
        startDate: _startDate!.toIso8601String().split('T').first,
        endDate: _endDate!.toIso8601String().split('T').first,
      );
    }

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tenant added')));
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

  Widget _buildTenantDropdown() {
    final tenantItems = _tenantPartners
        .map((p) => _DropdownItem(p['id'] as int, p['name'] as String))
        .toList();
    final outlineColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.5);
    final fillColor = Theme.of(context).colorScheme.surfaceContainerLow;

    return FormField<_DropdownItem>(
      initialValue: _selectedTenantPartnerId != null
          ? _DropdownItem(
              _selectedTenantPartnerId!,
              _tenantPartners.firstWhere(
                    (p) => p['id'] == _selectedTenantPartnerId,
                  )['name']
                  as String,
            )
          : null,
      validator: (v) => _createNewTenant
          ? null
          : (v == null ? 'Please select a tenant' : null),
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
              hintText: 'Tenant',
              initialItem: field.value,
              items: tenantItems,
              onChanged: (value) {
                field.didChange(value);
                if (value != null)
                  setState(() => _selectedTenantPartnerId = value.id);
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
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUnitDropdown(),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _createNewTenant,
                  onChanged: (v) => setState(() {
                    _createNewTenant = v ?? false;
                    _selectedTenantPartnerId = null;
                  }),
                  title: const Text('Create new tenant'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (!_createNewTenant) ...[
                  _buildTenantDropdown(),
                ] else ...[
                  Row(
                    children: [
                      InkWell(
                        onTap: _pickTenantImage,
                        borderRadius: BorderRadius.circular(48),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(48),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _tenantImageBytes == null
                              ? const Icon(Icons.person)
                              : Image.memory(
                                  _tenantImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTenantImage,
                          icon: const Icon(Icons.photo_library),
                          label: Text(
                            _tenantImageBytes == null
                                ? 'Add tenant photo'
                                : 'Change photo',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'firstName',
                          decoration: InputDecoration(
                            labelText: 'First name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'lastName',
                          decoration: InputDecoration(
                            labelText: 'Last name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FormBuilderTextField(
                    name: 'email',
                    keyboardType: TextInputType.emailAddress,
                    validator: FormBuilderValidators.email(),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'phone',
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'mobile',
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Mobile (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'startDate',
                        initialValue: _formatDate(_startDate!),
                        readOnly: true,
                        onTap: _pickStartDate,
                        validator: FormBuilderValidators.required(),
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                          suffixIcon: const Icon(Icons.event),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'endDate',
                        readOnly: true,
                        onTap: _pickEndDate,
                        validator: FormBuilderValidators.required(),
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          suffixIcon: const Icon(Icons.event_available),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    onPressed: _submit,
                    minHeight: 48,
                    borderRadius: BorderRadius.circular(24),
                    child: Text(
                      _createNewTenant
                          ? 'Create Tenant & Contract'
                          : 'Add Tenant',
                    ),
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
