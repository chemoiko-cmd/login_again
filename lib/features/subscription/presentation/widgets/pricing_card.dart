import 'package:flutter/material.dart';

class Feature {
  final String text;
  final bool included;

  const Feature({required this.text, required this.included});
}

class DiscountCode {
  final String code;
  final double amount;
  final String expiryDate;

  const DiscountCode({
    required this.code,
    required this.amount,
    required this.expiryDate,
  });
}

enum PricingTier { bronze, silver, gold }

class PricingPlan {
  final String name;
  final String code;
  final String description;
  final String price;
  final String priceSubtext;
  final PricingTier tier;
  final IconData icon;
  final List<Feature> features;
  final String ctaText;
  final bool featured;
  final String? badge;
  final DiscountCode? discountCode;

  const PricingPlan({
    required this.name,
    required this.code,
    required this.description,
    required this.price,
    required this.priceSubtext,
    required this.tier,
    required this.icon,
    required this.features,
    required this.ctaText,
    this.featured = false,
    this.badge,
    this.discountCode,
  });
}

class TierStyles {
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;
  final Color buttonColor;
  final Color buttonHoverColor;
  final Color buttonTextColor;
  final Color badgeColor;
  final Color checkBgColor;
  final Color checkIconColor;

  const TierStyles({
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
    required this.buttonColor,
    required this.buttonHoverColor,
    required this.buttonTextColor,
    required this.badgeColor,
    required this.checkBgColor,
    required this.checkIconColor,
  });

  static const bronze = TierStyles(
    borderColor: Color.fromARGB(255, 153, 102, 51),
    backgroundColor: Color.fromARGB(255, 245, 230, 214),
    textColor: Color.fromARGB(255, 112, 75, 38),
    buttonColor: Color.fromARGB(255, 153, 102, 51),
    buttonHoverColor: Color.fromARGB(255, 133, 89, 44),
    buttonTextColor: Colors.white,
    badgeColor: Color.fromARGB(255, 153, 102, 51),
    checkBgColor: Color.fromARGB(255, 242, 224, 204),
    checkIconColor: Color.fromARGB(255, 133, 89, 44),
  );

  static const silver = TierStyles(
    borderColor: Color.fromARGB(255, 133, 137, 143),
    backgroundColor: Color.fromARGB(255, 238, 239, 240),
    textColor: Color.fromARGB(255, 97, 100, 105),
    buttonColor: Color.fromARGB(255, 133, 137, 143),
    buttonHoverColor: Color.fromARGB(255, 107, 111, 117),
    buttonTextColor: Colors.white,
    badgeColor: Color.fromARGB(255, 133, 137, 143),
    checkBgColor: Color.fromARGB(255, 227, 229, 230),
    checkIconColor: Color.fromARGB(255, 107, 111, 117),
  );

  static const gold = TierStyles(
    borderColor: Color.fromARGB(255, 242, 194, 13),
    backgroundColor: Color.fromARGB(255, 250, 243, 224),
    textColor: Color.fromARGB(255, 112, 90, 11),
    buttonColor: Color.fromARGB(255, 242, 194, 13),
    buttonHoverColor: Color.fromARGB(255, 217, 174, 12),
    buttonTextColor: Color.fromARGB(255, 38, 31, 5),
    badgeColor: Color.fromARGB(255, 242, 194, 13),
    checkBgColor: Color.fromARGB(255, 247, 233, 199),
    checkIconColor: Color.fromARGB(255, 133, 107, 13),
  );

  static TierStyles fromTier(PricingTier tier) {
    switch (tier) {
      case PricingTier.bronze:
        return bronze;
      case PricingTier.silver:
        return silver;
      case PricingTier.gold:
        return gold;
    }
  }
}

class PricingCard extends StatefulWidget {
  final PricingPlan plan;
  final VoidCallback? onTap;

  const PricingCard({super.key, required this.plan, this.onTap});

  @override
  State<PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<PricingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final styles = TierStyles.fromTier(widget.plan.tier);
    final scale = widget.plan.featured ? 1.02 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        offset: _isHovered ? const Offset(0, -0.02) : Offset.zero,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.plan.featured
                    ? styles.borderColor
                    : Theme.of(context).dividerColor,
                width: 2,
              ),
              boxShadow: [
                if (widget.plan.featured)
                  BoxShadow(
                    color: styles.borderColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: _isHovered ? 24 : 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, styles),
                      const SizedBox(height: 24),
                      _buildPrice(context),
                      const SizedBox(height: 24),
                      _buildFeatures(context, styles),
                      const SizedBox(height: 32),
                      _buildButton(context, styles),
                    ],
                  ),
                ),
                if (widget.plan.badge != null) _buildBadge(styles),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TierStyles styles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: styles.checkBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.plan.icon, size: 20, color: styles.textColor),
            ),
            const SizedBox(width: 8),
            Text(
              widget.plan.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: styles.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.plan.description,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPrice(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          widget.plan.price,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          widget.plan.priceSubtext,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures(BuildContext context, TierStyles styles) {
    return Column(
      children: widget.plan.features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: feature.included
                          ? styles.checkBgColor
                          : Theme.of(context).hintColor.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      feature.included ? Icons.check : Icons.close,
                      size: 14,
                      color: feature.included
                          ? styles.checkIconColor
                          : Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: feature.included
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildButton(BuildContext context, TierStyles styles) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: styles.buttonColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: styles.buttonHoverColor.withValues(alpha: 0.1),
          splashColor: styles.buttonHoverColor.withValues(alpha: 0.2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: _isHovered ? styles.buttonHoverColor : styles.buttonColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                widget.plan.ctaText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: styles.buttonTextColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(TierStyles styles) {
    return Positioned(
      top: -12,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: styles.badgeColor,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.plan.badge!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class PricingSection extends StatelessWidget {
  const PricingSection({super.key});

  static const plan = PricingPlan(
    name: 'Rental Management',
    code: 'KRENTAL',
    description: 'Complete property management solution billed per tenant',
    price: 'UGX 1,000',
    priceSubtext: '/tenant/month',
    tier: PricingTier.gold,
    icon: Icons.people,
    features: [
      Feature(text: 'Unlimited properties', included: true),
      Feature(text: 'Per-tenant billing', included: true),
      Feature(text: 'Rent tracking + payment status', included: true),
      Feature(text: 'Maintenance requests', included: true),
      Feature(text: 'Tenant portal access', included: true),
      Feature(text: 'Receipts & exports', included: true),
      Feature(text: 'Dashboard overview', included: true),
      Feature(text: 'Monthly recurring billing', included: true),
    ],
    ctaText: 'Get Started',
    featured: true,
    badge: 'Per Tenant Pricing',
    discountCode: DiscountCode(
      code: 'FREE',
      amount: 3590.0,
      expiryDate: '2026-03-20',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 800),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -400,
            left: MediaQuery.of(context).size.width / 2 - 400,
            child: Container(
              width: 800,
              height: 800,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.05),
                    blurRadius: 200,
                    spreadRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.05),
                    blurRadius: 150,
                    spreadRadius: 75,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 672),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.business,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Property Management Plans',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                          children: [
                            const TextSpan(text: 'Simple, transparent '),
                            TextSpan(
                              text: 'pricing',
                              style: TextStyle(
                                foreground: Paint()
                                  ..shader =
                                      LinearGradient(
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ],
                                      ).createShader(
                                        const Rect.fromLTWH(0, 0, 200, 70),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Choose the perfect plan for your property management needs. Start free and scale as you grow.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: PricingCard(plan: plan, onTap: () {}),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All plans include 14-day free trial. No credit card required.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
