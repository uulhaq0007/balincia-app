// Review content from the web store's seed (reviewers + reviewPool), assigned
// deterministically per product so every launch shows the same store.

import '../models/commerce.dart';
import '../models/product.dart';

const _reviewers = [
  'Ayesha K.',
  'Hamza R.',
  'Fatima Z.',
  'Bilal A.',
  'Sana M.',
  'Usman T.',
  'Mahnoor S.',
  'Ali H.',
  'Zainab F.',
  'Omer Q.',
  'Hira N.',
  'Saad J.',
  'Iqra B.',
  'Daniyal W.',
  'Mehwish I.',
  'Fahad L.',
];

const _pool = [
  (
    5,
    'My new signature',
    'Lasts all day even in this heat. I get compliments every single time I wear it to the office.',
  ),
  (
    5,
    'Smells way more expensive',
    'Honestly comparable to designer bottles three times the price. The drydown is gorgeous.',
  ),
  (
    4,
    'Beautiful, slightly soft',
    'Gorgeous scent and lovely packaging. Projection is a little softer than I expected but longevity is great.',
  ),
  (
    5,
    'Gifted it, now buying for myself',
    'Bought this as a gift for my husband and ended up stealing it. Delivery to Lahore took just two days.',
  ),
  (
    5,
    'Perfect for weddings',
    'Wore it to a mehndi and three people asked what I was wearing. Will definitely reorder.',
  ),
  (4, 'Great value', 'Very good quality for the price. The bottle feels premium and the cap is nice and heavy.'),
  (
    5,
    'Obsessed',
    "The opening is lovely but the drydown after an hour is where it really shines. Still on my scarf the next morning.",
  ),
  (
    3,
    'Nice but not for me',
    'Well made and long lasting, just a bit too sweet for my taste. My sister loves it though.',
  ),
  (
    5,
    'Fast delivery, sealed packaging',
    'Arrived in Islamabad within 48 hours, perfectly packed. COD made it super easy.',
  ),
  (4, 'Lovely everyday scent', 'Easy to wear, not overpowering. Good for office and university.'),
];

/// Reference "today" for seeded sample data, so dates stay stable between runs.
final kDemoToday = DateTime(2026, 10, 27, 11, 20);

final Map<String, List<Review>> _cache = {};

List<Review> reviewsFor(Product p) => _cache.putIfAbsent(p.slug, () {
  // Park–Miller PRNG, like the seed script, keyed by catalogue position.
  var seed = 42 + p.index * 977;
  double rand() {
    seed = (seed * 16807) % 2147483647;
    return (seed - 1) / 2147483646;
  }

  final used = <int>{};
  final reviews = <Review>[];
  var daysAgo = 2 + (rand() * 6).floor();
  for (var i = 0; i < p.ratingCount; i++) {
    var pick = (rand() * _pool.length).floor();
    while (used.contains(pick) && used.length < _pool.length) {
      pick = (pick + 1) % _pool.length;
    }
    used.add(pick);
    final (rating, title, body) = _pool[pick];
    reviews.add(
      Review(
        name: _reviewers[(rand() * _reviewers.length).floor()],
        rating: rating,
        title: title,
        body: body,
        date: kDemoToday.subtract(Duration(days: daysAgo)),
      ),
    );
    daysAgo += 3 + (rand() * 14).floor();
  }
  return reviews;
});

final Map<String, double> _ratings = {};

/// Average star rating, rounded to one decimal like `recomputeProductRating`.
double ratingOf(Product p) => _ratings.putIfAbsent(p.slug, () {
  final reviews = reviewsFor(p);
  if (reviews.isEmpty) return 0;
  final avg = reviews.fold<int>(0, (s, r) => s + r.rating) / reviews.length;
  return (avg * 10).round() / 10;
});
