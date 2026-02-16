import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
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
  final _formKey = GlobalKey<FormBuilderState>();

  final _imagePicker = ImagePicker();
  Uint8List? _photoBytes;

  bool _submitting = false;

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final auth = context.read<AuthCubit>().state;
    if (auth is! Authenticated || !auth.isLandlord) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in as a landlord')),
      );
      return;
    }

    final formData = _formKey.currentState!.value;
    final name = (formData['name'] ?? '').toString().trim();
    final email = (formData['email'] ?? '').toString().trim();
    final phone = (formData['phone'] ?? '').toString().trim();
    final street = (formData['street'] ?? '').toString().trim();

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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/landlord-maintainers');
            }
          },
        ),
        title: const Text('Add Maintainer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              FormBuilderTextField(
                name: 'name',
                textInputAction: TextInputAction.next,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                ]),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FormBuilderTextField(
                name: 'email',
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                validator: FormBuilderValidators.compose([
                  (value) {
                    final email = (value ?? '').toString().trim();
                    final phone = _formKey.currentState?.fields['phone']?.value?.toString().trim() ?? '';
                    if (email.isEmpty && phone.isEmpty) {
                      return 'Email or phone is required';
                    }
                    if (email.isNotEmpty) {
                      return FormBuilderValidators.email()(email);
                    }
                    return null;
                  },
                ]),
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FormBuilderTextField(
                name: 'phone',
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                validator: FormBuilderValidators.compose([
                  (value) {
                    final phone = (value ?? '').toString().trim();
                    final email = _formKey.currentState?.fields['email']?.value?.toString().trim() ?? '';
                    if (phone.isEmpty && email.isEmpty) {
                      return 'Email or phone is required';
                    }
                    if (phone.isNotEmpty) {
                      if (!RegExp(r'^\d+$').hasMatch(phone)) {
                        return 'Phone must contain only digits';
                      }
                      if (phone.length != 10) {
                        return 'Phone number must be exactly 10 digits';
                      }
                    }
                    return null;
                  },
                ]),
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              FormBuilderTextField(
                name: 'street',
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
