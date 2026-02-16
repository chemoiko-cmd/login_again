import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
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
      other is _DropdownItem && runtimeType == other.runtimeType && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

class TenantCreateOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final int partnerId; // landlord partner id

  const TenantCreateOverlay({
    super.key,
    required this.onClose,
    required this.partnerId,
  });

  @override
  State<TenantCreateOverlay> createState() => _TenantCreateOverlayState();
}

class _TenantCreateOverlayState extends State<TenantCreateOverlay> {
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
        // Keep the visible form field in sync with the picked value
        _formKey.currentState?.fields['endDate']
            ?.didChange(_formatDate(picked));
      });
    }
  }

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
    final repo = context.read<TenantsCubit>().repository;
    final units = await repo.fetchUnits(partnerId: widget.partnerId);
    final tenants = await repo.fetchTenantPartnersForLandlord(
      partnerId: widget.partnerId,
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
        _formKey.currentState?.fields['startDate']?.didChange(_formatDate(picked));
        if (_endDate != null && !_endDate!.isAfter(picked)) {
          _endDate = null;
          _formKey.currentState?.fields['endDate']?.didChange('');
        }
      });
    }
  }


  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    
    if (_startDate == null || _endDate == null) return;
    if (!_endDate!.isAfter(_startDate!)) return;

    final formData = _formKey.currentState!.value;
    bool ok = false;
    if (_createNewTenant) {
      ok = await context.read<TenantsCubit>().createTenantAndContract(
        partnerId: widget.partnerId,
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
        partnerId: widget.partnerId,
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
      widget.onClose();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tenant added')));
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
                                'Add Tenant',
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
                                        hintText: 'Unit',
                                        initialItem: field.value,
                                        items: unitItems,
                                        validateOnChange: true,
                                        validator: (value) => value == null ? 'Please select a unit' : null,
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
                            CheckboxListTile(
                              value: _createNewTenant,
                              onChanged: (v) {
                                setState(() {
                                  _createNewTenant = v ?? false;
                                  _selectedTenantPartnerId = null;
                                });
                                _formKey.currentState?.fields['tenant']?.didChange(null);
                              },
                              title: const Text('Create new tenant'),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (!_createNewTenant) ...[
                              FormField<_DropdownItem>(
                                initialValue: _selectedTenantPartnerId != null
                                    ? _DropdownItem(_selectedTenantPartnerId!, _tenantPartners.firstWhere((p) => p['id'] == _selectedTenantPartnerId)['name'] as String)
                                    : null,
                                validator: (v) {
                                  if (_createNewTenant) return null;
                                  if (v == null) return 'Please select a tenant';
                                  return null;
                                },
                                builder: (field) {
                                  final tenantItems = _tenantPartners.map((p) => _DropdownItem(p['id'] as int, p['name'] as String)).toList();
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
                                          hintText: 'Tenant',
                                          initialItem: field.value,
                                          items: tenantItems,
                                          validateOnChange: true,
                                          validator: (value) => value == null ? 'Please select a tenant' : null,
                                          onChanged: (value) {
                                            field.didChange(value);
                                            if (value != null) {
                                              setState(() => _selectedTenantPartnerId = value.id);
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
                                      enabled: _createNewTenant,
                                      validator: FormBuilderValidators.compose([
                                        if (_createNewTenant)
                                          (value) {
                                            final firstName = (value ?? '').toString().trim();
                                            final lastName = _formKey.currentState?.fields['lastName']?.value?.toString().trim() ?? '';
                                            if (firstName.isEmpty && lastName.isEmpty) {
                                              return 'Enter first or last name';
                                            }
                                            return null;
                                          },
                                      ]),
                                      decoration: InputDecoration(
                                        labelText: 'First name',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FormBuilderTextField(
                                      name: 'lastName',
                                      enabled: _createNewTenant,
                                      validator: FormBuilderValidators.compose([
                                        if (_createNewTenant)
                                          (value) {
                                            final lastName = (value ?? '').toString().trim();
                                            final firstName = _formKey.currentState?.fields['firstName']?.value?.toString().trim() ?? '';
                                            if (firstName.isEmpty && lastName.isEmpty) {
                                              return 'Enter first or last name';
                                            }
                                            return null;
                                          },
                                      ]),
                                      decoration: InputDecoration(
                                        labelText: 'Last name',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              FormBuilderTextField(
                                name: 'email',
                                enabled: _createNewTenant,
                                keyboardType: TextInputType.emailAddress,
                                validator: FormBuilderValidators.compose([
                                  if (_createNewTenant)
                                    FormBuilderValidators.email(),
                                ]),
                                decoration: InputDecoration(
                                  labelText: 'Email ',
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
                                      enabled: _createNewTenant,
                                      keyboardType: TextInputType.phone,
                                      validator: FormBuilderValidators.compose([
                                        if (_createNewTenant)
                                          FormBuilderValidators.compose([
                                            FormBuilderValidators.numeric(),
                                            FormBuilderValidators.equalLength(
                                              10,
                                              errorText:
                                                  'Phone number must be exactly 10 digits',
                                            ),
                                          ]),
                                      ]),
                                      decoration: InputDecoration(
                                        labelText: 'Phone ',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FormBuilderTextField(
                                      name: 'mobile',
                                      enabled: _createNewTenant,
                                      keyboardType: TextInputType.phone,
                                      validator: FormBuilderValidators.compose([
                                        if (_createNewTenant)
                                          (value) {
                                            final mobile =
                                                (value ?? '').toString().trim();
                                            if (mobile.isEmpty) return null;
                                            if (!RegExp(r'^\d+$')
                                                .hasMatch(mobile)) {
                                              return 'Mobile must contain only digits';
                                            }
                                            if (mobile.length != 10) {
                                              return 'Mobile number must be exactly 10 digits';
                                            }
                                            return null;
                                          },
                                      ]),
                                      decoration: InputDecoration(
                                        labelText: 'Mobile (optional)',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      (value) {
                                        if (_endDate != null && !_endDate!.isAfter(_startDate!)) {
                                          return 'End date must be after start date';
                                        }
                                        return null;
                                      },
                                    ]),
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
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      (value) {
                                        if (_startDate != null && _endDate != null && !_endDate!.isAfter(_startDate!)) {
                                          return 'End date must be after start date';
                                        }
                                        return null;
                                      },
                                    ]),
                                    decoration: InputDecoration(
                                      labelText: 'End Date',
                                      suffixIcon: const Icon(
                                        Icons.event_available,
                                      ),
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
