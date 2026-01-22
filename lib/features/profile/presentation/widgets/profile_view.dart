import 'package:flutter/material.dart';
import 'package:login_again/features/landlord/data/models/partner_profile.dart';
import 'package:login_again/theme/app_theme.dart';

/// Reusable profile display widget for both landlord and tenant profiles
class ProfileView extends StatelessWidget {
  final PartnerProfile? profile;
  final String? fallbackName;
  final String? userRole;
  final String? propertyContext;
  final String? unitContext;
  final String? statusBadge;
  final VoidCallback? onCallPressed;
  final VoidCallback? onEmailPressed;

  const ProfileView({
    super.key,
    this.profile,
    this.fallbackName,
    this.userRole,
    this.propertyContext,
    this.unitContext,
    this.statusBadge,
    this.onCallPressed,
    this.onEmailPressed,
  });

  String _initials(String name) {
    final parts = name
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  Color _statusColor(BuildContext context, String? s) {
    final scheme = Theme.of(context).colorScheme;
    switch (s) {
      case 'paid':
        return context.success;
      case 'pending':
        return context.warning;
      case 'overdue':
        return scheme.error;
      default:
        return Colors.grey;
    }
  }

  Widget _infoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(value.isEmpty ? '—' : value),
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (profile?.name.isNotEmpty == true)
        ? profile!.name
        : (fallbackName ?? 'User');

    final email = profile?.email ?? '';
    final phone = profile?.phone ?? '';
    final mobile = profile?.mobile ?? '';
    final street = profile?.street ?? '';
    final city = profile?.city ?? '';
    final country = profile?.country ?? '';

    final hasPhone = phone.isNotEmpty || mobile.isNotEmpty;
    final hasEmail = email.isNotEmpty;

    final addressParts = [
      street,
      city,
      country,
    ].where((e) => e.trim().isNotEmpty).toList();
    final address = addressParts.isEmpty ? '—' : addressParts.join(', ');

    final phoneValue = phone.isNotEmpty ? phone : mobile;
    final imageBytes = profile?.imageBytes;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Header Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.12),
                  backgroundImage: (imageBytes != null && imageBytes.isNotEmpty)
                      ? MemoryImage(imageBytes)
                      : null,
                  child: (imageBytes != null && imageBytes.isNotEmpty)
                      ? null
                      : Text(
                          _initials(name),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 18,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (userRole != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    userRole!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
                if (statusBadge != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(
                        context,
                        statusBadge,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusBadge!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(context, statusBadge),
                      ),
                    ),
                  ),
                ],
                if (propertyContext != null || unitContext != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (propertyContext != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.apartment,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            propertyContext!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  if (unitContext != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.door_front_door,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            unitContext!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),

        // Action Buttons (if callbacks provided)
        if (onCallPressed != null || onEmailPressed != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (onCallPressed != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasPhone ? onCallPressed : null,
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                  ),
                ),
              if (onCallPressed != null && onEmailPressed != null)
                const SizedBox(width: 12),
              if (onEmailPressed != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasEmail ? onEmailPressed : null,
                    icon: const Icon(Icons.mail),
                    label: const Text('Email'),
                  ),
                ),
            ],
          ),
        ],

        // Contact Information Card
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _infoTile(
                context: context,
                icon: Icons.mail,
                title: 'Email',
                value: email,
              ),
              const Divider(height: 1),
              _infoTile(
                context: context,
                icon: Icons.phone,
                title: 'Phone',
                value: phoneValue,
              ),
              const Divider(height: 1),
              _infoTile(
                context: context,
                icon: Icons.home_outlined,
                title: 'Address',
                value: address,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
