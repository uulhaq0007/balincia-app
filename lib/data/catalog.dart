// Port of the web store's src/lib/catalog.ts + src/lib/constants.ts:
// filter parsing, the where-clause (as a predicate), sorting and collections.

import '../models/product.dart';
import 'products.dart';
import 'reviews.dart';

class Option {
  const Option(this.value, this.label);
  final String value;
  final String label;
}

const kGenders = [Option('MEN', 'Men'), Option('WOMEN', 'Women'), Option('UNISEX', 'Unisex')];

const kFamilies = [
  Option('woody', 'Woody'),
  Option('oud', 'Oud'),
  Option('floral', 'Floral'),
  Option('fresh', 'Fresh'),
  Option('citrus', 'Citrus'),
  Option('oriental', 'Oriental'),
  Option('gourmand', 'Gourmand'),
  Option('spicy', 'Spicy'),
  Option('aquatic', 'Aquatic'),
  Option('fruity', 'Fruity'),
];

const kSeasons = [
  Option('spring', 'Spring'),
  Option('summer', 'Summer'),
  Option('autumn', 'Autumn'),
  Option('winter', 'Winter'),
];

const kGenres = [
  Option('ARABIC', 'Arabic'),
  Option('FRENCH', 'French'),
  Option('WESTERN', 'Western'),
  Option('EASTERN', 'Eastern'),
];

const kOccasions = [
  Option('day', 'Day'),
  Option('night', 'Night'),
  Option('office', 'Office'),
  Option('evening', 'Evening'),
  Option('signature', 'Signature'),
];

const kSortOptions = [
  Option('featured', 'Featured'),
  Option('popular', 'Best selling'),
  Option('newest', 'Newest'),
  Option('price-asc', 'Price: low to high'),
  Option('price-desc', 'Price: high to low'),
  Option('rating', 'Top rated'),
];

class PriceRange {
  const PriceRange(this.label, this.min, this.max);
  final String label;
  final int? min;
  final int? max;
}

/// Same buckets as the web FilterPanel.
const kPriceRanges = [
  PriceRange('Under Rs. 2,000', null, 2000),
  PriceRange('Rs. 2,000 – 3,500', 2000, 3500),
  PriceRange('Rs. 3,500 – 5,000', 3500, 5000),
  PriceRange('Rs. 5,000 +', 5000, null),
];

const kLongevityOptions = [Option('3', '6+ hours'), Option('4', '8+ hours'), Option('5', '12+ hours')];

const kLongevityLabels = {1: '2 – 3 hrs', 2: '4 – 5 hrs', 3: '6 – 8 hrs', 4: '8 – 12 hrs', 5: '12+ hrs'};
const kPerformanceLabels = {1: 'Intimate', 2: 'Soft', 3: 'Moderate', 4: 'Strong', 5: 'Beast mode'};

const kConcentrationLabels = {
  'EDP': 'Eau de Parfum',
  'EDT': 'Eau de Toilette',
  'EXTRAIT': 'Extrait de Parfum',
  'PARFUM': 'Parfum',
  'ATTAR': 'Attar (oil)',
  'MIST': 'Body Mist',
  'HOME': 'Home Fragrance',
  'SET': 'Gift / Sample Set',
};

String labelFor(List<Option> options, String value) =>
    options.firstWhere((o) => o.value == value, orElse: () => Option(value, value)).label;

/// Family swatches from the home page's FamilyExplorer.
class FamilySwatch {
  const FamilySwatch(this.value, this.label, this.description, this.color);
  final String value;
  final String label;
  final String description;
  final Color color;
}

const kFamilySwatches = [
  FamilySwatch('woody', 'Woody', 'Cedar, vetiver, sandalwood', Color(0xff7a5a3a)),
  FamilySwatch('oud', 'Oud', 'Smoky, resinous, regal', Color(0xff3b1d12)),
  FamilySwatch('floral', 'Floral', 'Rose, jasmine, tuberose', Color(0xffc0607a)),
  FamilySwatch('fresh', 'Fresh', 'Clean, airy, green', Color(0xff5a8a7a)),
  FamilySwatch('citrus', 'Citrus', 'Lemon, bergamot, lime', Color(0xffd0a020)),
  FamilySwatch('oriental', 'Oriental', 'Amber, spice, resin', Color(0xffa0522d)),
  FamilySwatch('gourmand', 'Gourmand', 'Vanilla, tonka, praline', Color(0xff9a6a4a)),
  FamilySwatch('aquatic', 'Aquatic', 'Sea salt, marine, mint', Color(0xff2a6a8a)),
];

