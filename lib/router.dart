import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/commerce.dart';
import 'screens/account_screen.dart';
import 'screens/bag_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/home_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/order_confirmed_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/product_screen.dart';
import 'screens/quiz_results_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/search_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/wishlist_screen.dart';
import 'state/app_scope.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Every screen (and every screenshot state) is reachable by URL:
///
///  /                       Home
///  /shop                   The Library — `?filters=1` opens the filter sheet
///                          with demo filters; `?family=oud&gender=MEN…` pre-filters
///  /shop/collections/:slug A category or virtual collection (back → the Library)
///  /search?q=              Search over the catalogue
///  /product/:slug          Product detail
///  /quiz                   Scent quiz — `?step=3` for a mid-quiz state
///  /quiz/results           Matches — `?demo=1` or the answers as query params
///  /bag                    Bag
///  /checkout               Checkout
///  /order-confirmed/:no    Confirmation (`demo` places the demo bag as an order)
///  /account                Profile, Balincia Points, order history
///  /orders/:no             Order detail and tracking
///  /wishlist               Saved scents
GoRouter buildRouter(AppState state, {String? initialLocation}) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation,
    errorBuilder: (context, s) => const NotFoundScreen(),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, s, shell) => ShellScreen(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (context, s) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shop',
                builder: (context, s) => ShopScreen(key: ValueKey(s.uri.toString()), query: s.uri.queryParameters),
                routes: [
                  GoRoute(
                    path: 'collections/:slug',
                    builder: (context, s) => ShopScreen(
                      key: ValueKey(s.uri.toString()),
                      query: s.uri.queryParameters,
                      collectionSlug: s.pathParameters['slug'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quiz',
                builder: (context, s) => QuizScreen(
                  key: ValueKey('quiz-${s.uri.queryParameters['step']}'),
                  demoStep: int.tryParse(s.uri.queryParameters['step'] ?? ''),
                ),
                routes: [
                  GoRoute(
                    path: 'results',
                    builder: (context, s) => QuizResultsScreen(query: s.uri.queryParameters),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/bag', builder: (context, s) => const BagScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/account', builder: (context, s) => const AccountScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/product/:slug',
        parentNavigatorKey: _rootKey,
        builder: (context, s) => ProductScreen(slug: s.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootKey,
        builder: (context, s) => SearchScreen(initialQuery: s.uri.queryParameters['q'] ?? ''),
      ),
      GoRoute(path: '/wishlist', parentNavigatorKey: _rootKey, builder: (context, s) => const WishlistScreen()),
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: _rootKey,
        redirect: (context, s) => state.cart.isEmpty ? '/bag' : null,
        builder: (context, s) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-confirmed/:number',
        parentNavigatorKey: _rootKey,
        redirect: (context, s) {
          // `demo` runs the real checkout on the seeded bag, then shows its confirmation.
          if (s.pathParameters['number'] != 'demo') return null;
          final account = state.account;
          final order = state.cart.isEmpty
              ? account.orders.first
              : account.placeOrder(state.cart, address: account.address, payment: PaymentMethod.cod);
          return '/order-confirmed/${order.number}${s.uri.hasQuery ? '?${s.uri.query}' : ''}';
        },
        builder: (context, s) => OrderConfirmedScreen(number: s.pathParameters['number']!),
      ),
      GoRoute(
        path: '/orders/:number',
        parentNavigatorKey: _rootKey,
        builder: (context, s) => OrderDetailScreen(number: s.pathParameters['number']!),
      ),
    ],
  );
}
