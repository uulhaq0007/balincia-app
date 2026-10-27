import 'product.dart';

/// PERCENT | FIXED | FREESHIP, mirroring the web store's Coupon model.
enum CouponType { percent, fixed, freeShip }

class Coupon {
  const Coupon({
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    required this.minSubtotal,
    this.expired = false,
  });

  final String code;
  final String description;
  final CouponType type;
  final int value;
  final int minSubtotal;
  final bool expired;
}

enum ShippingMethod { standard, express }

enum PaymentMethod {
  cod('Cash on Delivery', 'Pay in cash when your parcel arrives.'),
  bank('Bank Transfer', 'Transfer to our bank account — details shared after checkout.'),
  wallet('JazzCash / Easypaisa', 'Send to our mobile wallet and share the transaction ID.');

  const PaymentMethod(this.label, this.description);
  final String label;
  final String description;
}

class CartItem {
  CartItem({required this.product, required this.variant, this.quantity = 1});

  final Product product;
  final Variant variant;
  int quantity;

  String get key => '${product.slug}|${variant.label}';
  int get lineTotal => variant.price * quantity;
}

class Address {
  const Address({
    required this.fullName,
    required this.phone,
    required this.line1,
    required this.city,
    required this.province,
    required this.postalCode,
  });

  final String fullName;
  final String phone;
  final String line1;
  final String city;
  final String province;
  final String postalCode;

  String get singleLine => '$line1, $city, $province $postalCode';
}

/// Order lifecycle, matching ORDER_STATUSES on the web.
enum OrderStatus {
  pending('Order placed', 'We have received your order.'),
  confirmed('Confirmed', 'Your order has been confirmed by our team.'),
  processing('Being prepared', 'Your fragrances are being packed with care.'),
  shipped('Shipped', 'Your parcel is on its way.'),
  delivered('Delivered', 'Delivered. Enjoy your new scent!'),
  cancelled('Cancelled', 'This order has been cancelled.');

  const OrderStatus(this.label, this.description);
  final String label;
  final String description;

  static const flow = [pending, confirmed, processing, shipped, delivered];
}

class OrderLine {
  const OrderLine({required this.product, required this.variant, required this.quantity});

  final Product product;
  final Variant variant;
  final int quantity;

  int get lineTotal => variant.price * quantity;
}

class Order {
  const Order({
    required this.number,
    required this.placedAt,
    required this.status,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.pointsRedeemed,
    required this.shipping,
    required this.total,
    required this.pointsEarned,
    required this.address,
    required this.payment,
    required this.shippingMethod,
    this.couponCode,
    this.courier,
    this.trackingNumber,
  });

  final String number;
  final DateTime placedAt;
  final OrderStatus status;
  final List<OrderLine> lines;
  final int subtotal;
  final int discount;
  final int pointsRedeemed;
  final int shipping;
  final int total;
  final int pointsEarned;
  final Address address;
  final PaymentMethod payment;
  final ShippingMethod shippingMethod;
  final String? couponCode;
  final String? courier;
  final String? trackingNumber;

  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  /// Approximate timestamp for each reached step of the timeline.
  DateTime stepTime(OrderStatus step) {
    const hours = {
      OrderStatus.pending: 0,
      OrderStatus.confirmed: 3,
      OrderStatus.processing: 20,
      OrderStatus.shipped: 30,
      OrderStatus.delivered: 70,
    };
    return placedAt.add(Duration(hours: hours[step] ?? 0));
  }
}

class Review {
  const Review({required this.name, required this.rating, required this.title, required this.body, required this.date});

  final String name;
  final int rating;
  final String title;
  final String body;
  final DateTime date;
}

class Customer {
  const Customer({
    required this.name,
    required this.email,
    required this.phone,
    required this.memberSince,
    required this.lifetimeSpend,
    required this.address,
  });

  final String name;
  final String email;
  final String phone;
  final DateTime memberSince;
  final int lifetimeSpend;
  final Address address;

  String get firstName => name.split(' ').first;
  String get initials => name.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join();
}