/// Filters exactly as `CatalogFilters` on the web; [matches] mirrors `filtersToWhere`.
class CatalogFilters {
  const CatalogFilters({
    this.q,
    this.gender = const {},
    this.family = const {},
    this.season = const {},
    this.genre = const {},
    this.occasion = const {},
    this.category = const {},
    this.minPrice,
    this.maxPrice,
    this.longevity,
    this.sale = false,
    this.sort = 'featured',
  });

  final String? q;
  final Set<String> gender;
  final Set<String> family;
  final Set<String> season;
  final Set<String> genre;
  final Set<String> occasion;
  final Set<String> category;
  final int? minPrice;
  final int? maxPrice;
  final int? longevity;
  final bool sale;
  final String sort;

  /// Parses `/shop?gender=MEN&family=woody,oud&min=2000&longevity=4…` like `parseFilters`.
  factory CatalogFilters.fromQuery(Map<String, String> qp) {
    Set<String> list(String key) => (qp[key] ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    int? num(String key) => int.tryParse(qp[key] ?? '');
    final q = qp['q']?.trim();
    return CatalogFilters(
      q: q == null || q.isEmpty ? null : q,
      gender: list('gender'),
      family: list('family'),
      season: list('season'),
      genre: list('genre'),
      occasion: list('occasion'),
      category: list('category'),
      minPrice: num('min'),
      maxPrice: num('max'),
      longevity: num('longevity'),
      sale: qp['sale'] == '1',
      sort: qp['sort'] ?? 'featured',
    );
  }

  bool matches(Product p) {
    final query = q?.toLowerCase();
    if (query != null && query.isNotEmpty) {
      final category = categoryBySlug(p.category)?.name.toLowerCase() ?? '';
      final hit = [
        p.name,
        p.tagline,
        p.topNotes,
        p.heartNotes,
        p.baseNotes,
        p.familiesRaw,
        category,
      ].any((field) => field.toLowerCase().contains(query));
      if (!hit) return false;
    }
    if (gender.isNotEmpty && !gender.contains(p.gender)) return false;
    if (genre.isNotEmpty && !genre.contains(p.genre)) return false;
    if (category.isNotEmpty && !category.contains(p.category)) return false;
    // anyContains(): the product matches if it carries at least one selected value.
    if (family.isNotEmpty && !family.any(p.familiesRaw.contains)) return false;
    if (season.isNotEmpty && !season.any(p.seasonsRaw.contains)) return false;
    if (occasion.isNotEmpty && !occasion.any(p.occasionsRaw.contains)) return false;
    if (minPrice != null && p.price < minPrice!) return false;
    if (maxPrice != null && p.price > maxPrice!) return false;
    if (longevity != null && longevity! > 0 && p.longevity < longevity!) return false;
    if (sale && p.compareAtPrice == null) return false;
    return true;
  }

  /// Mirrors `sortToOrderBy`.
  List<Product> sorted(Iterable<Product> products) {
    final list = products.toList();
    int byIndexDesc(Product a, Product b) => b.index.compareTo(a.index);
    switch (sort) {
      case 'popular':
        list.sort((a, b) => b.soldCount.compareTo(a.soldCount));
      case 'newest':
        list.sort((a, b) {
          final n = (b.isNew ? 1 : 0).compareTo(a.isNew ? 1 : 0);
          return n != 0 ? n : byIndexDesc(a, b);
        });
      case 'price-asc':
        list.sort((a, b) => a.price.compareTo(b.price));
      case 'price-desc':
        list.sort((a, b) => b.price.compareTo(a.price));
      case 'rating':
        list.sort((a, b) {
          final r = ratingOf(b).compareTo(ratingOf(a));
          return r != 0 ? r : b.ratingCount.compareTo(a.ratingCount);
        });
      default:
        list.sort((a, b) {
          final f = (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0);
          if (f != 0) return f;
          final s = b.soldCount.compareTo(a.soldCount);
          return s != 0 ? s : byIndexDesc(a, b);
        });
    }
    return list;
  }

  List<Product> apply(Iterable<Product> products) => sorted(products.where(matches));

  /// Number of active refinements (the "Filters (n)" badge). Search and sort excluded.
  int get activeCount =>
      gender.length +
      family.length +
      season.length +
      genre.length +
      occasion.length +
      category.length +
      (minPrice != null || maxPrice != null ? 1 : 0) +
      (longevity != null ? 1 : 0) +
      (sale ? 1 : 0);

  bool get isEmpty => activeCount == 0;

  PriceRange? get priceRange {
    for (final r in kPriceRanges) {
      if (r.min == minPrice && r.max == maxPrice) return r;
    }
    return null;
  }

  CatalogFilters copyWith({
    String? q,
    bool clearQ = false,
    Set<String>? gender,
    Set<String>? family,
    Set<String>? season,
    Set<String>? genre,
    Set<String>? occasion,
    Set<String>? category,
    int? minPrice,
    int? maxPrice,
    bool clearPrice = false,
    int? longevity,
    bool clearLongevity = false,
    bool? sale,
    String? sort,
  }) {
    return CatalogFilters(
      q: clearQ ? null : (q ?? this.q),
      gender: gender ?? this.gender,
      family: family ?? this.family,
      season: season ?? this.season,
      genre: genre ?? this.genre,
      occasion: occasion ?? this.occasion,
      category: category ?? this.category,
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      longevity: clearLongevity ? null : (longevity ?? this.longevity),
      sale: sale ?? this.sale,
      sort: sort ?? this.sort,
    );
  }

  /// Clears every refinement but keeps the sort order.
  CatalogFilters cleared() => CatalogFilters(sort: sort);

  /// Toggles [value] in one of the multi-select groups.
  CatalogFilters toggle(String group, String value) {
    Set<String> flip(Set<String> s) => s.contains(value) ? ({...s}..remove(value)) : {...s, value};
    return switch (group) {
      'gender' => copyWith(gender: flip(gender)),
      'family' => copyWith(family: flip(family)),
      'season' => copyWith(season: flip(season)),
      'genre' => copyWith(genre: flip(genre)),
      'occasion' => copyWith(occasion: flip(occasion)),
      'category' => copyWith(category: flip(category)),
      _ => this,
    };
  }

  Set<String> group(String key) => switch (key) {
    'gender' => gender,
    'family' => family,
    'season' => season,
    'genre' => genre,
    'occasion' => occasion,
    'category' => category,
    _ => const {},
  };
}

/// A collection page: either a category or one of the web's VIRTUAL_COLLECTIONS.
class Collection {
  const Collection({
    required this.slug,
    required this.name,
    required this.description,
    required this.dark,
    required this.light,
    required this.where,
    this.defaultSort = 'featured',
    this.shape = BottleShape.classic,
  });

