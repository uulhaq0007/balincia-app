import 'package:flutter/widgets.dart';

import '../data/store_data.dart';
import 'account_store.dart';
import 'cart_store.dart';
import 'quiz_session.dart';
import 'wishlist_store.dart';

/// All app state, created once and handed down with [AppScope].
class AppState {
  AppState._(this.account, this.cart, this.wishlist, this.quiz);

  /// A store seeded with the demo bag, wishlist and order history.
  factory AppState.demo() {
    final account = AccountStore();
    final cart = CartStore(pointsBalance: () => account.points);
    for (final (product, label, qty) in kDemoBag) {
      cart.add(product, product.variants.firstWhere((v) => v.label == label), quantity: qty);
    }
    cart.applyCode('WELCOME10');
    cart.setUsePoints(true);
    return AppState._(account, cart, WishlistStore(kDemoWishlist), QuizSession());
  }

  final AccountStore account;
  final CartStore cart;
  final WishlistStore wishlist;
  final QuizSession quiz;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.state, required super.child});

  final AppState state;

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.state;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => state != oldWidget.state;
}

extension AppStateContext on BuildContext {
  AppState get app => AppScope.of(this);
  CartStore get cart => AppScope.of(this).cart;
  WishlistStore get wishlist => AppScope.of(this).wishlist;
  AccountStore get account => AppScope.of(this).account;
  QuizSession get quiz => AppScope.of(this).quiz;
}
