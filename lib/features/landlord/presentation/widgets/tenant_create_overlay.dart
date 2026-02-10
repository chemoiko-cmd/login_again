import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
import 'package:login_again/features/landlord/presentation/cubit/tenants_cubit.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;
import 'dart:typed_data';

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
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  final _nameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();

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
    _startDateCtrl.text = _formatDate(_startDate!);
    _loadDropdowns();
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

  bool _isValidEmail(String v) {
    final value = v.trim();
    if (value.isEmpty) return true;
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value);
  }

  bool _isValidPhoneOptional(String v) {
    final value = v.trim();
    if (value.isEmpty) return true;
    final digitsOnly = RegExp(r'^\d+$');
    if (!digitsOnly.hasMatch(value)) return false;
    return value.length >= 9 && value.length <= 10;
  }

  String? _validateDateRange() {
    if (_startDate == null) return 'Please select a start date';
    if (_endDate == null) return 'Please select an end date';
    if (!_endDate!.isAfter(_startDate!)) {
      return 'End date must be after start date';
    }
    return null;
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
        _endDateCtrl.text = _formatDate(picked);
      });
      if (_autoValidateMode != AutovalidateMode.disabled) {
        _formKey.currentState?.validate();
      }
    }
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    _nameCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _mobileCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
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
        _startDateCtrl.text = _formatDate(picked);
        if (_endDate != null && !_endDate!.isAfter(picked)) {
          _endDate = null;
          _endDateCtrl.text = '';
        }
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
    bool ok = false;
    if (_createNewTenant) {
      ok = await context.read<TenantsCubit>().createTenantAndContract(
        partnerId: widget.partnerId,
        unitId: _selectedUnitId!,
        contractName: _nameCtrl.text.trim().isEmpty
            ? null
            : _nameCtrl.text.trim(),
        startDate: _startDate!.toIso8601String().split('T').first,
        endDate: _endDate!.toIso8601String().split('T').first,
        firstName: _firstNameCtrl.text.trim().isEmpty
            ? null
            : _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim().isEmpty
            ? null
            : _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim().isEmpty
            ? null
            : _mobileCtrl.text.trim(),
        imageBytes: _tenantImageBytes,
      );
    } else {
      ok = await context.read<TenantsCubit>().addTenant(
        partnerId: widget.partnerId,
        unitId: _selectedUnitId!,
        tenantPartnerId: _selectedTenantPartnerId!,
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
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
                            CheckboxListTile(
                              value: _createNewTenant,
                              onChanged: (v) {
                                setState(() {
                                  _createNewTenant = v ?? false;
                                  _selectedTenantPartnerId = null;
                                });
                                if (_autoValidateMode !=
                                    AutovalidateMode.disabled) {
                                  _formKey.currentState?.validate();
                                }
                              },
                              title: const Text('Create new tenant'),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (!_createNewTenant) ...[
                              DropdownButtonFormField<int>(
                                value: _selectedTenantPartnerId,
                                onChanged: (v) => setState(
                                  () => _selectedTenantPartnerId = v,
                                ),
                                validator: (v) {
                                  if (_createNewTenant) return null;
                                  if (v == null)
                                    return 'Please select a tenant';
                                  return null;
                                },
                                items: _tenantPartners
                                    .map(
                                      (p) => DropdownMenuItem<int>(
                                        value: p['id'] as int,
                                        child: Text(p['name'] as String),
                                      ),
                                    )
                                    .toList(),
                                decoration: InputDecoration(
                                  labelText: 'Tenant',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
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
                                    child: TextFormField(
                                      controller: _firstNameCtrl,
                                      validator: (v) {
                                        if (!_createNewTenant) return null;
                                        if (_firstNameCtrl.text
                                                .trim()
                                                .isEmpty &&
                                            _lastNameCtrl.text.trim().isEmpty) {
                                          return 'Enter first or last name';
                                        }
                                        return null;
                                      },
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
                                    child: TextFormField(
                                      controller: _lastNameCtrl,
                                      validator: (v) {
                                        if (!_createNewTenant) return null;
                                        if (_firstNameCtrl.text
                                                .trim()
                                                .isEmpty &&
                                            _lastNameCtrl.text.trim().isEmpty) {
                                          return 'Enter first or last name';
                                        }
                                        return null;
                                      },
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
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (!_createNewTenant) return null;
                                  if (v == null) return null;
                                  return _isValidEmail(v)
                                      ? null
                                      : 'Enter a valid email';
                                },
                                decoration: InputDecoration(
                                  labelText: 'Email (optional)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      validator: (v) {
                                        if (!_createNewTenant) return null;
                                        if (v == null) return null;
                                        return _isValidPhoneOptional(v)
                                            ? null
                                            : 'Phone must be 9-10 digits';
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Phone (optional)',
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
                                    child: TextFormField(
                                      controller: _mobileCtrl,
                                      keyboardType: TextInputType.phone,
                                      validator: (v) {
                                        if (!_createNewTenant) return null;
                                        if (v == null) return null;
                                        return _isValidPhoneOptional(v)
                                            ? null
                                            : 'Mobile must be 9-10 digits';
                                      },
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

                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _startDateCtrl,
                                    readOnly: true,
                                    onTap: _pickStartDate,
                                    validator: (v) => _validateDateRange(),
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
                                  child: TextFormField(
                                    controller: _endDateCtrl,
                                    readOnly: true,
                                    onTap: _pickEndDate,
                                    validator: (v) => _validateDateRange(),
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
