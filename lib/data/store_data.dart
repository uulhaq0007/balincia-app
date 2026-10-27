// Sample account data: the demo customer from the web seed, her order history
// and the boutiques list from constants.ts.

import '../models/commerce.dart';
import '../models/product.dart';
import 'catalog.dart';
import 'pricing.dart';
import 'reviews.dart';

const kDemoAddress = Address(
  fullName: 'Ayesha Khan',
  phone: '0300-1112233',
  line1: 'House 14, Street 7, Phase 6, DHA',
  city: 'Karachi',
  province: 'Sindh',
  postalCode: '75500',
);

final kDemoCustomer = Customer(
  name: 'Ayesha Khan',
  email: 'ayesha@example.com',
  phone: '0300-1112233',
  memberSince: DateTime(2025, 3, 14),
  lifetimeSpend: 18760,
  address: kDemoAddress,
);

const kDemoLoyaltyPoints = 340;

OrderLine _line(String slug, String label, [int qty = 1]) {
  final p = productNamed(slug);
  final v = p.variants.firstWhere((v) => v.label == label);
  return OrderLine(product: p, variant: v, quantity: qty);
}

Order _order({
  required String number,
  required int daysAgo,
  required OrderStatus status,
  required List<OrderLine> lines,
  Coupon? coupon,
  PaymentMethod payment = PaymentMethod.cod,
  ShippingMethod method = ShippingMethod.standard,
  String? courier,
  String? tracking,
}) {
  final subtotal = lines.fold(0, (s, l) => s + l.lineTotal);
  final totals = computeTotals(subtotal: subtotal, coupon: coupon, method: method);
  return Order(
    number: number,
    placedAt: kDemoToday.subtract(Duration(days: daysAgo, hours: 3)),
    status: status,
    lines: lines,
    subtotal: totals.subtotal,
    discount: totals.discount,
    pointsRedeemed: totals.points,
    shipping: totals.shipping,
    total: totals.total,
    pointsEarned: pointsEarned(totals.total),
    address: kDemoAddress,
    payment: payment,
    shippingMethod: method,
    couponCode: coupon?.code,
    courier: courier,
    trackingNumber: tracking,
  );
}

Coupon _coupon(String code) => kCoupons.firstWhere((c) => c.code == code);

/// Mixed statuses so the account history looks lived-in.
List<Order> seedOrders() => [
  _order(
    number: 'BLC-7K2Q9M',
    daysAgo: 1,
    status: OrderStatus.processing,
    lines: [_line('ghazal', '50ml'), _line('musk-tahara-attar', '8ml')],
    payment: PaymentMethod.wallet,
  ),
  _order(
    number: 'BLC-R4WD8T',
    daysAgo: 5,
    status: OrderStatus.shipped,
    lines: [_line('the-duo-him-her', '2 x 50ml')],
    method: ShippingMethod.express,
    courier: 'TCS',
    tracking: '7723 0915 4410',
  ),
  _order(
    number: 'BLC-3HNX6B',
    daysAgo: 23,
    status: OrderStatus.delivered,
    lines: [_line('amber-reverie', '100ml'), _line('amber-hearth-candle', '220g')],
    coupon: _coupon('FLAT500'),
    courier: 'Leopards',
    tracking: 'LP 4410 2291 07',
  ),
  _order(
    number: 'BLC-P9VE2C',
    daysAgo: 61,
    status: OrderStatus.delivered,
    lines: [_line('lahore-nights', '50ml'), _line('top-5-discovery-set', '5 x 5ml', 2)],
    coupon: _coupon('WELCOME10'),
    payment: PaymentMethod.bank,
    courier: 'TCS',
    tracking: '7723 0388 1902',
  ),
  _order(
    number: 'BLC-Z8MF5A',
    daysAgo: 96,
    status: OrderStatus.cancelled,
    lines: [_line('vanilla-silk-mist', '250ml')],
  ),
];

class Boutique {
  const Boutique(this.city, this.name, this.address, this.phone, this.hours);
  final String city;
  final String name;
  final String address;
  final String phone;
  final String hours;
}

const kBoutiques = [
  Boutique(
    'Karachi',
    'Flagship Atelier — Dolmen Mall Clifton',
    'Ground Floor, Dolmen Mall, Block 4 Clifton, Karachi',
    '+92 21 3529 0000',
    '11am – 10pm',
  ),
  Boutique(
    'Karachi',
    'LuckyOne Mall',
    'First Floor, LuckyOne Mall, Rashid Minhas Road, Karachi',
    '+92 21 3630 0000',
    '11am – 10pm',
  ),
  Boutique(
    'Lahore',
    'Emporium Mall',
    'Ground Floor, Emporium Mall, Johar Town, Lahore',
    '+92 42 3531 0000',
    '11am – 10pm',
  ),
  Boutique(
    'Lahore',
    'MM Alam Road Boutique',
    'Shop 12, MM Alam Road, Gulberg III, Lahore',
    '+92 42 3575 0000',
    '12pm – 11pm',
  ),
  Boutique('Islamabad', 'Centaurus Mall', 'Level 2, The Centaurus, F-8, Islamabad', '+92 51 2155 0000', '11am – 10pm'),
  Boutique(
    'Faisalabad',
    'Lyallpur Galleria',
    'Ground Floor, Lyallpur Galleria, Canal Road, Faisalabad',
    '+92 41 8500 000',
    '11am – 10pm',
  ),
  Boutique(
    'Multan',
    'Mall of Multan',
    'First Floor, Mall of Multan, Bosan Road, Multan',
    '+92 61 6500 000',
    '11am – 10pm',
  ),
  Boutique(
    'Peshawar',
    'Deans Trade Centre',
    'Ground Floor, Deans Trade Centre, Saddar, Peshawar',
    '+92 91 5250 000',
    '11am – 9pm',
  ),
];

const kConcierge = (
  phone: '+92 300 1234567',
  email: 'care@balincia.pk',
  whatsapp: '+92 300 1234567',
  hours: 'Mon – Sun, 11am – 10pm',
);

/// The bag the app opens with: three items, WELCOME10 applied, points on.
List<(Product, String, int)> get kDemoBag => [
  (productNamed('saffron-dusk'), '50ml', 1),
  (productNamed('velvet-rose'), '50ml', 1),
  (productNamed('kesar-oud-attar'), '8ml', 2),
];

const kDemoWishlist = ['noir-oud-royale', 'ghazal', 'amber-reverie', 'hunza-morning'];

/// Popular searches shown on the search screen.
const kPopularSearches = ['Oud', 'Rose', 'Saffron', 'Vanilla', 'Attar', 'Vetiver', 'Musk', 'Gift'];
