import 'package:flutter/material.dart';
import 'package:login_again/core/utils/formatters.dart';
import '../../data/contracts_repository.dart';
import 'info_box.dart';

class ContractCard extends StatelessWidget {
  final ContractDetails details;

  const ContractCard({super.key, required this.details});

  Color _stateColor(String s) {
    switch (s) {
      case 'active':
        return Colors.green;
      case 'done':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final sd = details.startDate;
    final ed = details.endDate;
    double progress = 0;
    String remainingLabel = '—';
    if (sd != null && ed != null) {
      final total = ed.difference(sd).inDays;
      final elapsed = now.difference(sd).inDays;
      progress = total > 0 ? (elapsed / total).clamp(0, 1) : 0;
      final today = DateTime(now.year, now.month, now.day);
      final endBase = DateTime(ed.year, ed.month, ed.day);
      final daysRemaining = endBase.difference(today).inDays;
      remainingLabel =
          '${daysRemaining >= 0 ? daysRemaining : 0} days remaining';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.teal.shade50,
                      child: Icon(Icons.apartment, color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details.propertyName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Unit ${details.unitName}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _stateColor(details.state).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    details.state.isEmpty
                        ? '—'
                        : details.state[0].toUpperCase() +
                              details.state.substring(1),
                    style: TextStyle(color: _stateColor(details.state)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Contract Progress',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(remainingLabel),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              color: scheme.primary,
              minHeight: 6,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InfoBox(
                    icon: Icons.calendar_today,
                    label: 'Start Date',
                    value: formatDate(details.startDate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InfoBox(
                    icon: Icons.event,
                    label: 'End Date',
                    value: formatDate(details.endDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InfoBox(
                    icon: Icons.attach_money,
                    label: 'Monthly Rent',
                    value: formatMoney(
                      details.rentAmount,
                      currencySymbol: details.currencySymbol,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InfoBox(
                    icon: Icons.home_outlined,
                    label: 'Unit',
                    value: details.unitName,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
