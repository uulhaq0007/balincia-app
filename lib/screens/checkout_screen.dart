import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/format.dart';
import '../data/pricing.dart';
import '../models/commerce.dart';
import '../state/app_scope.dart';
import '../theme.dart';
import '../widgets/commerce_widgets.dart';
import '../widgets/common.dart';

/// Delivery details, shipping method, payment and a review of the totals.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  late final Address _initial = context.account.address;
  late final _name = TextEditingController(text: _initial.fullName);
  late final _phone = TextEditingController(text: _initial.phone);
  late final _line1 = TextEditingController(text: _initial.line1);
  late final _city = TextEditingController(text: _initial.city);
  late final _postal = TextEditingController(text: _initial.postalCode);
  PaymentMethod _payment = PaymentMethod.cod;
  bool _placing = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _line1, _city, _postal]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _place() async {
    if (!(_form.currentState?.validate() ?? false)) {
      showToast(context, 'Please check your delivery details.');
      return;
    }
    setState(() => _placing = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final account = context.account;
    final order = account.placeOrder(
      context.cart,
      address: Address(
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        line1: _line1.text.trim(),
        city: _city.text.trim(),
        province: _initial.province,
        postalCode: _postal.text.trim(),
      ),
      payment: _payment,
    );
    context.go('/order-confirmed/${order.number}');
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.cart;
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        final totals = cart.totals;
        return Scaffold(
          appBar: AppBar(
            leading: const BackOrHomeButton(fallback: '/bag'),
            title: const Text('Checkout'),
            bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider()),
          ),
          body: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                const _Steps(),
                const SizedBox(height: 18),
                PaperCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionLabel('Deliver to'),
                      _Field(controller: _name, label: 'Full name', icon: Icons.person_outline_rounded),
                      _Field(
                        controller: _phone,
                        label: 'Mobile number',
                        icon: Icons.phone_iphone_rounded,
                        keyboard: TextInputType.phone,
                        validator: (v) => RegExp(r'^03\d{2}-?\d{7}$').hasMatch((v ?? '').trim())
                            ? null
                            : 'Use a mobile number like 0300-1234567',
                      ),
                      _Field(controller: _line1, label: 'Address', icon: Icons.home_outlined),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _Field(controller: _city, label: 'City', icon: Icons.location_city_outlined),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _Field(controller: _postal, label: 'Postcode', keyboard: TextInputType.number),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PaperCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionLabel('Delivery'),
                      _ChoiceTile(
                        selected: cart.shippingMethod == ShippingMethod.standard,
                        onTap: () => cart.setShippingMethod(ShippingMethod.standard),
                        icon: Icons.local_shipping_outlined,
                        title: 'Standard',
                        subtitle: '2–4 working days, nationwide',
                        trailing:
                            shippingFee(
                                  cart.subtotal,
                                  ShippingMethod.standard,
                                  freeShipCoupon: cart.coupon?.type == CouponType.freeShip,
                                ) ==
                                0
                            ? 'Free'
                            : formatPrice(StoreConfig.standardShippingFee),
                      ),
                      const SizedBox(height: 8),
                      _ChoiceTile(
                        selected: cart.shippingMethod == ShippingMethod.express,
                        onTap: () => cart.setShippingMethod(ShippingMethod.express),
                        icon: Icons.bolt_rounded,
                        title: 'Express',
                        subtitle: '24–48 hrs in major cities',
                        trailing: formatPrice(StoreConfig.expressShippingFee),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PaperCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionLabel('Payment'),
                      for (final m in PaymentMethod.values) ...[
                        if (m != PaymentMethod.values.first) const SizedBox(height: 8),
                        _ChoiceTile(
                          selected: _payment == m,
                          onTap: () => setState(() => _payment = m),
                          icon: switch (m) {
                            PaymentMethod.cod => Icons.payments_outlined,
                            PaymentMethod.bank => Icons.account_balance_outlined,
                            PaymentMethod.wallet => Icons.phone_android_rounded,
                          },
                          title: m.label,
                          subtitle: m.description,
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
                      SectionLabel(
                        'Your order',
                        trailing: TextButton(
                          onPressed: () => context.canPop() ? context.pop() : context.go('/bag'),
                          child: Text(
                            'Edit bag',
                            style: AppText.sans(12.5, weight: FontWeight.w700, color: BrandColors.gold),
                          ),
                        ),
                      ),
                      for (final i in cart.items)
                        OrderLineTile(product: i.product, variant: i.variant, quantity: i.quantity),
                      const SizedBox(height: 10),
                      TotalsBreakdown(
                        subtotal: totals.subtotal,
                        discount: totals.discount,
                        points: totals.points,
                        shipping: totals.shipping,
                        total: totals.total,
                        couponCode: cart.coupon?.code,
                        pointsNote: "You'll earn ${cart.pointsToEarn} points on delivery",
                        afterShipping: cart.shippingMethod == ShippingMethod.standard
                            ? ShippingMeterLine(
                                subtotal: cart.subtotal,
                                freeShipCoupon: cart.coupon?.type == CouponType.freeShip,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'By placing your order you agree to our terms and 15-day exchange policy.',
                  textAlign: TextAlign.center,
                  style: AppText.sans(11.5, color: BrandColors.muted),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xfffbf8f3),
              border: Border(top: BorderSide(color: BrandColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: FilledButton(
                onPressed: _placing || cart.isEmpty ? null : _place,
                child: _placing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: BrandColors.paper),
                      )
                    : Text('PLACE ORDER · ${formatPrice(totals.total)}'),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    Widget step(int n, String label, bool on) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? BrandColors.ink : Colors.transparent,
            border: Border.all(color: on ? BrandColors.ink : BrandColors.line),
          ),
          child: Text(
            '$n',
            style: AppText.sans(11, weight: FontWeight.w800, color: on ? BrandColors.paper : BrandColors.muted),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppText.sans(12.5, weight: FontWeight.w700, color: on ? BrandColors.ink : BrandColors.muted),
        ),
      ],
    );
    Widget rule() => Expanded(
      child: Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 8), color: BrandColors.line),
    );
    return Row(children: [step(1, 'Bag', true), rule(), step(2, 'Details', true), rule(), step(3, 'Confirmed', false)]);
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, this.icon, this.keyboard, this.validator});

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        style: AppText.sans(14.5, weight: FontWeight.w600),
        validator: validator ?? (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon, size: 19, color: BrandColors.muted),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? BrandColors.goldSoft.withValues(alpha: 0.45) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? BrandColors.gold : BrandColors.line, width: selected ? 1.4 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Icon(icon, size: 21, color: selected ? BrandColors.ink : BrandColors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.sans(14, weight: FontWeight.w800)),
                    Text(subtitle, style: AppText.sans(12, color: BrandColors.inkSoft)),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Text(trailing!, style: AppText.sans(13.5, weight: FontWeight.w800)),
              ],
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                size: 21,
                color: selected ? BrandColors.ink : BrandColors.line,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
