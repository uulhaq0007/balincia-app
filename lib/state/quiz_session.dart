import 'package:flutter/foundation.dart';

import '../data/quiz.dart';

/// Progress through the five-question scent quiz.
class QuizSession extends ChangeNotifier {
  int _step = 0;
  final Map<String, String> _answers = {};

  int get step => _step;
  QuizAnswers get answers => Map.unmodifiable(_answers);
  QuizQuestion get question => kQuiz[_step];
  String? get currentAnswer => _answers[question.key];
  bool get isLast => _step == kQuiz.length - 1;

  void choose(String value) {
    _answers[question.key] = value;
    notifyListeners();
  }

  void next() {
    if (_step < kQuiz.length - 1) {
      _step++;
      notifyListeners();
    }
  }

  void back() {
    if (_step > 0) {
      _step--;
      notifyListeners();
    }
  }

  void reset() {
    _step = 0;
    _answers.clear();
    notifyListeners();
  }

  /// Jumps to question [oneBasedStep] with the demo answers filled in up to
  /// and including it — the `/quiz?step=3` screenshot state.
  void seedDemo(int oneBasedStep) {
    _step = (oneBasedStep - 1).clamp(0, kQuiz.length - 1);
    _answers
      ..clear()
      ..addAll({for (final q in kQuiz.take(_step + 1)) q.key: kDemoAnswers[q.key]!});
    notifyListeners();
  }
}
