import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/catalog.dart';
import '../data/products.dart';
import '../data/store_data.dart';
import '../models/product.dart';
import '../theme.dart';
import '../widgets/bottle_art.dart';
import '../widgets/common.dart';

/// Live search across names, taglines, notes, families and collections —
/// the same fields as the web catalogue's `q` filter.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    if (widget.initialQuery.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setQuery(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
  }

  @override
  Widget build(BuildContext context) {
    final q = _controller.text.trim();
    final results = q.isEmpty ? <Product>[] : CatalogFilters(q: q, sort: 'popular').apply(kProducts);

    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(fallback: '/shop'),
        titleSpacing: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            style: AppText.sans(15, weight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search oud, rose, gifts…',
              prefixIcon: const Icon(Icons.search_rounded, size: 21, color: BrandColors.muted),
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      onPressed: () => _setQuery(''),
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: const BorderSide(color: BrandColors.line)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: const BorderSide(color: BrandColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: const BorderSide(color: BrandColors.gold, width: 1.3),
              ),
            ),
          ),
        ),
      ),
      body: q.isEmpty ? _Suggestions(onPick: _setQuery) : _Results(query: q, results: results),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final trending = ['noir-oud-royale', 'velvet-rose', 'saffron-dusk', 'karachi-breeze'].map(productNamed).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        const Eyebrow('Popular searches'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in kPopularSearches)
              ActionChip(
                label: Text(s),
                labelStyle: AppText.sans(13, weight: FontWeight.w600),
                avatar: const Icon(Icons.north_west_rounded, size: 14, color: BrandColors.muted),
                onPressed: () => onPick(s),
              ),
          ],
        ),
        const SizedBox(height: 28),
        const Eyebrow('Trending now'),
        const SizedBox(height: 6),
        for (final p in trending) _ResultRow(product: p),
        const SizedBox(height: 24),
        const Eyebrow('Browse collections'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final slug in ['best-sellers', 'new-arrivals', 'oud', 'under-2000', 'attars', 'gift-sets'])
              ActionChip(
                label: Text(resolveCollection(slug)!.name),
                labelStyle: AppText.sans(13, weight: FontWeight.w600),
                onPressed: () => context.go('/shop/collections/$slug'),
              ),
          ],
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.query, required this.results});

  final String query;
  final List<Product> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Nothing for “$query”',
            message: 'Try a note like saffron or vetiver, a family like woody, or a collection name.',
            primaryLabel: 'Browse the library',
            onPrimary: () => context.go('/shop'),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            Expanded(child: Eyebrow('${results.length} ${results.length == 1 ? 'match' : 'matches'}')),
            TextButton(
              onPressed: () => context.go('/shop?q=${Uri.encodeQueryComponent(query)}'),
              child: Text('View as grid', style: AppText.sans(12.5, weight: FontWeight.w700)),
            ),
          ],
        ),
        for (final p in results) _ResultRow(product: p, highlight: query),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.product, this.highlight});

  final Product product;
  final String? highlight;

  /// Which note/family the query matched, shown as a hint.
  String? get _matchedNote {
    final q = highlight?.toLowerCase();
    if (q == null) return null;
    for (final note in [...product.top, ...product.heart, ...product.base]) {
      if (note.toLowerCase().contains(q)) return 'Note: $note';
    }
    for (final f in product.families) {
      if (f.contains(q)) return 'Family: ${labelFor(kFamilies, f)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = product;
    final hint = _matchedNote;
    return InkWell(
      onTap: () => context.push('/product/${p.slug}'),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(width: 64, height: 80, child: BottleArt.product(p, showName: false)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: AppText.display(17.5)),
                  const SizedBox(height: 2),
                  Text(p.tagline, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sans(12.5, color: BrandColors.inkSoft)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      PriceTag.product(p, size: 13),
                      if (hint != null) ...[
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(11.5, weight: FontWeight.w600, color: BrandColors.gold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: BrandColors.muted),
          ],
        ),
      ),
    );
  }
}