  final String slug;
  final String name;
  final String description;
  final Color dark;
  final Color light;
  final bool Function(Product p) where;
  final String defaultSort;
  final BottleShape shape;
}

bool _notHomeOrSet(Product p) => p.concentration != 'HOME' && p.concentration != 'SET';

final Map<String, Collection> kVirtualCollections = {
  'best-sellers': Collection(
    slug: 'best-sellers',
    name: 'Best Sellers',
    description: 'The scents Pakistan keeps coming back to — our most-loved bottles, ranked by you.',
    dark: const Color(0xff1f1a17),
    light: const Color(0xffc9a27a),
    where: (p) => p.isBestseller,
    defaultSort: 'popular',
  ),
  'new-arrivals': Collection(
    slug: 'new-arrivals',
    name: 'New Arrivals',
    description: 'Fresh from the atelier. The newest compositions to join the Balincia library.',
    dark: const Color(0xff20302b),
    light: const Color(0xffa7c4b5),
    where: (p) => p.isNew,
    defaultSort: 'newest',
    shape: BottleShape.tall,
  ),
  'under-2000': Collection(
    slug: 'under-2000',
    name: 'Under Rs. 2,000',
    description: 'Big character, gentle price. Every scent here is under two thousand rupees.',
    dark: const Color(0xff3a2a1c),
    light: const Color(0xffe2b07a),
    where: (p) => p.price <= 2000,
    shape: BottleShape.mist,
  ),
  'oud': Collection(
    slug: 'oud',
    name: 'The Oud Edit',
    description: 'Smoky, resinous and regal — compositions built around precious agarwood.',
    dark: const Color(0xff1a0f0a),
    light: const Color(0xff8b5a2b),
    where: (p) => p.families.contains('oud') || p.name.toLowerCase().contains('oud'),
    shape: BottleShape.attar,
  ),
  'sale': Collection(
    slug: 'sale',
    name: 'On Sale',
    description: "Limited-time prices on selected favourites. When they're gone, they're gone.",
    dark: const Color(0xff3b1219),
    light: const Color(0xffe08a8a),
    where: (p) => p.compareAtPrice != null,
    shape: BottleShape.round,
  ),
  'men': Collection(
    slug: 'men',
    name: 'For Him',
    description: 'Woody, spicy and commanding. Signature scents composed for men.',
    dark: const Color(0xff141820),
    light: const Color(0xff7d8ca3),
    where: (p) => (p.gender == 'MEN' || p.gender == 'UNISEX') && _notHomeOrSet(p),
  ),
  'women': Collection(
    slug: 'women',
    name: 'For Her',
    description: 'Florals, fruits and soft musks — luminous perfumes composed for women.',
    dark: const Color(0xff3a1f2b),
    light: const Color(0xffe7b8c4),
    where: (p) => (p.gender == 'WOMEN' || p.gender == 'UNISEX') && _notHomeOrSet(p),
    shape: BottleShape.round,
  ),
  'unisex': Collection(
    slug: 'unisex',
    name: 'Unisex',
    description: 'Scents without rules. Compositions made to be shared, borrowed and claimed by anyone.',
    dark: const Color(0xff2f2a24),
    light: const Color(0xffc8b59a),
    where: (p) => p.gender == 'UNISEX' && _notHomeOrSet(p),
    shape: BottleShape.tall,
  ),
};

const _categoryShapes = {
  'attars': BottleShape.attar,
  'gift-sets': BottleShape.box,
  'discovery-sets': BottleShape.box,
  'body-mists': BottleShape.mist,
  'home-fragrance': BottleShape.diffuser,
  'noir': BottleShape.tall,
  'diwan': BottleShape.round,
};

/// Resolves `/collections/:slug`, like `resolveCollection` on the web.
Collection? resolveCollection(String slug) {
  final virtual = kVirtualCollections[slug];
  if (virtual != null) return virtual;
  final c = categoryBySlug(slug);
  if (c == null) return null;
  return Collection(
    slug: c.slug,
    name: c.name,
    description: c.description,
    dark: c.dark,
    light: c.light,
    where: (p) => p.category == c.slug,
    shape: _categoryShapes[c.slug] ?? BottleShape.classic,
  );
}

Category? categoryBySlug(String slug) {
  for (final c in kCategories) {
    if (c.slug == slug) return c;
  }
  return null;
}

Product? productBySlug(String slug) {
  for (final p in kProducts) {
    if (p.slug == slug) return p;
  }
  return null;
}

Product productNamed(String slug) => productBySlug(slug)!;

/// Compact card label, e.g. "Signature · EDP" or just "Gift Sets".
String productEyebrow(Product p) {
  final category = (categoryBySlug(p.category)?.name ?? '').replaceAll(' Collection', '');
  const short = {'EDP': 'EDP', 'EDT': 'EDT', 'EXTRAIT': 'Extrait', 'PARFUM': 'Parfum', 'ATTAR': 'Perfume oil'};
  final concentration = short[p.concentration];
  return concentration == null ? category : '$category · $concentration';
}

/// Products that share a family with [p], for "You may also like".
List<Product> relatedTo(Product p, {int take = 6}) {
  final scored =
      kProducts.where((o) => o.slug != p.slug).map((o) {
        final shared = o.families.where(p.families.contains).length;
        final sameCategory = o.category == p.category ? 1 : 0;
        return (o, shared * 2 + sameCategory);
      }).toList()..sort((a, b) {
        final s = b.$2.compareTo(a.$2);
        return s != 0 ? s : b.$1.soldCount.compareTo(a.$1.soldCount);
      });
  return scored.take(take).map((e) => e.$1).toList();
}
