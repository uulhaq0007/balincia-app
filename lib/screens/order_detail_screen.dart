import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/format.dart';
import '../models/commerce.dart';
import '../state/app_scope.dart';
import '../theme.dart';
import '../widgets/commerce_widgets.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';
import 'not_found_screen.dart';

/// Order tracking: status timeline, courier, items, address and totals.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    final order = context.account.orderByNumber(number);
    if (order == null) return const NotFoundScreen();
    final delivered = order.status == OrderStatus.delivered;

    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(fallback: '/account'),
        title: Text(order.number),
        actions: [
          IconButton(
            tooltip: 'Copy order number',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: order.number));
              showToast(context, 'Order number copied');
            },
            icon: const Icon(Icons.copy_rounded, size: 20),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(order.status.label, style: AppText.display(26))),
                      Text(
                        pluralize(order.itemCount, 'item'),
                        style: AppText.sans(12.5, color: BrandColors.muted, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(order.status.description, style: AppText.sans(13.5, color: BrandColors.inkSoft)),
                  const SizedBox(height: 4),
                  Text('Placed ${formatDateTime(order.placedAt)}', style: AppText.sans(12, color: BrandColors.muted)),
                  const SizedBox(height: 18),
                  if (order.status == OrderStatus.cancelled)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: BrandColors.sale.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel_outlined, color: BrandColors.sale),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This order was cancelled at your request. No payment was taken.',
                              style: AppText.sans(13, color: BrandColors.sale, weight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _Timeline(order: order),
                  if (order.trackingNumber != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                      decoration: BoxDecoration(color: BrandColors.paper2, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 19, color: BrandColors.gold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Shipped with ',
                                    style: AppText.sans(13, color: BrandColors.inkSoft),
                                  ),
                                  TextSpan(
                                    text: order.courier ?? 'our courier',
                                    style: AppText.sans(13, weight: FontWeight.w800),
                                  ),
                                  TextSpan(
                                    text: '\nTracking # ',
                                    style: AppText.sans(13, color: BrandColors.inkSoft),
                                  ),
                                  TextSpan(
                                    text: order.trackingNumber,
                                    style: AppText.sans(13, weight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy tracking number',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: order.trackingNumber!));
                              showToast(context, 'Tracking number copied');
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionLabel(pluralize(order.itemCount, 'item')),
                  for (final l in order.lines)
                    OrderLineTile(product: l.product, variant: l.variant, quantity: l.quantity),
                  const SizedBox(height: 10),
                  TotalsBreakdown(
                    subtotal: order.subtotal,
                    discount: order.discount,
                    points: order.pointsRedeemed,
                    shipping: order.shipping,
                    total: order.total,
                    couponCode: order.couponCode,
                    pointsNote: order.status == OrderStatus.cancelled
                        ? null
                        : delivered
                        ? '${order.pointsEarned} points earned'
                        : '${order.pointsEarned} points on delivery',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Delivery & payment'),
                  _Detail(
                    icon: Icons.place_outlined,
                    title: order.address.fullName,
                    body: '${order.address.singleLine}\n${order.address.phone}',
                  ),
                  const SizedBox(height: 12),
                  _Detail(
                    icon: order.shippingMethod == ShippingMethod.express
                        ? Icons.bolt_rounded
                        : Icons.local_shipping_outlined,
                    title: order.shippingMethod == ShippingMethod.express ? 'Express delivery' : 'Standard delivery',
                    body: order.shippingMethod == ShippingMethod.express
                        ? '24–48 hrs in major cities'
                        : '2–4 working days',
                  ),
                  const SizedBox(height: 12),
                  _Detail(icon: Icons.payments_outlined, title: order.payment.label, body: order.payment.description),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                context.cart.addAll(order.lines);
                showToast(context, '${pluralize(order.itemCount, 'item')} added to your bag');
                context.go('/bag');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.replay_rounded, size: 18), SizedBox(width: 8), Text('BUY AGAIN')],
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => showConciergeSheet(context),
              child: const Text('NEED HELP WITH THIS ORDER?'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final reached = OrderStatus.flow.indexOf(order.status);
    return Column(
      children: [
        for (var i = 0; i < OrderStatus.flow.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= reached ? BrandColors.gold : BrandColors.paper,
                          border: Border.all(color: i <= reached ? BrandColors.gold : BrandColors.paper3, width: 2),
                          boxShadow: i == reached
                              ? [BoxShadow(color: BrandColors.gold.withValues(alpha: 0.25), spreadRadius: 4)]
                              : null,
                        ),
                        child: i <= reached
                            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                            : Center(
                                child: Text(
                                  '${i + 1}',
                                  style: AppText.sans(10, weight: FontWeight.w800, color: BrandColors.muted),
                                ),
                              ),
                      ),
                      if (i < OrderStatus.flow.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            color: i < reached ? BrandColors.gold : BrandColors.paper3,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i < OrderStatus.flow.length - 1 ? 16 : 0, top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          OrderStatus.flow[i].label,
                          style: AppText.sans(
                            13.5,
                            weight: FontWeight.w700,
                            color: i <= reached ? BrandColors.ink : BrandColors.muted,
                          ),
                        ),
                        if (i <= reached)
                          Text(
                            formatDateTime(order.stepTime(OrderStatus.flow[i])),
                            style: AppText.sans(11.5, color: BrandColors.muted),
                          )
                        else
                          Text(OrderStatus.flow[i].description, style: AppText.sans(11.5, color: BrandColors.muted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: BrandColors.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.sans(13.5, weight: FontWeight.w700)),
              Text(body, style: AppText.sans(12.5, color: BrandColors.inkSoft, height: 1.45)),
            ],
          ),
        ),
      ],
    );
  }
}
