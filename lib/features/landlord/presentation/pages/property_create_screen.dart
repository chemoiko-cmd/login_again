import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/landlord/data/repositories/landlord_repository.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;
import 'dart:typed_data';

class PropertyCreateScreen extends StatefulWidget {
  const PropertyCreateScreen({super.key});

  @override
  State<PropertyCreateScreen> createState() => _PropertyCreateScreenState();
}

class _PropertyCreateScreenState extends State<PropertyCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _latitudeCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();
  final _totalUnitsCtrl = TextEditingController();
  final _bedroomsCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();

  final _imagePicker = ImagePicker();
  Uint8List? _imageBytes;

  bool _submitting = false;

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    _totalUnitsCtrl.dispose();
    _bedroomsCtrl.dispose();
    _rentCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) {
      setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final ownerPartnerId = authState.user.partnerId;

    final name = _nameCtrl.text.trim();

    final rentRaw = _rentCtrl.text.trim();
    final rent = double.tryParse(rentRaw)!;

    final depositRaw = _depositCtrl.text.trim();
    final deposit = double.tryParse(depositRaw)!;

    final totalUnitsRaw = _totalUnitsCtrl.text.trim();
    int? totalUnits;
    if (totalUnitsRaw.isNotEmpty) {
      totalUnits = int.tryParse(totalUnitsRaw);
    }

    final bedroomsRaw = _bedroomsCtrl.text.trim();
    int? bedrooms;
    if (bedroomsRaw.isNotEmpty) {
      bedrooms = int.tryParse(bedroomsRaw);
    }

    final latitudeRaw = _latitudeCtrl.text.trim();
    double? latitude;
    if (latitudeRaw.isNotEmpty) {
      latitude = double.tryParse(latitudeRaw);
    }

    final longitudeRaw = _longitudeCtrl.text.trim();
    double? longitude;
    if (longitudeRaw.isNotEmpty) {
      longitude = double.tryParse(longitudeRaw);
    }

    if (_submitting) return;

    setState(() => _submitting = true);
    loading.Widgets.showLoader(context);

    try {
      final auth = context.read<AuthCubit>();
      final repo = LandlordRepository(apiClient: auth.apiClient);
      final propertyId = await repo.createPropertyReturningId(
        ownerPartnerId: ownerPartnerId,
        name: name,
        defaultRentAmount: rent,
        defaultDepositAmount: deposit,
        imageBytes: _imageBytes,
        code: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
        street: _streetCtrl.text.trim().isEmpty
            ? null
            : _streetCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        geoLat: latitude,
        geoLong: longitude,
      );

      var ok = propertyId != null;
      if (ok && totalUnits != null && totalUnits > 0) {
        ok = await repo.generateUnitsForProperty(
          propertyId: propertyId,
          propertyName: name,
          totalUnits: totalUnits,
          roomCount: bedrooms,
        );
      }

      if (!mounted) return;
      loading.Widgets.hideLoader(context);
      setState(() => _submitting = false);

      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Property added')));
        context.pop(true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add property')));
      }
    } catch (_) {
      if (!mounted) return;
      loading.Widgets.hideLoader(context);
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add property')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

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
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Property name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) {
                      return 'Please enter property name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _submitting
                      ? null
                      : () async {
                          final picked = await _imagePicker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 640,
                            imageQuality: 70,
                          );
                          if (picked == null) return;
                          final bytes = await picked.readAsBytes();
                          if (!mounted) return;
                          setState(() => _imageBytes = bytes);
                        },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 54,
                            height: 54,
                            color: Colors.black.withValues(alpha: 0.06),
                            child: _imageBytes == null
                                ? const Icon(Icons.camera_alt_outlined)
                                : Image.memory(_imageBytes!, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Property picture',
                                style: t.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _imageBytes == null
                                    ? 'Tap to select from gallery'
                                    : 'Tap to change',
                                style: t.bodySmall?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_imageBytes != null) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: 'Remove picture',
                            onPressed: _submitting
                                ? null
                                : () => setState(() => _imageBytes = null),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _streetCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Street',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) {
                      return 'Please enter street';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'City ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) {
                      return 'Please enter city';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _totalUnitsCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Total units',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _submitting
                                    ? null
                                    : () {
                                        final current =
                                            int.tryParse(
                                              _totalUnitsCtrl.text.trim(),
                                            ) ??
                                            0;
                                        _totalUnitsCtrl.text = (current + 1)
                                            .toString();
                                        if (_autoValidateMode !=
                                            AutovalidateMode.disabled) {
                                          _formKey.currentState?.validate();
                                        }
                                      },
                                child: const Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 20,
                                ),
                              ),
                              InkWell(
                                onTap: _submitting
                                    ? null
                                    : () {
                                        final current =
                                            int.tryParse(
                                              _totalUnitsCtrl.text.trim(),
                                            ) ??
                                            0;
                                        if (current > 0) {
                                          _totalUnitsCtrl.text = (current - 1)
                                              .toString();
                                          if (_autoValidateMode !=
                                              AutovalidateMode.disabled) {
                                            _formKey.currentState?.validate();
                                          }
                                        }
                                      },
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) {
                            return 'Please enter total units';
                          }
                          final parsed = int.tryParse(value);
                          if (parsed == null || parsed <= 0) {
                            return 'Total units must be a positive number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _bedroomsCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Bedrooms',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _submitting
                                    ? null
                                    : () {
                                        final current =
                                            int.tryParse(
                                              _bedroomsCtrl.text.trim(),
                                            ) ??
                                            0;
                                        _bedroomsCtrl.text = (current + 1)
                                            .toString();
                                        if (_autoValidateMode !=
                                            AutovalidateMode.disabled) {
                                          _formKey.currentState?.validate();
                                        }
                                      },
                                child: const Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 20,
                                ),
                              ),
                              InkWell(
                                onTap: _submitting
                                    ? null
                                    : () {
                                        final current =
                                            int.tryParse(
                                              _bedroomsCtrl.text.trim(),
                                            ) ??
                                            0;
                                        if (current > 0) {
                                          _bedroomsCtrl.text = (current - 1)
                                              .toString();
                                          if (_autoValidateMode !=
                                              AutovalidateMode.disabled) {
                                            _formKey.currentState?.validate();
                                          }
                                        }
                                      },
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) {
                            return 'Please enter bedrooms';
                          }
                          final parsed = int.tryParse(value);
                          if (parsed == null || parsed <= 0) {
                            return 'Bedrooms must be a positive number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rentCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Property rent',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    final rent = double.tryParse(value);
                    if (rent == null || rent <= 0) {
                      return 'Please enter a valid rent amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _depositCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Security deposit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    final deposit = double.tryParse(value);
                    if (deposit == null || deposit < 0) {
                      return 'Please enter a valid deposit amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    onPressed: _submitting ? null : _submit,
                    minHeight: 48,
                    borderRadius: BorderRadius.circular(24),
                    child: const Text('Create Property'),
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
