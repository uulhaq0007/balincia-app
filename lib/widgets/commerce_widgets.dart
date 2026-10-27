import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/format.dart';
import '../data/pricing.dart';
import '../models/commerce.dart';
import '../models/product.dart';
import '../theme.dart';
import 'bottle_art.dart';
import 'common.dart';

/// "You're Rs. 710 away from free delivery" with a gold progress bar.
class FreeShippingMeter extends StatelessWidget {
  const FreeShippingMeter({super.key, required this.subtotal, this.freeShipCoupon = false});

  final int subtotal;
  final bool freeShipCoupon;

  @override
  Widget build(BuildContext context) {
    const threshold = StoreConfig.freeShippingThreshold;
    final remaining = (threshold - subtotal).clamp(0, threshold);
    final unlocked = remaining == 0 || freeShipCoupon;
    final pct = unlocked ? 1.0 : (subtotal / threshold).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(color: BrandColors.paper2, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(unlocked ? Icons.check_circle_rounded : Icons.local_shipping_outlined, size: 19, color: unlocked ? BrandColors.sage : BrandColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  unlocked
                      ? TextSpan(
                          children: [
                            TextSpan(text: 'Free delivery', style: AppText.sans(13, weight: FontWeight.w800)),
                            TextSpan(
                              text: freeShipCoupon && remaining > 0 ? ' with your code' : ' unlocked — nice!',
                              style: AppText.sans(13, color: BrandColors.inkSoft),
                            ),
                          ],
                        )
                      : TextSpan(
                          children: [
                            TextSpan(text: "You're ", style: AppText.sans(13, color: BrandColors.inkSoft)),
                            TextSpan(text: formatPrice(remaining), style: AppText.sans(13, weight: FontWeight.w800)),
                            TextSpan(text: ' away from free delivery', style: AppText.sans(13, color: BrandColors.inkSoft)),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: pct),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                color: unlocked ? BrandColors.sage : BrandColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(formatPrice(subtotal.clamp(0, threshold)), style: AppText.sans(10.5, color: BrandColors.muted, weight: FontWeight.w600)),
              const Spacer(),
              Text('Free over ${formatPrice(threshold)}', style: AppText.sans(10.5, color: BrandColors.muted, weight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small tinted bottle thumbnail.
class BottleThumb extends StatelessWidget {
  const BottleThumb({super.key, required this.product, this.width = 64, this.height = 80, this.radius = 14});

  final Product product;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: width, height: height, child: BottleArt.product(product, showName: width >= 70)),
    );
  }
}

/// Overlapping thumbnails for an order summary row.
class BottleStack extends StatelessWidget {
  const BottleStack({super.key, required this.products, this.size = 44});

  final List<Product> products;
  final double size;

  @override
  Widget build(BuildContext context) {
    final shown = products.take(3).toList();
    return SizedBox(
      width: size + (shown.length - 1) * size * 0.55,
      height: size * 1.25,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * size * 0.55,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BrandColors.card, width: 2),
                ),
                child: BottleThumb(product: shown[i], width: size, height: size * 1.25 - 4, radius: 10),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact line for summaries: thumb, name × qty, line total.
class OrderLineTile extends StatelessWidget {
  const OrderLineTile({super.key, required this.product, required this.variant, required this.quantity});

  final Product product;
  final Variant variant;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/product/${product.slug}'),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            BottleThumb(product: product, width: 52, height: 64, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: AppText.display(16.5)),
                  const SizedBox(height: 2),
                  Text('${variant.label} · Qty $quantity', style: AppText.sans(12.5, color: BrandColors.muted)),
                ],
              ),
            ),
            Text(formatPrice(variant.price * quantity), style: AppText.sans(13.5, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Subtotal / discount / points / shipping / total, as on the web checkout.
class TotalsBreakdown extends StatelessWidget {
  const TotalsBreakdown({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.points,
    required this.shipping,
    required this.total,
    this.couponCode,
    this.savings = 0,
    this.pointsNote,
  });

  final int subtotal;
  final int discount;
  final int points;
  final int shipping;
  final int total;
  final String? couponCode;
  final int savings;
  final String? pointsNote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AmountRow('Subtotal', formatPrice(subtotal)),
        if (savings > 0) AmountRow('Sale savings', '− ${formatPrice(savings)}', accent: BrandColors.sale),
        if (discount > 0)
          AmountRow('Discount${couponCode == null ? '' : ' ($couponCode)'}', '− ${formatPrice(discount)}', accent: BrandColors.sage),
        if (points > 0) AmountRow('Points redeemed', '− ${formatPrice(points)}', accent: BrandColors.sage),
        AmountRow('Shipping', shipping == 0 ? 'Free' : formatPrice(shipping)),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text('TOTAL', style: AppText.sans(12, weight: FontWeight.w800, letterSpacing: 1.6))),
            Text(formatPrice(total), style: AppText.display(27, weight: FontWeight.w500)),
          ],
        ),
        if (pointsNote != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(pointsNote!, style: AppText.sans(12, weight: FontWeight.w700, color: BrandColors.gold)),
          ),
        ],
      ],
    );
  }
}

/// Colour-coded order status pill.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      OrderStatus.delivered => (const Color(0xffdfe8de), BrandColors.sage),
      OrderStatus.cancelled => (const Color(0xfff3dcd9), BrandColors.sale),
      OrderStatus.shipped => (const Color(0xffdde3ee), const Color(0xff3c5a86)),
      _ => (BrandColors.goldSoft, const Color(0xff7d5a2e)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(status.label, style: AppText.sans(11, weight: FontWeight.w800, color: fg)),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: AppText.sans(11.5, weight: FontWeight.w800, letterSpacing: 1.6))),
          ?trailing,
        ],
      ),
    );
  }
}
