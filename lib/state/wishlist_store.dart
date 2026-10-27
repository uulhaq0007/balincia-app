import 'package:flutter/foundation.dart';

import '../data/catalog.dart';
import '../models/product.dart';

class WishlistStore extends ChangeNotifier {
  WishlistStore([Iterable<String> initial = const []]) : _slugs = {...initial};

  final Set<String> _slugs;

  bool contains(Product p) => _slugs.contains(p.slug);
  int get count => _slugs.length;

  List<Product> get products => [
    for (final slug in _slugs)
      if (productBySlug(slug) case final p?) p,
  ];

  /// Returns true when the product is now saved.
  bool toggle(Product p) {
    final added = !_slugs.remove(p.slug);
    if (added) _slugs.add(p.slug);
    notifyListeners();
    return added;
  }
}
