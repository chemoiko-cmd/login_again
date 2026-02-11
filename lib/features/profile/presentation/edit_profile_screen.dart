import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_again/core/widgets/glass_surface.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:login_again/features/auth/presentation/cubit/auth_state.dart';
import 'package:login_again/features/landlord/data/models/partner_profile.dart';
import 'package:login_again/features/profile/data/profile_repository.dart';
import 'package:login_again/styles/loading/widgets.dart' as loading;

class EditProfileScreen extends StatefulWidget {
  final PartnerProfile? initialProfile;

  const EditProfileScreen({super.key, this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;

  bool _saving = false;
  Uint8List? _pickedAvatarBytes;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _emailCtrl = TextEditingController(text: p?.email ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _mobileCtrl = TextEditingController(text: p?.mobile ?? '');
    _streetCtrl = TextEditingController(text: p?.street ?? '');
    _cityCtrl = TextEditingController(text: p?.city ?? '');
  }

  Future<void> _pickAvatar() async {
    if (_saving) return;

    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        imageQuality: 85,
      );
      if (img == null) return;

      final bytes = await img.readAsBytes();
      if (!mounted) return;
      setState(() => _pickedAvatarBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  @override
  void dispose() {
    loading.Widgets.hideLoader(context);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _mobileCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final authState = context.read<AuthCubit>().state;
    final partnerId = authState is Authenticated ? authState.user.partnerId : 0;
    if (partnerId == 0) return;

    setState(() => _saving = true);
    loading.Widgets.showLoader(context);

    try {
      final repo = ProfileRepository(
        apiClient: context.read<AuthCubit>().apiClient,
      );

      final values = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'street': _streetCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
      };

      if (_pickedAvatarBytes != null && _pickedAvatarBytes!.isNotEmpty) {
        values['image_128'] = base64Encode(_pickedAvatarBytes!);
      }

      final ok = await repo.updatePartnerProfile(
        partnerId: partnerId,
        values: values,
      );

      if (!mounted) return;

      if (ok) {
        loading.Widgets.hideLoader(context);
        context.pop(true);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (!mounted) return;
      loading.Widgets.hideLoader(context);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatarBytes = _pickedAvatarBytes ?? widget.initialProfile?.imageBytes;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Edit Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassSurface(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: _saving ? null : _pickAvatar,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: scheme.primary.withValues(
                            alpha: 0.10,
                          ),
                          backgroundImage: avatarBytes != null
                              ? MemoryImage(avatarBytes)
                              : null,
                          child: avatarBytes == null
                              ? Icon(
                                  Icons.person_outline,
                                  color: scheme.primary,
                                  size: 30,
                                )
                              : null,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor
                                    .withValues(alpha: 0.6),
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              size: 16,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  readOnly: true,
                  enabled: !_saving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        enabled: !_saving,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _mobileCtrl,
                        enabled: !_saving,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _streetCtrl,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Street',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cityCtrl,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
