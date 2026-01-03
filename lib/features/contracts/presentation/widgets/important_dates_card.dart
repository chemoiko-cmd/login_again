import 'package:flutter/material.dart';

class ImportantDatesCard extends StatelessWidget {
  final String dateText;
  final String title;
  final String subtitle;

  const ImportantDatesCard({
    super.key,
    required this.dateText,
    this.title = 'Contract Expiration',
    this.subtitle = 'Current term ends',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: Text(
              dateText,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
