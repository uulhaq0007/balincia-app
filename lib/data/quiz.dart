// Port of the web store's src/lib/quiz.ts: questions, personas and the
// server-side scoring used to rank the catalogue.

import 'package:flutter/painting.dart';

import '../models/product.dart';
import 'products.dart';
import 'reviews.dart';

class QuizOption {
  const QuizOption(this.value, this.label, this.hint, {this.color});
  final String value;
  final String label;
  final String hint;
  final Color? color;
}

class QuizQuestion {
  const QuizQuestion(this.key, this.question, this.options);
  final String key;
  final String question;
  final List<QuizOption> options;
}

const kQuiz = [
  QuizQuestion('gender', 'Who are we finding a scent for?', [
    QuizOption('WOMEN', 'For her', 'Feminine compositions'),
    QuizOption('MEN', 'For him', 'Masculine compositions'),
    QuizOption('ANY', 'Anyone', 'Show me everything'),
  ]),
  QuizQuestion('vibe', 'Pick the mood that feels most like you.', [
    QuizOption('fresh', 'Fresh & clean', 'Citrus, sea air, crisp linen', color: Color(0xff7cc6d6)),
    QuizOption('floral', 'Floral & romantic', 'Rose, jasmine, soft fruits', color: Color(0xffe9a3b5)),
    QuizOption('warm', 'Warm & sweet', 'Amber, vanilla, tonka', color: Color(0xffe7a65a)),
    QuizOption('dark', 'Dark & smoky', 'Oud, leather, incense', color: Color(0xff8b3a2a)),
  ]),
  QuizQuestion('occasion', 'When will you wear it most?', [
    QuizOption('day', 'Everyday', 'Errands, uni, weekends'),
    QuizOption('office', 'At work', 'Polished, never loud'),
    QuizOption('evening', 'Dinners & events', 'Weddings, dawats, parties'),
    QuizOption('night', 'Late nights', 'Made to be remembered'),
  ]),
  QuizQuestion('season', 'Which season do you want it for?', [
    QuizOption('summer', 'Summer', 'Light enough for 40°C'),
    QuizOption('winter', 'Winter', 'Rich and enveloping'),
    QuizOption('spring', 'Spring', 'Blooming and bright'),
    QuizOption('autumn', 'Autumn', 'Woody and warm'),
  ]),
  QuizQuestion('intensity', 'How bold should it be?', [
    QuizOption('2', 'A whisper', 'Close to the skin'),
    QuizOption('3', 'Noticeable', "Arm's-length aura"),
    QuizOption('5', 'A statement', 'Fills the room'),
  ]),
];

const kVibeFamilies = {
  'fresh': ['fresh', 'citrus', 'aquatic'],
  'floral': ['floral', 'fruity'],
  'warm': ['gourmand', 'oriental'],
  'dark': ['oud', 'woody', 'spicy'],
};

class Persona {
  const Persona(this.name, this.description, this.dark, this.light);
  final String name;
  final String description;
  final Color dark;
  final Color light;
}

const kPersonas = {
  'fresh': Persona(
    'The Free Spirit',
    "You're drawn to light, luminous scents that feel like a deep breath of sea air — effortless, clean and quietly confident.",
    Color(0xff12384a),
    Color(0xff7cc6d6),
  ),
  'floral': Persona(
    'The Romantic',
    'Blooms, petals and a little sweetness. Your scents are soft-spoken but unforgettable — like a love letter on silk.',
    Color(0xff5a1a2c),
    Color(0xffe9a3b5),
  ),
  'warm': Persona(
    'The Comfort Seeker',
    'Amber, vanilla and golden resins — you love fragrances that feel like cashmere and leave a warm, inviting trail.',
    Color(0xff4a2412),
    Color(0xffe7a65a),
  ),
  'dark': Persona(
    'The Mystic',
    'Smoke, oud and leather. You wear scent as a signature — intense, magnetic and impossible to ignore.',
    Color(0xff1a0a08),
    Color(0xff8b3a2a),
  ),
};

/// Answers keyed by question key (gender, vibe, occasion, season, intensity).
typedef QuizAnswers = Map<String, String>;

/// The answers used for `/quiz/results?demo=1` and `/quiz?step=n`.
const QuizAnswers kDemoAnswers = {
  'gender': 'MEN',
  'vibe': 'dark',
  'occasion': 'evening',
  'season': 'winter',
  'intensity': '5',
};

bool isComplete(QuizAnswers a) =>
    kQuiz.every((q) => q.options.any((o) => o.value == a[q.key]));

QuizAnswers answersFromQuery(Map<String, String> qp) => {
  for (final q in kQuiz)
    if (q.options.any((o) => o.value == qp[q.key])) q.key: qp[q.key]!,
};

/// Identical to `scoreProduct` in quiz.ts.
int scoreProduct(Product p, QuizAnswers a) {
  var score = 0;
  final gender = a['gender'] ?? 'ANY';
  if (gender != 'ANY') {
    if (p.gender == gender) {
      score += 3;
    } else if (p.gender == 'UNISEX') {
      score += 2;
    } else {
      score -= 10;
    }
  }
  final families = p.familiesRaw.split(',');
  score += (kVibeFamilies[a['vibe']] ?? const []).where(families.contains).take(2).length * 3;
  if (p.occasionsRaw.contains(a['occasion'] ?? '')) score += 2;
  if (p.seasonsRaw.contains(a['season'] ?? '')) score += 2;
  score += 2 - (p.sillage - (int.tryParse(a['intensity'] ?? '') ?? 3)).abs();
  return score;
}

/// Best achievable score for these answers — the denominator for "% match".
int maxScore(QuizAnswers a) => (a['gender'] == 'ANY' ? 0 : 3) + 6 + 2 + 2 + 2;

class QuizMatch {
  const QuizMatch(this.product, this.score, this.percent);
  final Product product;
  final int score;
  final int percent;
}

/// Ranks perfumes (no home, sets or mists) the way the quiz page does, top [take].
List<QuizMatch> rankMatches(QuizAnswers a, {int take = 4}) {
  final best = maxScore(a);
  final ranked = kProducts
      .where((p) => !const ['HOME', 'SET', 'MIST'].contains(p.concentration))
      .map((p) => (p, scoreProduct(p, a)))
      .toList()
    ..sort((x, y) {
      final s = y.$2.compareTo(x.$2);
      return s != 0 ? s : ratingOf(y.$1).compareTo(ratingOf(x.$1));
    });
  return ranked.take(take).map((r) {
    final pct = (r.$2 / best * 100).round().clamp(0, 100);
    return QuizMatch(r.$1, r.$2, pct);
  }).toList();
}

String answerLabel(String key, String value) {
  for (final q in kQuiz) {
    if (q.key != key) continue;
    for (final o in q.options) {
      if (o.value == value) return o.label;
    }
  }
  return value;
}
