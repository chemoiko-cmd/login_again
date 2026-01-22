import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
import 'package:login_again/features/landlord/presentation/cubit/tenants_cubit.dart';
import 'package:login_again/core/widgets/app_loading_indicator.dart';

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
  final _nameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();

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
    _loadDropdowns();
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    final repo = context.read<TenantsCubit>().repository;
    final units = await repo.fetchUnits(partnerId: widget.partnerId);
    final tenants = await repo.fetchTenantPartners();
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
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedUnitId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a unit')));
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick start and end dates')),
      );
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }
    bool ok = false;
    if (_createNewTenant) {
      // Minimal validation: need at least a first or last name
      if (_firstNameCtrl.text.trim().isEmpty &&
          _lastNameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter tenant name')),
        );
        return;
      }
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
      );
    } else {
      if (_selectedTenantPartnerId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a tenant')));
        return;
      }

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
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: AppLoadingIndicator(),
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
                          CheckboxListTile(
                            value: _createNewTenant,
                            onChanged: (v) =>
                                setState(() => _createNewTenant = v ?? false),
                            title: const Text('Create new tenant'),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (!_createNewTenant) ...[
                            DropdownButtonFormField<int>(
                              value: _selectedTenantPartnerId,
                              onChanged: (v) =>
                                  setState(() => _selectedTenantPartnerId = v),
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
                                Expanded(
                                  child: TextField(
                                    controller: _firstNameCtrl,
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
                                  child: TextField(
                                    controller: _lastNameCtrl,
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
                            TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
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
                                  child: TextField(
                                    controller: _phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'Phone (optional)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _mobileCtrl,
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
                          TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Contract reference (optional)',
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
                                  onPressed: _pickStartDate,
                                  minHeight: 48,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.event),
                                      const SizedBox(width: 8),
                                      Text(
                                        _startDate == null
                                            ? 'Start Date (optional)'
                                            : _startDate!
                                                  .toIso8601String()
                                                  .split('T')
                                                  .first,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GradientOutlinedButton(
                                  onPressed: _pickEndDate,
                                  minHeight: 48,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.event_available),
                                      const SizedBox(width: 8),
                                      Text(
                                        _endDate == null
                                            ? 'End Date (optional)'
                                            : _endDate!
                                                  .toIso8601String()
                                                  .split('T')
                                                  .first,
                                      ),
                                    ],
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
    );
  }
}
