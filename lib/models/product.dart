import 'package:flutter/painting.dart';

export 'package:flutter/painting.dart' show Color;

/// The eight generative bottle silhouettes from the web store's BottleArt.
enum BottleShape { classic, round, tall, attar, box, diffuser, candle, mist }

class Variant {
  const Variant({required this.label, required this.price, this.compareAtPrice});

  final String label;
  final int price;
  final int? compareAtPrice;

  bool get onSale => compareAtPrice != null && compareAtPrice! > price;
}

class Category {
  const Category({
    required this.slug,
    required this.name,
    required this.description,
    required this.dark,
    required this.light,
  });

  final String slug;
  final String name;
  final String description;
  final Color dark;
  final Color light;
}

class Product {
  const Product({
    required this.index,
    required this.name,
    required this.slug,
    required this.category,
    required this.tagline,
    required this.description,
    required this.gender,
    required this.concentration,
    required this.genre,
    required this.topNotes,
    required this.heartNotes,
    required this.baseNotes,
    required this.familiesRaw,
    required this.seasonsRaw,
    required this.occasionsRaw,
    required this.longevity,
    required this.sillage,
    required this.dark,
    required this.light,
    required this.shape,
    required this.variants,
    required this.isFeatured,
    required this.isBestseller,
    required this.isNew,
    required this.ratingCount,
    required this.soldCount,
  });

  /// Position in the seed catalogue; doubles as "created" order for sorting.
  final int index;
  final String name;
  final String slug;

  /// Category slug, see [kCategories].
  final String category;
  final String tagline;
  final String description;

  /// MEN | WOMEN | UNISEX
  final String gender;

  /// EDP | EDT | EXTRAIT | ATTAR | MIST | HOME | SET
  final String concentration;

  /// ARABIC | FRENCH | WESTERN | EASTERN
  final String genre;
  final String topNotes;
  final String heartNotes;
  final String baseNotes;
  final String familiesRaw;
  final String seasonsRaw;
  final String occasionsRaw;

  /// 1–5 scales, as in the web store.
  final int longevity;
  final int sillage;
  final Color dark;
  final Color light;
  final BottleShape shape;
  final List<Variant> variants;
  final bool isFeatured;
  final bool isBestseller;
  final bool isNew;
  final int ratingCount;
  final int soldCount;

  List<String> get families => _split(familiesRaw);
  List<String> get seasons => _split(seasonsRaw);
  List<String> get occasions => _split(occasionsRaw);
  List<String> get top => _split(topNotes);
  List<String> get heart => _split(heartNotes);
  List<String> get base => _split(baseNotes);

  /// The cheapest variant drives the listed price, like `syncProductPrice`.
  Variant get cheapest => variants.reduce((a, b) => a.price <= b.price ? a : b);
  int get price => cheapest.price;
  int? get compareAtPrice => cheapest.onSale ? cheapest.compareAtPrice : null;
  bool get onSale => variants.any((v) => v.onSale);
  bool get hasRange => variants.map((v) => v.price).toSet().length > 1;

  int get discountPercent {
    final compare = compareAtPrice;
    if (compare == null) return 0;
    return ((compare - price) / compare * 100).round();
  }

  static List<String> _split(String raw) =>
      raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}
