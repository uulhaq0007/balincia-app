import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/format.dart';
import '../models/commerce.dart';
import '../state/app_scope.dart';
import '../theme.dart';
import '../widgets/commerce_widgets.dart';
import '../widgets/common.dart';
import 'not_found_screen.dart';

/// Shown after checkout: order number, delivery estimate and points earned.
class OrderConfirmedScreen extends StatelessWidget {
  const OrderConfirmedScreen({super.key, required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    final account = context.account;
    final order = account.orderByNumber(number);
    if (order == null) return const NotFoundScreen();

    final fast = order.shippingMethod == ShippingMethod.express;
    final from = order.placedAt.add(Duration(days: fast ? 1 : 2));
    final to = order.placedAt.add(Duration(days: fast ? 2 : 4));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Close',
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.close_rounded),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            const Center(child: _Seal()),
            const SizedBox(height: 20),
            Center(child: Eyebrow('Thank you, ${account.customer.firstName}')),
            const SizedBox(height: 10),
            const EditorialText('Your order is *confirmed*', size: 34, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Order ${order.number} · placed ${formatDateTime(order.placedAt)}',
              textAlign: TextAlign.center,
              style: AppText.sans(13.5, color: BrandColors.inkSoft),
            ),
            const SizedBox(height: 24),
            PaperCard(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.event_available_outlined,
                    label: 'Arriving',
                    value: '${formatShortDate(from)} – ${formatShortDate(to)}',
                    note: fast ? 'Express · 24–48 hrs' : 'Standard · 2–4 working days',
                  ),
                  const Divider(height: 26),
                  _InfoRow(
                    icon: Icons.place_outlined,
                    label: 'Deliver to',
                    value: order.address.fullName,
                    note: order.address.singleLine,
                  ),
                  const Divider(height: 26),
                  _InfoRow(
                    icon: Icons.payments_outlined,
                    label: 'Payment',
                    value: order.payment.label,
                    note: order.payment == PaymentMethod.cod
                        ? 'Please keep ${formatPrice(order.total)} ready'
                        : order.payment.description,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(colors: [BrandColors.oud, Color(0xff3d2817)]),
              ),
              child: Row(
                children: [
                  Text('+${order.pointsEarned}', style: AppText.display(34, color: BrandColors.gold2, weight: FontWeight.w500)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Balincia Points will be added to your account once this order is delivered.',
                      style: AppText.sans(13, color: BrandColors.paper.withValues(alpha: 0.85), height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionLabel('${pluralize(order.itemCount, 'item')} in this order'),
                  for (final l in order.lines) OrderLineTile(product: l.product, variant: l.variant, quantity: l.quantity),
                  const SizedBox(height: 10),
                  TotalsBreakdown(
                    subtotal: order.subtotal,
                    discount: order.discount,
                    points: order.pointsRedeemed,
                    shipping: order.shipping,
                    total: order.total,
                    couponCode: order.couponCode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => context.push('/orders/${order.number}'),
              child: const Text('TRACK THIS ORDER'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: () => context.go('/'), child: const Text('CONTINUE SHOPPING')),
          ],
        ),
      ),
    );
  }
}

class _Seal extends StatelessWidget {
  const _Seal();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: BrandColors.goldSoft,
          border: Border.all(color: BrandColors.gold2, width: 1.5),
        ),
        child: Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: BrandColors.gold),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, required this.note});

  final IconData icon;
  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: BrandColors.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: AppText.eyebrow(color: BrandColors.muted, size: 9.5)),
              const SizedBox(height: 3),
              Text(value, style: AppText.sans(14.5, weight: FontWeight.w700)),
              Text(note, style: AppText.sans(12.5, color: BrandColors.inkSoft, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
