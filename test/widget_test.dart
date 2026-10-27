import 'package:balincia_app/app.dart';
import 'package:balincia_app/data/catalog.dart';
import 'package:balincia_app/data/pricing.dart';
import 'package:balincia_app/data/products.dart';
import 'package:balincia_app/data/quiz.dart';
import 'package:balincia_app/models/commerce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('app boots to the home screen with the bottom navigation', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const BalinciaApp(initialLocation: '/'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('BALINCIA'), findsWidgets);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);

    // Switch to the bag tab: the seeded bag is there.
    await tester.tap(find.text('Bag'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Saffron Dusk'), findsWidgets);
  });

  test('catalogue filters mirror the web where-clause', () {
    const f = CatalogFilters(gender: {'MEN'}, family: {'woody', 'oud'}, season: {'winter'}, longevity: 4);
    final results = f.apply(kProducts);
    expect(results, isNotEmpty);
    for (final p in results) {
      expect(p.gender, 'MEN');
      expect(p.families.any((x) => x == 'woody' || x == 'oud'), isTrue);
      expect(p.seasons, contains('winter'));
      expect(p.longevity, greaterThanOrEqualTo(4));
    }
  });

  test('pricing follows pricing.ts', () {
    final welcome = kCoupons.first;
    final t = computeTotals(subtotal: 8360, coupon: welcome, method: ShippingMethod.standard, pointsToRedeem: 340);
    expect(t.discount, 836);
    expect(t.shipping, 0);
    expect(t.total, 8360 - 836 - 340);
    expect(shippingFee(2000, ShippingMethod.standard), StoreConfig.standardShippingFee);
    expect(shippingFee(9000, ShippingMethod.express), StoreConfig.expressShippingFee);
    expect(maxRedeemablePoints(1000, 340, 20), 200);
  });

  test('quiz scoring ranks the demo answers like the web', () {
    final top = rankMatches(kDemoAnswers);
    expect(top.first.product.slug, 'lahore-nights');
    expect(top.first.percent, 100);
  });
}
