import 'package:flutter/material.dart';
import 'package:login_again/core/utils/formatters.dart';

class RentCard extends StatelessWidget {
  final double totalCollected;
  final double totalOverall; // total overall rent
  final String currency; // new: pass currency symbol
  final IconData icon;

  // Static gradient colors
  static const Color secondary = Color(0xFF4BACF7);
  static const Color secondaryDark = Color(0xFF3391E6);

  const RentCard({
    Key? key,
    required this.totalCollected,
    required this.totalOverall,
    this.currency = 'UGX', // default to UGX
    this.icon = Icons.credit_card,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double collectionRate = totalOverall > 0
        ? (totalCollected / totalOverall) * 100
        : 0.0;
    final double progress = totalOverall > 0
        ? (totalCollected / totalOverall)
        : 0.0;

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [secondary, secondaryDark],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: title + icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Rent Collected',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatCurrency(
                          totalCollected,
                          currencySymbol: currency,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Bottom row: overall total + percentage badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Expected: ${formatCurrency(totalOverall, currencySymbol: currency)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${collectionRate.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
