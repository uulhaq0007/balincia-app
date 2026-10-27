import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/catalog.dart';
import '../data/format.dart';
import '../data/products.dart';
import '../data/reviews.dart';
import '../models/product.dart';
import '../theme.dart';
import '../widgets/bottle_art.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bestSellers = kProducts.where((p) => p.isBestseller).toList()
      ..sort((a, b) => b.soldCount.compareTo(a.soldCount));
    final newArrivals = kProducts.where((p) => p.isNew).toList()..sort((a, b) => b.index.compareTo(a.index));
    final giftSets = kProducts.where((p) => p.category == 'gift-sets').toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const _HomeAppBar(),
          const SliverToBoxAdapter(child: _Hero()),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          const SliverToBoxAdapter(child: _NotesMarquee()),
          const SliverToBoxAdapter(child: SizedBox(height: 34)),
          SliverToBoxAdapter(
            child: SectionHeading(
              eyebrow: 'Most loved',
              title: 'Our *best sellers*',
              actionLabel: 'View all',
              onAction: () => context.go('/shop/collections/best-sellers'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(child: ProductRail(products: bestSellers)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          const SliverToBoxAdapter(child: _CollectionTiles()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          const SliverToBoxAdapter(child: _FamilyExplorer()),
          const SliverToBoxAdapter(child: SizedBox(height: 36)),
          SliverToBoxAdapter(
            child: SectionHeading(
              eyebrow: 'Just landed',
              title: 'New *arrivals*',
              actionLabel: 'View all',
              onAction: () => context.go('/shop/collections/new-arrivals'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(child: ProductRail(products: newArrivals)),
          const SliverToBoxAdapter(child: SizedBox(height: 36)),
          const SliverToBoxAdapter(child: _QuizBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: 36)),
          SliverToBoxAdapter(
            child: SectionHeading(
              eyebrow: 'Gifting, perfected',
              title: 'Gift sets for *every occasion*',
              actionLabel: 'All',
              onAction: () => context.go('/shop/collections/gift-sets'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(child: ProductRail(products: giftSets)),
          const SliverToBoxAdapter(child: SizedBox(height: 36)),
          const SliverToBoxAdapter(child: _TrustGrid()),
          const SliverToBoxAdapter(child: _Footer()),
        ],
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 60,
      leading: IconButton(
        tooltip: 'Search',
        onPressed: () => context.push('/search'),
        icon: const Icon(Icons.search_rounded, size: 25),
      ),
      title: const Wordmark(),
      actions: const [WishlistIconButton(), SizedBox(width: 6)],
      bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider()),
    );
  }
}

/// BALINCIA / MAISON DE PARFUM lockup from the web header.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.color = BrandColors.ink});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'BALINCIA',
          style: AppText.display(22, weight: FontWeight.w500, color: color, height: 1).copyWith(letterSpacing: 6.5),
        ),
        const SizedBox(height: 3),
        Text('MAISON DE PARFUM', style: AppText.eyebrow(size: 7.2).copyWith(letterSpacing: 3)),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final totalReviews = kProducts.fold(0, (s, p) => s + p.ratingCount);
    final avg = kProducts.fold(0.0, (s, p) => s + ratingOf(p) * p.ratingCount) / totalReviews;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Maison de Parfum · Karachi'),
          const SizedBox(height: 12),
          const EditorialText(
            'Scent is the story *you leave* behind.',
            size: 41,
            weight: FontWeight.w300,
            accentWeight: FontWeight.w400,
            height: 1.02,
          ),
          const SizedBox(height: 12),
          Text(
            'Long-lasting, super-macerated perfumes and attars — composed with rare oils, aged for 30 days and delivered anywhere in Pakistan.',
            style: AppText.sans(14, color: BrandColors.inkSoft, height: 1.55),
          ),
          const SizedBox(height: 20),
          const _HeroStage(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.go('/shop/collections/best-sellers'),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text('BEST SELLERS'), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, size: 17)],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(onPressed: () => context.go('/quiz'), child: const Text('FIND MY SCENT')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stars(rating: avg, size: 14),
                  const SizedBox(width: 6),
                  Text(avg.toStringAsFixed(1), style: AppText.sans(12.5, weight: FontWeight.w800)),
                  Text(' from $totalReviews reviews', style: AppText.sans(12.5, color: BrandColors.inkSoft)),
                ],
              ),
              Text('Cash on delivery', style: AppText.sans(12.5, color: BrandColors.inkSoft)),
              Text('15-day exchanges', style: AppText.sans(12.5, color: BrandColors.inkSoft)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The dark stage with three floating bottles, as in the web hero.
class _HeroStage extends StatefulWidget {
  const _HeroStage();

  @override
  State<_HeroStage> createState() => _HeroStageState();
}

class _HeroStageState extends State<_HeroStage> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 6))
    ..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hero = productNamed('noir-oud-royale');
    final left = productNamed('boardroom');
    final right = productNamed('velvet-rose');

    return GestureDetector(
      onTap: () => context.push('/product/${hero.slug}'),
      child: Container(
        height: 340,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [hero.dark, const Color(0xff120c09)],
          ),
          boxShadow: [BoxShadow(color: hero.dark.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 16))],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.4, -0.6),
                    radius: 1.0,
                    colors: [hero.light.withValues(alpha: 0.42), hero.light.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 0,
              right: 0,
              child: Text(
                hero.name.split(' ').first,
                textAlign: TextAlign.center,
                style: AppText.display(124, italic: true, color: Colors.white.withValues(alpha: 0.06), height: 1),
              ),
            ),
            Positioned(
              left: 4,
              bottom: 16,
              width: 112,
              height: 160,
              child: Opacity(opacity: 0.92, child: BottleArt.product(left, bare: true)),
            ),
            Positioned(
              right: 4,
              bottom: 16,
              width: 112,
              height: 150,
              child: Opacity(opacity: 0.92, child: BottleArt.product(right, bare: true)),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              height: 262,
              child: AnimatedBuilder(
                animation: _float,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -8 * (0.5 - 0.5 * math.cos(_float.value * 2 * math.pi))),
                  child: child,
                ),
                child: BottleArt.product(hero, bare: true),
              ),
            ),
            Positioned(top: 14, left: 14, child: _HeroChip(product: hero)),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
      decoration: BoxDecoration(
        color: BrandColors.paper.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 42,
            decoration: BoxDecoration(
              color: product.light.withValues(alpha: 0.33),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: BottleArt.product(product, bare: true, showName: false),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('BESTSELLER', style: AppText.eyebrow(size: 8)),
              const SizedBox(height: 2),
              Text(product.name, style: AppText.display(15.5, height: 1.1)),
              Text('from ${formatPrice(product.price)}', style: AppText.sans(11, color: BrandColors.inkSoft)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotesMarquee extends StatefulWidget {
  const _NotesMarquee();

  @override
  State<_NotesMarquee> createState() => _NotesMarqueeState();
}

class _NotesMarqueeState extends State<_NotesMarquee> with SingleTickerProviderStateMixin {
  static const _notes = [
    'Saffron',
    'Cambodian Oud',
    'Damask Rose',
    'Haitian Vetiver',
    'Jasmine Sambac',
    'Madagascan Vanilla',
    'Ambergris',
    'Tonka Bean',
    'Sandalwood',
    'Bergamot',
    'Petrichor',
    'Iris',
  ];

  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 45))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget row() => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final n in _notes) ...[
          Text(n, style: AppText.display(22, italic: true, color: BrandColors.inkSoft)),
          const SizedBox(width: 18),
          Text('✦', style: AppText.sans(12, color: BrandColors.gold)),
          const SizedBox(width: 18),
        ],
      ],
    );
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: BrandColors.paper2,
        border: Border.symmetric(horizontal: BorderSide(color: BrandColors.line)),
      ),
      child: ClipRect(
        child: OverflowBox(
          maxWidth: double.infinity,
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) =>
                FractionalTranslation(translation: Offset(-0.5 * _c.value, 0), child: child),
            child: Row(mainAxisSize: MainAxisSize.min, children: [row(), row()]),
          ),
        ),
      ),
    );
  }
}

