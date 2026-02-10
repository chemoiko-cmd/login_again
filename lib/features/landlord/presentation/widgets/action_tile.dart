import 'package:flutter/material.dart';
import 'package:login_again/core/utils/formatters.dart';
import 'package:login_again/core/widgets/glass_surface.dart';
import 'dart:typed_data';

class ActionTile extends StatelessWidget {
  final IconData icon;
  final List<int>? avatarBytes;
  final String title;
  final String subtitle;
  final String? state; // just the string from your Inspection model
  final VoidCallback? onTap;

  const ActionTile({
    super.key,
    required this.icon,
    this.avatarBytes,
    required this.title,
    required this.subtitle,
    this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassSurface(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.10),
          backgroundImage: (avatarBytes != null && avatarBytes!.isNotEmpty)
              ? MemoryImage(Uint8List.fromList(avatarBytes!))
              : null,
          child: (avatarBytes != null && avatarBytes!.isNotEmpty)
              ? null
              : Icon(icon, color: scheme.primary),
        ),
        title: Row(
          children: [
            Expanded(child: Text(title)),
            if (state != null)
              Chip(
                label: Text(
                  formatStateLabel(state),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: stateBadgeColor(state),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
