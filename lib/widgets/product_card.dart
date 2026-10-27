import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/catalog.dart';
import '../data/reviews.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../theme.dart';
import 'bottle_art.dart';
import 'common.dart';

/// Height of a [ProductCard] for a given width (artwork is 4:5).
double productCardHeight(double width) => width * 1.25 + 108;

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.showQuickAdd = true});

  final Product product;
  final bool showQuickAdd;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final rating = ratingOf(p);
    void open() => context.push('/product/${p.slug}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(borderRadius: BorderRadius.circular(18), child: BottleArt.product(p)),
              ),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: open,
                    splashColor: p.light.withValues(alpha: 0.2),
                  ),
                ),
              ),
              Positioned(top: 10, left: 10, child: _Badges(product: p)),
              Positioned(top: 8, right: 8, child: WishlistButton(product: p, size: 32)),
              if (showQuickAdd)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: GlassIconButton(
                    icon: Icons.add_rounded,
                    size: 32,
                    iconSize: 19,
                    tooltip: 'Quick add',
                    onPressed: () {
                      context.cart.add(p, p.cheapest);
                      showToast(
                        context,
                        '${p.name} (${p.cheapest.label}) added to your bag',
                        actionLabel: 'View bag',
                        onAction: () => context.go('/bag'),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: open,
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productEyebrow(p).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(8.6, weight: FontWeight.w700, color: BrandColors.muted, letterSpacing: 1.3),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(p.name, maxLines: 1, style: AppText.display(17.5, height: 1.15)),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                p.tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(12, color: BrandColors.inkSoft, height: 1.3),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(child: PriceTag.product(p, size: 13.5)),
                  if (p.ratingCount > 0) ...[
                    const Icon(Icons.star_rounded, size: 13, color: BrandColors.gold),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: AppText.sans(11.5, weight: FontWeight.w700, color: BrandColors.inkSoft),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final off = product.discountPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (off > 0) ...[
          Pill('−$off%', background: BrandColors.sale, foreground: Colors.white),
          const SizedBox(height: 5),
        ],
        if (product.isNew)
          const Pill('New', background: BrandColors.paper, foreground: BrandColors.ink)
        else if (product.isBestseller)
          const Pill('Bestseller'),
      ],
    );
  }
}

/// Horizontal rail of product cards.
class ProductRail extends StatelessWidget {
  const ProductRail({super.key, required this.products, this.cardWidth = 168});

  final List<Product> products;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: productCardHeight(cardWidth),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) => SizedBox(
          width: cardWidth,
          child: ProductCard(product: products[i]),
        ),
      ),
    );
  }
}

/// Two-column sliver grid of product cards.
class ProductSliverGrid extends StatelessWidget {
  const ProductSliverGrid({
    super.key,
    required this.products,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<Product> products;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          const gap = 14.0;
          final width = (constraints.crossAxisExtent - gap) / 2;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: gap,
              mainAxisSpacing: 22,
              mainAxisExtent: productCardHeight(width),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => ProductCard(product: products[i]),
              childCount: products.length,
            ),
          );
        },
      ),
    );
  }
}
