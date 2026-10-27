// Port of the web store's src/lib/pricing.ts — the same rules the checkout page
// uses for estimates and the order API uses for authoritative totals.

import '../models/commerce.dart';

/// Store settings (DEFAULT_SETTINGS in lib/settings.ts).
class StoreConfig {
  static const freeShippingThreshold = 3000;
  static const standardShippingFee = 250;
  static const expressShippingFee = 450;
  static const pointsPer100 = 1;
  static const maxPointsRedeemPercent = 20;
}

int couponDiscount(Coupon? coupon, int subtotal) {
  if (coupon == null || subtotal < coupon.minSubtotal) return 0;
  switch (coupon.type) {
    case CouponType.percent:
      final pct = (subtotal * coupon.value / 100).round();
      return pct < subtotal ? pct : subtotal;
    case CouponType.fixed:
      return coupon.value < subtotal ? coupon.value : subtotal;
    case CouponType.freeShip:
      return 0;
  }
}

int shippingFee(int subtotal, ShippingMethod method, {bool freeShipCoupon = false}) {
  if (method == ShippingMethod.express) return StoreConfig.expressShippingFee;
  if (freeShipCoupon) return 0;
  if (StoreConfig.freeShippingThreshold > 0 && subtotal >= StoreConfig.freeShippingThreshold) return 0;
  return StoreConfig.standardShippingFee;
}

int maxRedeemablePoints(int subtotalAfterDiscount, int balance, int maxPercent) {
  final cap = (subtotalAfterDiscount * maxPercent / 100).floor();
  final value = balance < cap ? balance : cap;
  return value < 0 ? 0 : value;
}

class Totals {
  const Totals({
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.points,
    required this.total,
  });

  final int subtotal;
  final int discount;
  final int shipping;
  final int points;
  final int total;
}

Totals computeTotals({required int subtotal, Coupon? coupon, required ShippingMethod method, int pointsToRedeem = 0}) {
  final discount = couponDiscount(coupon, subtotal);
  final freeShip = coupon?.type == CouponType.freeShip && subtotal >= coupon!.minSubtotal;
  final shipping = shippingFee(subtotal, method, freeShipCoupon: freeShip);
  final maxPoints = subtotal - discount;
  final points = pointsToRedeem.clamp(0, maxPoints < 0 ? 0 : maxPoints);
  final total = subtotal - discount - points + shipping;
  return Totals(
    subtotal: subtotal,
    discount: discount,
    shipping: shipping,
    points: points,
    total: total < 0 ? 0 : total,
  );
}

int pointsEarned(int total, [int pointsPer100 = StoreConfig.pointsPer100]) => (total ~/ 100) * pointsPer100;

class LoyaltyTier {
  const LoyaltyTier(this.name, this.min, this.perk);
  final String name;
  final int min;
  final String perk;
}

const kLoyaltyTiers = [
  LoyaltyTier('Silver', 0, '1 point per Rs. 100 spent'),
  LoyaltyTier('Gold', 25000, 'Early access to launches + birthday gift'),
  LoyaltyTier('Noir', 75000, 'Free express shipping + private previews'),
];

({LoyaltyTier tier, LoyaltyTier? next}) loyaltyTier(int lifetimeSpend) {
  var tier = kLoyaltyTiers.first;
  for (final t in kLoyaltyTiers) {
    if (lifetimeSpend >= t.min) tier = t;
  }
  LoyaltyTier? next;
  for (final t in kLoyaltyTiers) {
    if (t.min > lifetimeSpend) {
      next = t;
      break;
    }
  }
  return (tier: tier, next: next);
}

/// The coupons seeded on the web store.
const kCoupons = [
  Coupon(
    code: 'WELCOME10',
    description: '10% off your first order',
    type: CouponType.percent,
    value: 10,
    minSubtotal: 2000,
  ),
  Coupon(
    code: 'FLAT500',
    description: 'Rs. 500 off orders over Rs. 5,000',
    type: CouponType.fixed,
    value: 500,
    minSubtotal: 5000,
  ),
  Coupon(code: 'FREESHIP', description: 'Free standard shipping', type: CouponType.freeShip, value: 0, minSubtotal: 0),
  Coupon(
    code: 'EID25',
    description: 'Eid special — 25% off (expired)',
    type: CouponType.percent,
    value: 25,
    minSubtotal: 3000,
    expired: true,
  ),
];

sealed class CouponResult {
  const CouponResult();
}

class CouponOk extends CouponResult {
  const CouponOk(this.coupon);
  final Coupon coupon;
}

class CouponError extends CouponResult {
  const CouponError(this.message);
  final String message;
}

/// Same checks as `findValidCoupon` on the web API.
CouponResult validateCoupon(String input, int subtotal) {
  final code = input.trim().toUpperCase();
  if (code.isEmpty) return const CouponError('Enter a discount code.');
  for (final c in kCoupons) {
    if (c.code != code) continue;
    if (c.expired) return const CouponError('This code has expired.');
    return CouponOk(c);
  }
  return const CouponError("That code isn't valid.");
}
