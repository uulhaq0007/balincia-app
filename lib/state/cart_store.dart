import 'package:flutter/foundation.dart';

import '../data/pricing.dart';
import '../models/commerce.dart';
import '../models/product.dart';

/// The bag: line items, an applied discount code, points redemption and the
/// shipping method. Totals always go through the ported pricing rules.
class CartStore extends ChangeNotifier {
  CartStore(this._pointsBalance);

  final int Function() _pointsBalance;
  final List<CartItem> _items = [];
  Coupon? _coupon;
  bool _usePoints = false;
  ShippingMethod _method = ShippingMethod.standard;

  List<CartItem> get items => List.unmodifiable(_items);
  Coupon? get coupon => _coupon;
  bool get usePoints => _usePoints;
  ShippingMethod get shippingMethod => _method;
  bool get isEmpty => _items.isEmpty;

  int get count => _items.fold(0, (s, i) => s + i.quantity);
  int get subtotal => _items.fold(0, (s, i) => s + i.lineTotal);

  int get savings => _items.fold(0, (s, i) {
    final compare = i.variant.compareAtPrice;
    return compare != null && compare > i.variant.price ? s + (compare - i.variant.price) * i.quantity : s;
  });

  /// Coupon is applied but the bag is under its minimum spend.
  bool get couponBelowMinimum => _coupon != null && subtotal < _coupon!.minSubtotal;

  int get redeemablePoints {
    final prelim = computeTotals(subtotal: subtotal, coupon: _coupon, method: _method);
    return maxRedeemablePoints(subtotal - prelim.discount, _pointsBalance(), StoreConfig.maxPointsRedeemPercent);
  }

  Totals get totals => computeTotals(
    subtotal: subtotal,
    coupon: _coupon,
    method: _method,
    pointsToRedeem: _usePoints ? redeemablePoints : 0,
  );

  int get pointsToEarn => pointsEarned(totals.total);

  int quantityOf(Product p) => _items.where((i) => i.product.slug == p.slug).fold(0, (s, i) => s + i.quantity);

  void add(Product product, Variant variant, {int quantity = 1}) {
    final existing = _items.where((i) => i.product.slug == product.slug && i.variant.label == variant.label);
    if (existing.isNotEmpty) {
      existing.first.quantity = (existing.first.quantity + quantity).clamp(1, 10);
    } else {
      _items.add(CartItem(product: product, variant: variant, quantity: quantity.clamp(1, 10)));
    }
    notifyListeners();
  }

  void setQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      remove(item);
      return;
    }
    item.quantity = quantity.clamp(1, 10);
    notifyListeners();
  }

  /// Removes [item] and returns its index so it can be restored ("Undo").
  int remove(CartItem item) {
    final index = _items.indexWhere((i) => i.key == item.key);
    if (index >= 0) _items.removeAt(index);
    notifyListeners();
    return index;
  }

  void restore(CartItem item, int index) {
    _items.insert(index.clamp(0, _items.length), item);
    notifyListeners();
  }

  /// Returns null on success, or an error message.
  String? applyCode(String code) {
    final result = validateCoupon(code, subtotal);
    switch (result) {
      case CouponOk(:final coupon):
        _coupon = coupon;
        notifyListeners();
        return null;
      case CouponError(:final message):
        return message;
    }
  }

  void removeCoupon() {
    _coupon = null;
    notifyListeners();
  }

  void setUsePoints(bool value) {
    _usePoints = value;
    notifyListeners();
  }

  void setShippingMethod(ShippingMethod method) {
    _method = method;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _coupon = null;
    _usePoints = false;
    _method = ShippingMethod.standard;
    notifyListeners();
  }

  /// Puts every line of a past order back in the bag.
  void addAll(Iterable<OrderLine> lines) {
    for (final l in lines) {
      add(l.product, l.variant, quantity: l.quantity);
    }
  }
}
