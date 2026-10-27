import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/format.dart';
import '../data/pricing.dart';
import '../models/commerce.dart';
import '../state/app_scope.dart';
import '../state/cart_store.dart';
import '../theme.dart';
import '../widgets/commerce_widgets.dart';
import '../widgets/common.dart';

class BagScreen extends StatelessWidget {
  const BagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.cart;
    final account = context.account;
    return ListenableBuilder(
      listenable: Listenable.merge([cart, account]),
      builder: (context, _) {
        final totals = cart.totals;
        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            automaticallyImplyLeading: false,
            titleSpacing: 20,
            toolbarHeight: 64,
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Your bag', style: AppText.display(30)),
                  if (!cart.isEmpty)
                    TextSpan(text: '  (${cart.count})', style: AppText.display(18, color: BrandColors.muted)),
                ],
              ),
            ),
            actions: const [WishlistIconButton(), SizedBox(width: 8)],
          ),
          body: cart.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: EmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Your bag is empty',
                      message: "Let's find a scent worth remembering.",
                      primaryLabel: 'Shop best sellers',
                      onPrimary: () => context.go('/shop/collections/best-sellers'),
                      secondaryLabel: 'Take the quiz',
                      onSecondary: () => context.go('/quiz'),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    FreeShippingMeter(
                      subtotal: cart.subtotal,
                      freeShipCoupon: cart.coupon?.type == CouponType.freeShip,
                    ),
                    const SizedBox(height: 8),
                    for (final item in cart.items) _BagItem(item: item, cart: cart),
                    const SizedBox(height: 14),
                    _DiscountCode(cart: cart),
                    const SizedBox(height: 12),
                    _PointsCard(cart: cart, balance: account.points),
                    const SizedBox(height: 12),
                    PaperCard(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionLabel('Order summary'),
                          TotalsBreakdown(
                            subtotal: totals.subtotal,
                            discount: totals.discount,
                            points: totals.points,
                            shipping: totals.shipping,
                            total: totals.total,
                            couponCode: cart.coupon?.code,
                            pointsNote: "You'll earn ${cart.pointsToEarn} points on delivery",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 14, color: BrandColors.muted),
                        const SizedBox(width: 6),
                        Text(
                          'Cash on Delivery · Bank Transfer · JazzCash / Easypaisa',
                          style: AppText.sans(11.5, color: BrandColors.muted, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
          bottomNavigationBar: cart.isEmpty
              ? null
              : _CheckoutBar(total: totals.total, items: cart.count, onCheckout: () => context.push('/checkout')),
        );
      },
    );
  }
}

class _BagItem extends StatelessWidget {
  const _BagItem({required this.item, required this.cart});

  final CartItem item;
  final CartStore cart;

  void _remove(BuildContext context) {
    final index = cart.remove(item);
    showToast(
      context,
      '${item.product.name} removed',
      actionLabel: 'Undo',
      onAction: () => cart.restore(item, index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    return Dismissible(
      key: ValueKey(item.key),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _remove(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: BrandColors.sale, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: BrandColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BrandColors.line.withValues(alpha: 0.8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context.push('/product/${p.slug}'),
              child: BottleThumb(product: p, width: 88, height: 110, radius: 14),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.display(18.5, height: 1.15)),
                              const SizedBox(height: 2),
                              Text(
                                '${item.variant.label} · ${formatPrice(item.variant.price)}',
                                style: AppText.sans(12.5, color: BrandColors.muted),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            tooltip: 'Remove',
                            padding: EdgeInsets.zero,
                            iconSize: 19,
                            color: BrandColors.muted,
                            onPressed: () => _remove(context),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        QuantityStepper(
                          compact: true,
                          value: item.quantity,
                          onChanged: (q) => cart.setQuantity(item, q),
                        ),
                        const Spacer(),
                        Text(formatPrice(item.lineTotal), style: AppText.display(18, weight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountCode extends StatefulWidget {
  const _DiscountCode({required this.cart});

  final CartStore cart;

  @override
  State<_DiscountCode> createState() => _DiscountCodeState();
}

class _DiscountCodeState extends State<_DiscountCode> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final error = widget.cart.applyCode(_controller.text);
    setState(() => _error = error);
    if (error == null) {
      FocusScope.of(context).unfocus();
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;
    final coupon = cart.coupon;
    final discount = cart.totals.discount;
    return PaperCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Discount code'),
          if (coupon != null)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              decoration: BoxDecoration(
                color: const Color(0xffe6ece3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: BrandColors.sage.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sell_outlined, size: 18, color: BrandColors.sage),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(coupon.code, style: AppText.sans(13.5, weight: FontWeight.w800, color: BrandColors.sage, letterSpacing: 0.8)),
                        Text(coupon.description, style: AppText.sans(12, color: BrandColors.inkSoft)),
                      ],
                    ),
                  ),
                  if (discount > 0)
                    Text('− ${formatPrice(discount)}', style: AppText.sans(13.5, weight: FontWeight.w800, color: BrandColors.sage)),
                  IconButton(
                    tooltip: 'Remove code',
                    onPressed: cart.removeCoupon,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _apply(),
                    style: AppText.sans(14, weight: FontWeight.w700, letterSpacing: 0.8),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Enter code',
                      errorText: null,
                      prefixIcon: const Icon(Icons.sell_outlined, size: 18, color: BrandColors.muted),
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: _error == null ? BrandColors.line : BrandColors.sale),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 46,
                  child: OutlinedButton(onPressed: _apply, child: const Text('APPLY')),
                ),
              ],
            ),
          const SizedBox(height: 8),
          if (_error != null && coupon == null)
            Text(_error!, style: AppText.sans(12, color: BrandColors.sale, weight: FontWeight.w600))
          else if (cart.couponBelowMinimum)
            Text(
              'Add ${formatPrice(coupon!.minSubtotal - cart.subtotal)} more to use this code.',
              style: AppText.sans(12, color: BrandColors.sale, weight: FontWeight.w600),
            )
          else if (coupon == null)
            Text('Try WELCOME10 for 10% off orders over Rs. 2,000.', style: AppText.sans(12, color: BrandColors.muted)),
        ],
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.cart, required this.balance});

  final CartStore cart;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final redeemable = cart.redeemablePoints;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandColors.oud, Color(0xff3d2817)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: BrandColors.gold2.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.workspace_premium_outlined, color: BrandColors.gold2, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BALINCIA POINTS', style: AppText.eyebrow(color: BrandColors.gold2, size: 9.5)),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Use $redeemable', style: AppText.sans(14, weight: FontWeight.w800, color: BrandColors.paper)),
                      TextSpan(
                        text: ' of your $balance points',
                        style: AppText.sans(14, color: BrandColors.paper.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '1 point = Rs. 1 · up to ${StoreConfig.maxPointsRedeemPercent}% of your order',
                  style: AppText.sans(11.5, color: BrandColors.paper.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          Switch(
            value: cart.usePoints && redeemable > 0,
            onChanged: redeemable == 0 ? null : cart.setUsePoints,
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.total, required this.items, required this.onCheckout});

  final int total;
  final int items;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xfffbf8f3),
        border: Border(top: BorderSide(color: BrandColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL · ${pluralize(items, 'ITEM')}', style: AppText.sans(10, weight: FontWeight.w800, color: BrandColors.muted, letterSpacing: 1.3)),
                Text(formatPrice(total), style: AppText.display(23, weight: FontWeight.w500)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: onCheckout,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('CHECKOUT'),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
