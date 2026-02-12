import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/landlord/data/repositories/landlord_repository.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;

class AddMaintainerScreen extends StatefulWidget {
  const AddMaintainerScreen({super.key});

  @override
  State<AddMaintainerScreen> createState() => _AddMaintainerScreenState();
}

class _AddMaintainerScreenState extends State<AddMaintainerScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();

  final _imagePicker = ImagePicker();
  Uint8List? _photoBytes;

  bool _submitting = false;

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final x = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() => _photoBytes = bytes);
    } catch (_) {}
  }

  bool _isValidEmail(String v) {
    final s = v.trim();
    if (s.isEmpty) return true;
    return s.contains('@') && s.contains('.');
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;

    if (_autoValidateMode == AutovalidateMode.disabled) {
      setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
    }

    final valid = form.validate();
    if (!valid) return;

    final auth = context.read<AuthCubit>().state;
    if (auth is! Authenticated || !auth.isLandlord) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in as a landlord')),
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final street = _streetCtrl.text.trim();

    setState(() => _submitting = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      loading.Widgets.showLoader(context);
    });

    try {
      final repo = LandlordRepository(
        apiClient: context.read<AuthCubit>().apiClient,
      );
      final res = await repo.createMaintainer(
        name: name,
        email: email.isEmpty ? null : email,
        phone: phone.isEmpty ? null : phone,
        street: street.isEmpty ? null : street,
        imageBase64: (_photoBytes != null && _photoBytes!.isNotEmpty)
            ? base64Encode(_photoBytes!)
            : null,
      );

      if (!mounted) return;
      loading.Widgets.hideLoader(context);

      if (res == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create maintainer')),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maintainer added')));

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      loading.Widgets.hideLoader(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Maintainer',
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12),
                    backgroundImage:
                        (_photoBytes != null && _photoBytes!.isNotEmpty)
                        ? MemoryImage(_photoBytes!)
                        : null,
                    child: (_photoBytes != null && _photoBytes!.isNotEmpty)
                        ? null
                        : const Icon(Icons.add_a_photo_outlined, size: 22),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Please enter a name';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty && _phoneCtrl.text.trim().isEmpty) {
                    return 'Email or phone is required';
                  }
                  if (!_isValidEmail(value)) return 'Enter a valid email';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty && _emailCtrl.text.trim().isEmpty) {
                    return 'Email or phone is required';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _streetCtrl,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Street',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onPressed: _submitting ? null : _submit,
                  borderRadius: BorderRadius.circular(24),
                  child: const Text('Create Maintainer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
