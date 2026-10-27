import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/quiz.dart';
import '../data/store_data.dart';
import '../models/commerce.dart';
import 'cart_store.dart';

/// The signed-in demo customer: profile, Balincia Points, orders and the
/// last scent-quiz result.
class AccountStore extends ChangeNotifier {
  AccountStore() : _orders = seedOrders();

  final Customer customer = kDemoCustomer;
  final List<Order> _orders;
  int _points = kDemoLoyaltyPoints;
  int _lifetimeSpend = kDemoCustomer.lifetimeSpend;
  Address _address = kDemoAddress;
  QuizAnswers? _quizAnswers;
  final _random = Random();

  int get points => _points;
  int get lifetimeSpend => _lifetimeSpend;
  Address get address => _address;
  List<Order> get orders => List.unmodifiable(_orders);
  QuizAnswers? get quizAnswers => _quizAnswers;

  /// Points still to be credited for orders that haven't been delivered yet.
  int get pendingPoints => _orders
      .where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
      .fold(0, (s, o) => s + o.pointsEarned);

  Order? orderByNumber(String number) {
    for (final o in _orders) {
      if (o.number == number) return o;
    }
    return null;
  }

  void saveQuiz(QuizAnswers answers) {
    _quizAnswers = Map.of(answers);
    notifyListeners();
  }

  void updateAddress(Address address) {
    _address = address;
    notifyListeners();
  }

  /// Turns the bag into an order — the same arithmetic as the web order API —
  /// deducts redeemed points and empties the bag.
  Order placeOrder(CartStore cart, {required Address address, required PaymentMethod payment}) {
    final totals = cart.totals;
    final order = Order(
      number: _newNumber(),
      placedAt: DateTime.now(),
      status: OrderStatus.pending,
      lines: [for (final i in cart.items) OrderLine(product: i.product, variant: i.variant, quantity: i.quantity)],
      subtotal: totals.subtotal,
      discount: totals.discount,
      pointsRedeemed: totals.points,
      shipping: totals.shipping,
      total: totals.total,
      pointsEarned: cart.pointsToEarn,
      address: address,
      payment: payment,
      shippingMethod: cart.shippingMethod,
      couponCode: totals.discount > 0 || totals.shipping == 0 ? cart.coupon?.code : null,
    );
    _orders.insert(0, order);
    _points -= totals.points;
    _lifetimeSpend += totals.total;
    _address = address;
    cart.clear();
    notifyListeners();
    return order;
  }

  String _newNumber() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String code() => List.generate(6, (_) => alphabet[_random.nextInt(alphabet.length)]).join();
    var number = 'BLC-${code()}';
    while (orderByNumber(number) != null) {
      number = 'BLC-${code()}';
    }
    return number;
  }
}