class _Tile {
  const _Tile(this.title, this.route, this.dark, this.light, this.shape);
  final String title;
  final String route;
  final Color dark;
  final Color light;
  final BottleShape shape;
}

class _CollectionTiles extends StatelessWidget {
  const _CollectionTiles();

  static const _big = [
    _Tile('For Him', '/shop/collections/men', Color(0xff141820), Color(0xff7d8ca3), BottleShape.classic),
    _Tile('For Her', '/shop/collections/women', Color(0xff5a1a2c), Color(0xffe9a3b5), BottleShape.round),
  ];
  static const _small = [
    _Tile('Attars', '/shop/collections/attars', Color(0xff4a1a08), Color(0xffe0a03a), BottleShape.attar),
    _Tile('Gift Sets', '/shop/collections/gift-sets', Color(0xff2a1a10), Color(0xffd4a373), BottleShape.box),
    _Tile('Discovery', '/shop/collections/discovery-sets', Color(0xff3a2a1c), Color(0xffe8d5b5), BottleShape.box),
    _Tile('Home', '/shop/collections/home-fragrance', Color(0xff4a3a20), Color(0xffd9c08a), BottleShape.diffuser),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(eyebrow: 'Shop by world', title: 'Every scent has a *home*'),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _TileCard(tile: _big[0], height: 210)),
                  const SizedBox(width: 12),
                  Expanded(child: _TileCard(tile: _big[1], height: 210)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _TileCard(tile: _small[0], height: 150)),
                  const SizedBox(width: 12),
                  Expanded(child: _TileCard(tile: _small[1], height: 150)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _TileCard(tile: _small[2], height: 150)),
                  const SizedBox(width: 12),
                  Expanded(child: _TileCard(tile: _small[3], height: 150)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TileCard extends StatelessWidget {
  const _TileCard({required this.tile, required this.height});

  final _Tile tile;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tile.light.withValues(alpha: 0.33), tile.light.withValues(alpha: 0.8)],
          ),
        ),
        child: InkWell(
          onTap: () => context.go(tile.route),
          child: Stack(
            children: [
              Positioned(
                right: -14,
                bottom: -6,
                width: height * 0.72,
                height: height * 0.92,
                child: BottleArt(dark: tile.dark, light: tile.light, shape: tile.shape, bare: true),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tile.title, style: AppText.display(height > 180 ? 25 : 21, color: tile.dark, height: 1)),
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: BrandColors.paper.withValues(alpha: 0.82),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.north_east_rounded, size: 17, color: tile.dark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyExplorer extends StatelessWidget {
  const _FamilyExplorer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BrandColors.paper2,
      padding: const EdgeInsets.fromLTRB(0, 34, 0, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(eyebrow: 'Shop by note', title: 'What does your *mood* smell like?'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Text(
              'Every Balincia scent is mapped to its olfactive family. Start with what you love.',
              style: AppText.sans(13.5, color: BrandColors.inkSoft, height: 1.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.42,
              padding: EdgeInsets.zero,
              children: [for (final f in kFamilySwatches) _FamilyCard(family: f)],
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({required this.family});

  final FamilySwatch family;

  @override
  Widget build(BuildContext context) {
    final count = kProducts.where((p) => p.families.contains(family.value)).length;
    return Material(
      color: BrandColors.paper,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/shop?family=${family.value}'),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BrandColors.line),
            gradient: RadialGradient(
              center: const Alignment(1.1, -1.1),
              radius: 1.1,
              colors: [family.color.withValues(alpha: 0.3), family.color.withValues(alpha: 0)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(color: family.color, shape: BoxShape.circle),
                  ),
                  const Spacer(),
                  Text('$count', style: AppText.sans(11, weight: FontWeight.w700, color: BrandColors.muted)),
                ],
              ),
              const Spacer(),
              Text(family.label, style: AppText.display(21, height: 1.05)),
              const SizedBox(height: 3),
              Text(
                family.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(11.5, color: BrandColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizBanner extends StatelessWidget {
  const _QuizBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: BrandColors.goldSoft.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: BrandColors.line),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -34,
              bottom: -26,
              width: 130,
              height: 160,
              child: Transform.rotate(
                angle: -0.21,
                child: const Opacity(
                  opacity: 0.85,
                  child: BottleArt(dark: Color(0xff5a1a2c), light: Color(0xffe9a3b5), shape: BottleShape.round, bare: true),
                ),
              ),
            ),
            Positioned(
              right: -30,
              bottom: -30,
              width: 120,
              height: 172,
              child: Transform.rotate(
                angle: 0.21,
                child: const Opacity(
                  opacity: 0.85,
                  child: BottleArt(dark: Color(0xff12384a), light: Color(0xff7cc6d6), shape: BottleShape.tall, bare: true),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 34, 26, 112),
              child: Column(
                children: [
                  const Eyebrow('Not sure where to start?'),
                  const SizedBox(height: 12),
                  const EditorialText(
                    'Meet your scent in *60 seconds*.',
                    size: 32,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Answer five quick questions about the moments, moods and notes you love — we’ll match you with the Balincia scents made for you.',
                    textAlign: TextAlign.center,
                    style: AppText.sans(13.5, color: BrandColors.inkSoft, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      context.go('/quiz');
                    },
                    child: const Text('TAKE THE QUIZ'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/shop/collections/discovery-sets'),
                    child: Text(
                      'OR TRY A SAMPLE SET',
                      style: AppText.sans(11.5, weight: FontWeight.w800, letterSpacing: 1.4).copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: BrandColors.gold,
                      ),
                    ),
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

class _TrustGrid extends StatelessWidget {
  const _TrustGrid();

  static const _items = [
    (Icons.local_shipping_outlined, 'Free delivery', 'On orders over Rs. 3,000, nationwide'),
    (Icons.payments_outlined, 'Cash on delivery', 'Pay at your door, anywhere in Pakistan'),
    (Icons.autorenew_rounded, '15-day exchanges', 'On unused, sealed bottles'),
    (Icons.workspace_premium_outlined, 'Balincia Points', '1 point for every Rs. 100 you spend'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.25,
        children: [
          for (final (icon, title, text) in _items)
            PaperCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: BrandColors.gold, size: 24),
                  const Spacer(),
                  Text(title, style: AppText.display(17.5)),
                  const SizedBox(height: 3),
                  Text(text, style: AppText.sans(11.5, color: BrandColors.inkSoft, height: 1.35)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 36),
      width: double.infinity,
      color: BrandColors.oud,
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EditorialText('Join the *inner circle*', size: 30, color: BrandColors.paper, accent: BrandColors.gold2),
          const SizedBox(height: 10),
          Text(
            'Early access to launches, private sales and scent stories — plus Balincia Points on every order.',
            style: AppText.sans(13.5, color: BrandColors.paper.withValues(alpha: 0.7), height: 1.5),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: BrandColors.paper,
              side: BorderSide(color: BrandColors.paper.withValues(alpha: 0.4)),
            ),
            onPressed: () => context.go('/account'),
            child: Text('YOUR ACCOUNT', style: AppText.button(color: BrandColors.paper)),
          ),
          const SizedBox(height: 26),
          FittedBox(
            child: Text(
              'BALINCIA',
              style: AppText.display(96, color: Colors.white.withValues(alpha: 0.07), height: 1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '© 2026 Balincia (Pvt) Ltd. Crafted in Pakistan.',
            style: AppText.sans(11.5, color: BrandColors.paper.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
