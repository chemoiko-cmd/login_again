import 'package:flutter/material.dart';
import 'package:login_again/features/subscription/presentation/widgets/pricing_card.dart';

enum _SubscriptionTab { myPlans, allPlans }

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  _SubscriptionTab _tab = _SubscriptionTab.allPlans;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildToggle(context),
          const SizedBox(height: 16),
          if (_tab == _SubscriptionTab.myPlans)
            _buildMyPlans(context)
          else
            _buildAllPlans(context),
        ],
      ),
    );
  }

  Widget _buildToggle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              selected: _tab == _SubscriptionTab.myPlans,
              label: 'My Plans',
              onTap: () => setState(() => _tab = _SubscriptionTab.myPlans),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              selected: _tab == _SubscriptionTab.allPlans,
              label: 'All Plans',
              onTap: () => setState(() => _tab = _SubscriptionTab.allPlans),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPlans(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No active subscription',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Switch to All Plans to choose a plan.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAllPlans(BuildContext context) {
    return const PricingSection();
  }
}

class _ToggleChip extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? scheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
