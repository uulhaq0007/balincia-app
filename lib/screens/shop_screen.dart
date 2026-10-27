import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/catalog.dart';
import '../data/products.dart';
import '../models/product.dart';
import '../theme.dart';
import '../widgets/bottle_art.dart';
import '../widgets/common.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/product_card.dart';

/// The Library (all products) or a single collection, with live filters.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.query, this.collectionSlug});

  final Map<String, String> query;
  final String? collectionSlug;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final Collection? _collection = widget.collectionSlug == null ? null : resolveCollection(widget.collectionSlug!);
  late CatalogFilters _filters;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Filters shown for `/shop?filters=1`: men's woody/oud winter scents that last 8+ hours.
  static const _demoFilters = CatalogFilters(
    gender: {'MEN'},
    family: {'woody', 'oud'},
    season: {'winter'},
    longevity: 4,
  );

  List<Product> get _base {
    final c = _collection;
    return c == null ? kProducts : kProducts.where(c.where).toList();
  }

  @override
  void initState() {
    super.initState();
    final demo = widget.query['filters'] == '1';
    final parsed = CatalogFilters.fromQuery(widget.query);
    _filters = demo
        ? _demoFilters
        : (widget.query.containsKey('sort') ? parsed : parsed.copyWith(sort: _collection?.defaultSort ?? 'featured'));
    if (demo) {
      // Scroll the banner away so the filtered grid shows behind the sheet.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scroll.hasClients) _scroll.jumpTo(_bannerExtent);
        _openFilters();
      });
    }
  }

  Future<void> _openFilters() async {
    final result = await showFilterSheet(context, initial: _filters, base: _base);
    if (result != null && mounted) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.collectionSlug != null && _collection == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackOrHomeButton(fallback: '/shop')),
        body: Center(
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Collection not found',
            message: 'That collection may have moved. Browse the full library instead.',
            primaryLabel: 'Browse the library',
            onPrimary: () => context.go('/shop'),
          ),
        ),
      );
    }

    final results = _filters.apply(_base);
    final collection = _collection;

    return Scaffold(
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 58,
            leading: collection != null ? const BackOrHomeButton(fallback: '/shop') : null,
            automaticallyImplyLeading: false,
            title: Text(collection?.name ?? 'The Library'),
            actions: [
              IconButton(
                tooltip: 'Search',
                onPressed: () => context.push('/search'),
                icon: const Icon(Icons.search_rounded),
              ),
              const WishlistIconButton(),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: _Banner(
              title: collection?.name ?? 'The Library',
              description: collection?.description ?? 'Every Balincia perfume, attar and home fragrance in one place. Filter by mood, season or note to find yours.',
              dark: collection?.dark ?? const Color(0xff2b2118),
              light: collection?.light ?? const Color(0xffc9a27a),
              shape: collection?.shape ?? BottleShape.classic,
              count: _base.length,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _ToolbarDelegate(
              filters: _filters,
              resultCount: results.length,
              onOpenFilters: _openFilters,
              onSort: (sort) => setState(() => _filters = _filters.copyWith(sort: sort)),
            ),
          ),
          if (!_filters.isEmpty || _filters.q != null)
            SliverToBoxAdapter(
              child: _ActiveFilters(filters: _filters, onChanged: (f) => setState(() => _filters = f)),
            )
          else
            SliverToBoxAdapter(
              child: _QuickFamilies(onPick: (f) => setState(() => _filters = _filters.toggle('family', f))),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          if (results.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'No scents match',
                message: 'Try removing a filter or two — the library has ${_base.length} scents to explore.',
                primaryLabel: 'Clear filters',
                onPrimary: () => setState(() => _filters = _filters.cleared()),
              ),
            )
          else
            ProductSliverGrid(products: results),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

/// Height of the banner sliver including its padding.
const double _bannerExtent = 128 + 6 + 4;

class _Banner extends StatelessWidget {
  const _Banner({
    required this.title,
    required this.description,
    required this.dark,
    required this.light,
    required this.shape,
    required this.count,
  });

  final String title;
  final String description;
  final Color dark;
  final Color light;
  final BottleShape shape;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Container(
        height: 128,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [light.withValues(alpha: 0.32), light.withValues(alpha: 0.72)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 50,
              bottom: -8,
              width: 62,
              height: 80,
              child: Opacity(
                opacity: 0.75,
                child: BottleArt(dark: dark, light: light, shape: BottleShape.round, bare: true),
              ),
            ),
            Positioned(
              right: 0,
              bottom: -6,
              width: 84,
              height: 120,
              child: BottleArt(dark: dark, light: light, shape: shape, bare: true),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 124, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count SCENTS', style: AppText.eyebrow(color: dark.withValues(alpha: 0.75), size: 10)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      description,
                      maxLines: 4,
                      overflow: TextOverflow.fade,
                      style: AppText.sans(12.5, color: dark.withValues(alpha: 0.85), height: 1.45),
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

class _ToolbarDelegate extends SliverPersistentHeaderDelegate {
  _ToolbarDelegate({
    required this.filters,
    required this.resultCount,
    required this.onOpenFilters,
    required this.onSort,
  });

  final CatalogFilters filters;
  final int resultCount;
  final VoidCallback onOpenFilters;
  final ValueChanged<String> onSort;

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final active = filters.activeCount;
    return Container(
      color: BrandColors.paper,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Material(
            color: active > 0 ? BrandColors.ink : BrandColors.card,
            shape: StadiumBorder(side: BorderSide(color: active > 0 ? BrandColors.ink : BrandColors.line)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onOpenFilters,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 17, color: active > 0 ? BrandColors.paper : BrandColors.ink),
                    const SizedBox(width: 8),
                    Text(
                      active > 0 ? 'Filters · $active' : 'Filters',
                      style: AppText.sans(
                        13,
                        weight: FontWeight.w700,
                        color: active > 0 ? BrandColors.paper : BrandColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Sort',
            initialValue: filters.sort,
            onSelected: onSort,
            position: PopupMenuPosition.under,
            itemBuilder: (context) => [
              for (final o in kSortOptions)
                PopupMenuItem(
                  value: o.value,
                  child: Row(
                    children: [
                      Expanded(child: Text(o.label)),
                      if (o.value == filters.sort) const Icon(Icons.check_rounded, size: 18, color: BrandColors.gold),
                    ],
                  ),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: BrandColors.card,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: BrandColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_vert_rounded, size: 17),
                  const SizedBox(width: 6),
                  Text(labelFor(kSortOptions, filters.sort), style: AppText.sans(13, weight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            '$resultCount ${resultCount == 1 ? 'scent' : 'scents'}',
            style: AppText.sans(12.5, weight: FontWeight.w600, color: BrandColors.muted),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_ToolbarDelegate old) => old.filters != filters || old.resultCount != resultCount;
}

/// Removable chips for every active refinement.
class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.filters, required this.onChanged});

  final CatalogFilters filters;
  final ValueChanged<CatalogFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <(String, CatalogFilters)>[
      if (filters.q != null) ('“${filters.q}”', filters.copyWith(clearQ: true)),
      for (final v in filters.gender) (labelFor(kGenders, v), filters.toggle('gender', v)),
      for (final v in filters.family) (labelFor(kFamilies, v), filters.toggle('family', v)),
      for (final v in filters.season) (labelFor(kSeasons, v), filters.toggle('season', v)),
      for (final v in filters.occasion) (labelFor(kOccasions, v), filters.toggle('occasion', v)),
      for (final v in filters.genre) (labelFor(kGenres, v), filters.toggle('genre', v)),
      if (filters.priceRange != null) (filters.priceRange!.label, filters.copyWith(clearPrice: true)),
      if (filters.longevity != null)
        (labelFor(kLongevityOptions, '${filters.longevity}'), filters.copyWith(clearLongevity: true)),
      if (filters.sale) ('On sale', filters.copyWith(sale: false)),
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final (label, next) in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text(label),
                labelStyle: AppText.sans(12.5, weight: FontWeight.w600),
                backgroundColor: BrandColors.goldSoft.withValues(alpha: 0.6),
                side: BorderSide.none,
                deleteIcon: const Icon(Icons.close_rounded, size: 15),
                onDeleted: () => onChanged(next),
                onPressed: () => onChanged(next),
              ),
            ),
          TextButton(
            onPressed: () => onChanged(filters.cleared().copyWith(clearQ: true)),
            child: Text(
              'Clear all',
              style: AppText.sans(
                12.5,
                weight: FontWeight.w700,
              ).copyWith(decoration: TextDecoration.underline, decorationColor: BrandColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}

/// One-tap family chips when nothing is filtered yet.
class _QuickFamilies extends StatelessWidget {
  const _QuickFamilies({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kFamilySwatches.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = kFamilySwatches[i];
          return Material(
            color: BrandColors.card,
            shape: const StadiumBorder(side: BorderSide(color: BrandColors.line)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onPick(f.value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: f.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(f.label, style: AppText.sans(12.5, weight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
