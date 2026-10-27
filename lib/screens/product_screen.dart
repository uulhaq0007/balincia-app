import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/catalog.dart';
import '../data/format.dart';
import '../data/pricing.dart';
import '../data/reviews.dart';
import '../models/commerce.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../theme.dart';
import '../widgets/bottle_art.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'not_found_screen.dart';

const kSeasonIcons = {
  'spring': Icons.local_florist_outlined,
  'summer': Icons.wb_sunny_outlined,
  'autumn': Icons.eco_outlined,
  'winter': Icons.ac_unit_rounded,
};

const kOccasionIcons = {
  'day': Icons.wb_sunny_outlined,
  'night': Icons.bedtime_outlined,
  'office': Icons.work_outline_rounded,
  'evening': Icons.wine_bar_outlined,
  'signature': Icons.auto_awesome_outlined,
};

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.slug});

  final String slug;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final Product? _product = productBySlug(widget.slug);
  late Variant _variant = _product?.variants.first ?? const Variant(label: '', price: 0);
  int _quantity = 1;

  void _addToBag() {
    final p = _product!;
    context.cart.add(p, _variant, quantity: _quantity);
    showToast(
      context,
      '${p.name} · ${_variant.label} × $_quantity added to your bag',
      actionLabel: 'View bag',
      onAction: () => context.go('/bag'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;
    if (p == null) return const NotFoundScreen();
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 372,
            backgroundColor: BrandColors.paper,
            automaticallyImplyLeading: false,
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: BackOrHomeButton(glass: true, fallback: '/shop'),
            ),
            leadingWidth: 60,
            actions: [
              WishlistButton(product: p, size: 40),
              const SizedBox(width: 8),
              const _GlassBag(),
              const SizedBox(width: 12),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(24),
              child: Container(
                height: 24,
                decoration: const BoxDecoration(
                  color: BrandColors.paper,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, c) {
                final min = kToolbarHeight + 24 + topInset;
                final max = 372 + topInset;
                final t = ((c.maxHeight - min) / (max - min)).clamp(0.0, 1.0);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: t,
                      child: _HeroArt(product: p, topInset: topInset),
                    ),
                    IgnorePointer(
                      child: Opacity(
                        opacity: 1 - t,
                        child: Container(
                          color: BrandColors.paper,
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Text(p.name, style: AppText.display(19, weight: FontWeight.w500)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _Summary(product: p, variant: _variant, onVariant: (v) => setState(() => _variant = v)),
          ),
          SliverToBoxAdapter(child: _Story(product: p)),
          SliverToBoxAdapter(child: _Pyramid(product: p)),
          SliverToBoxAdapter(child: _Performance(product: p)),
          SliverToBoxAdapter(child: _Reviews(product: p)),
          const SliverToBoxAdapter(child: SizedBox(height: 34)),
          const SliverToBoxAdapter(
            child: SectionHeading(eyebrow: 'You may also like', title: 'From the *same family*'),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: ProductRail(products: relatedTo(p))),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
      bottomNavigationBar: _PurchaseBar(
        price: _variant.price * _quantity,
        quantity: _quantity,
        onQuantity: (q) => setState(() => _quantity = q),
        onAdd: _addToBag,
      ),
    );
  }
}

class _GlassBag extends StatelessWidget {
  const _GlassBag();

  @override
  Widget build(BuildContext context) {
    final cart = context.cart;
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => Badge(
        isLabelVisible: cart.count > 0,
        backgroundColor: BrandColors.gold,
        offset: const Offset(-2, 2),
        label: Text(
          '${cart.count}',
          style: AppText.sans(9.5, weight: FontWeight.w800, color: Colors.white),
        ),
        child: GlassIconButton(icon: Icons.shopping_bag_outlined, tooltip: 'Bag', onPressed: () => context.go('/bag')),
      ),
    );
  }
}

/// Large painted bottle on its palette-tinted backdrop.
class _HeroArt extends StatelessWidget {
  const _HeroArt({required this.product, required this.topInset});

  final Product product;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(p.light.withValues(alpha: 0.16), const Color(0xfff4eee5)),
            Color.alphaBlend(p.light.withValues(alpha: 0.55), const Color(0xfff4eee5)),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topInset + 34, bottom: 22),
        child: LayoutBuilder(
          builder: (context, c) {
            final ring = math.min(c.maxWidth * 0.86, c.maxHeight * 0.92);
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: ring,
                  height: ring,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p.dark.withValues(alpha: 0.08)),
                    gradient: RadialGradient(
                      colors: [Colors.white.withValues(alpha: 0.75), Colors.white.withValues(alpha: 0)],
                      stops: const [0, 0.8],
                    ),
                  ),
                ),
                Positioned.fill(child: BottleArt.product(p, bare: true)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.product, required this.variant, required this.onVariant});

  final Product product;
  final Variant variant;
  final ValueChanged<Variant> onVariant;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final rating = ratingOf(p);
    final off = variant.onSale
        ? ((variant.compareAtPrice! - variant.price) / variant.compareAtPrice! * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow('${categoryBySlug(p.category)?.name} · ${kConcentrationLabels[p.concentration]}'),
          const SizedBox(height: 8),
          Text(p.name, style: AppText.display(36, height: 1.04)),
          const SizedBox(height: 6),
          Text(
            p.tagline,
            style: AppText.display(16.5, italic: true, color: BrandColors.inkSoft, weight: FontWeight.w300),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Stars(rating: rating, size: 15),
              const SizedBox(width: 6),
              Text(rating.toStringAsFixed(1), style: AppText.sans(13, weight: FontWeight.w800)),
              const SizedBox(width: 6),
              Text(pluralize(p.ratingCount, 'review'), style: AppText.sans(13, color: BrandColors.inkSoft)),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                formatPrice(variant.price),
                style: AppText.display(
                  28,
                  weight: FontWeight.w500,
                  color: variant.onSale ? BrandColors.sale : BrandColors.ink,
                ),
              ),
              if (variant.onSale) ...[
                const SizedBox(width: 10),
                Text(
                  formatPrice(variant.compareAtPrice!),
                  style: AppText.sans(
                    15,
                    color: BrandColors.muted,
                  ).copyWith(decoration: TextDecoration.lineThrough, decorationColor: BrandColors.muted),
                ),
                const SizedBox(width: 10),
                Pill('−$off%', background: BrandColors.sale, foreground: Colors.white),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tax included. Free delivery over ${formatPrice(StoreConfig.freeShippingThreshold)}.',
            style: AppText.sans(12, color: BrandColors.muted),
          ),
          const SizedBox(height: 20),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'SIZE — ',
                  style: AppText.sans(11.5, weight: FontWeight.w800, letterSpacing: 1.6, color: BrandColors.inkSoft),
                ),
                TextSpan(
                  text: variant.label.toUpperCase(),
                  style: AppText.sans(11.5, weight: FontWeight.w800, letterSpacing: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final v in p.variants)
                _VariantCard(variant: v, selected: v.label == variant.label, onTap: () => onVariant(v)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: BrandColors.sage, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                'In stock, ready to ship',
                style: AppText.sans(12.5, color: BrandColors.inkSoft, weight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _ServiceList(),
        ],
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({required this.variant, required this.selected, required this.onTap});

  final Variant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? BrandColors.paper : BrandColors.ink;
    return Material(
      color: selected ? BrandColors.ink : BrandColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? BrandColors.ink : BrandColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(minWidth: 104),
          padding: const EdgeInsets.fromLTRB(16, 11, 18, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                variant.label,
                style: AppText.sans(14.5, weight: FontWeight.w800, color: fg),
              ),
              const SizedBox(height: 1),
              Text(
                formatPrice(variant.price),
                style: AppText.sans(
                  12,
                  weight: FontWeight.w500,
                  color: selected ? BrandColors.paper.withValues(alpha: 0.7) : BrandColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceList extends StatelessWidget {
  const _ServiceList();

  static const _rows = [
    (Icons.local_shipping_outlined, 'Delivery in 2–4 working days', 'Nationwide · Cash on delivery available'),
    (Icons.autorenew_rounded, '15-day exchanges & returns', 'On unused, sealed bottles'),
    (Icons.verified_outlined, 'Authentic & freshly made', 'Macerated for 30 days in our Karachi atelier'),
  ];

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < _rows.length; i++) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
              child: Row(
                children: [
                  Icon(_rows[i].$1, size: 20, color: BrandColors.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_rows[i].$2, style: AppText.sans(13, weight: FontWeight.w700)),
                        Text(_rows[i].$3, style: AppText.sans(12, color: BrandColors.inkSoft)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final facts = [
      ('Concentration', kConcentrationLabels[p.concentration] ?? p.concentration),
      ('For', p.gender == 'UNISEX' ? 'Unisex' : (p.gender == 'MEN' ? 'Him' : 'Her')),
      ('Genre', labelFor(kGenres, p.genre)),
      ('Sizes', p.variants.map((v) => v.label).join(' / ')),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('The story'),
          const SizedBox(height: 12),
          Text(p.description, style: AppText.display(19, weight: FontWeight.w300, height: 1.45)),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: BrandColors.line),
            ),
            child: Column(
              children: [
                for (var r = 0; r < 2; r++) ...[
                  if (r > 0) const Divider(),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        for (var c = 0; c < 2; c++) ...[
                          if (c > 0) const VerticalDivider(width: 1),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    facts[r * 2 + c].$1.toUpperCase(),
                                    style: AppText.eyebrow(color: BrandColors.muted, size: 9),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(facts[r * 2 + c].$2, style: AppText.sans(13.5, weight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Top / heart / base tiers, widening like the web FragrancePyramid.
class _Pyramid extends StatelessWidget {
  const _Pyramid({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final tiers = [
      ('Top notes', 'The first impression · 0–30 min', p.top, 0.66, 0.22),
      ('Heart notes', 'The character · 30 min – 4 hrs', p.heart, 0.83, 0.44),
      ('Base notes', 'The memory · 4 hrs +', p.base, 1.0, 0.69),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: Column(
        children: [
          const Eyebrow('Fragrance pyramid'),
          const SizedBox(height: 8),
          const EditorialText('How it *unfolds*', size: 30, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          for (final (title, sub, notes, width, alpha) in tiers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FractionallySizedBox(
                widthFactor: width,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(p.light.withValues(alpha: alpha), BrandColors.paper),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(title.toUpperCase(), style: AppText.eyebrow(color: p.dark.withValues(alpha: 0.65), size: 9)),
                      const SizedBox(height: 5),
                      Text(
                        notes.join(' · '),
                        textAlign: TextAlign.center,
                        style: AppText.display(
                          17,
                          color: Color.alphaBlend(p.dark.withValues(alpha: 0.85), BrandColors.ink),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(sub, style: AppText.sans(10.5, color: p.dark.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Performance extends StatelessWidget {
  const _Performance({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
      child: PaperCard(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Performance & wear'),
            const SizedBox(height: 18),
            Meter(label: 'Longevity', value: p.longevity, caption: kLongevityLabels[p.longevity] ?? ''),
            const SizedBox(height: 18),
            Meter(label: 'Sillage', value: p.sillage, caption: kPerformanceLabels[p.sillage] ?? ''),
            const SizedBox(height: 24),
            Text('BEST SEASONS', style: AppText.sans(11, weight: FontWeight.w800, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < kSeasons.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _SeasonTile(option: kSeasons[i], on: p.seasons.contains(kSeasons[i].value)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            Text('WEAR IT FOR', style: AppText.sans(11, weight: FontWeight.w800, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [for (final o in kOccasions) _OccasionChip(option: o, on: p.occasions.contains(o.value))],
            ),
            const SizedBox(height: 18),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Olfactive family: ',
                    style: AppText.sans(13, weight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: p.families.map((f) => labelFor(kFamilies, f)).join(', '),
                    style: AppText.sans(13, color: BrandColors.inkSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Five-segment gold meter (longevity / sillage).
class Meter extends StatelessWidget {
  const Meter({super.key, required this.label, required this.value, required this.caption});

  final String label;
  final int value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(label.toUpperCase(), style: AppText.sans(11, weight: FontWeight.w800, letterSpacing: 1.5)),
            const Spacer(),
            Text(caption, style: AppText.sans(13, color: BrandColors.inkSoft)),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            for (var i = 1; i <= 5; i++) ...[
              if (i > 1) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: i <= value ? BrandColors.gold : BrandColors.paper3,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SeasonTile extends StatelessWidget {
  const _SeasonTile({required this.option, required this.on});

  final Option option;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final fg = on ? BrandColors.paper : BrandColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: on ? BrandColors.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: on ? BrandColors.ink : BrandColors.line),
      ),
      child: Column(
        children: [
          Icon(kSeasonIcons[option.value], size: 19, color: fg),
          const SizedBox(height: 4),
          Text(
            option.label,
            style: AppText.sans(11.5, weight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

class _OccasionChip extends StatelessWidget {
  const _OccasionChip({required this.option, required this.on});

  final Option option;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final fg = on ? BrandColors.paper : BrandColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: on ? BrandColors.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: on ? BrandColors.ink : BrandColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kOccasionIcons[option.value], size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            option.label,
            style: AppText.sans(12, weight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

class _Reviews extends StatefulWidget {
  const _Reviews({required this.product});

  final Product product;

  @override
  State<_Reviews> createState() => _ReviewsState();
}

class _ReviewsState extends State<_Reviews> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final reviews = reviewsFor(widget.product);
    if (reviews.isEmpty) return const SizedBox.shrink();
    final rating = ratingOf(widget.product);
    final shown = _all ? reviews : reviews.take(2).toList();
    final counts = {for (var s = 5; s >= 1; s--) s: reviews.where((r) => r.rating == s).length};

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Reviews'),
          const SizedBox(height: 8),
          Text('What people say', style: AppText.display(28)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(rating.toStringAsFixed(1), style: AppText.display(52, weight: FontWeight.w300, height: 1)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stars(rating: rating, size: 16),
                  const SizedBox(height: 3),
                  Text(
                    'Based on ${pluralize(reviews.length, 'review')}',
                    style: AppText.sans(12, color: BrandColors.muted),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    for (final e in counts.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.5),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              child: Text('${e.key}★', style: AppText.sans(10, color: BrandColors.inkSoft)),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: LinearProgressIndicator(value: e.value / reviews.length, minHeight: 5),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final r in shown) _ReviewTile(review: r),
          if (reviews.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton(
                onPressed: () => setState(() => _all = !_all),
                child: Text(_all ? 'SHOW FEWER' : 'SHOW ALL ${reviews.length} REVIEWS'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BrandColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stars(rating: review.rating.toDouble(), size: 13),
              const Spacer(),
              Text(formatDate(review.date), style: AppText.sans(11.5, color: BrandColors.muted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.title, style: AppText.display(18)),
          const SizedBox(height: 4),
          Text(review.body, style: AppText.sans(13.5, color: BrandColors.inkSoft, height: 1.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(review.name.toUpperCase(), style: AppText.sans(10.5, weight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(width: 8),
              const Icon(Icons.verified_rounded, size: 13, color: BrandColors.sage),
              const SizedBox(width: 3),
              Text(
                'Verified buyer',
                style: AppText.sans(11, color: BrandColors.sage, weight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchaseBar extends StatelessWidget {
  const _PurchaseBar({required this.price, required this.quantity, required this.onQuantity, required this.onAdd});

  final int price;
  final int quantity;
  final ValueChanged<int> onQuantity;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfffbf8f3),
        border: const Border(top: BorderSide(color: BrandColors.line)),
        boxShadow: [
          BoxShadow(color: BrandColors.ink.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              QuantityStepper(value: quantity, onChanged: onQuantity),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onAdd,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('ADD TO BAG · ${formatPrice(price)}'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
