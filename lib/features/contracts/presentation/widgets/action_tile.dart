import 'package:flutter/material.dart';

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          child: Icon(icon, color: scheme.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
