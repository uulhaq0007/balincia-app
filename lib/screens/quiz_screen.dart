import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/quiz.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../state/quiz_session.dart';
import '../theme.dart';
import '../widgets/bottle_art.dart';
import '../widgets/common.dart';

const _optionIcons = {
  'WOMEN': Icons.female_rounded,
  'MEN': Icons.male_rounded,
  'ANY': Icons.all_inclusive_rounded,
  'day': Icons.wb_sunny_outlined,
  'office': Icons.work_outline_rounded,
  'evening': Icons.wine_bar_outlined,
  'night': Icons.bedtime_outlined,
  'summer': Icons.wb_sunny_outlined,
  'winter': Icons.ac_unit_rounded,
  'spring': Icons.local_florist_outlined,
  'autumn': Icons.eco_outlined,
  '2': Icons.water_drop_outlined,
  '3': Icons.air_rounded,
  '5': Icons.local_fire_department_outlined,
};

/// Five questions, one per step — `/quiz?step=3` opens mid-quiz with an answer picked.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.demoStep});

  final int? demoStep;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Timer? _advance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final step = widget.demoStep;
    if (step != null && !_seeded) {
      _seeded = true;
      context.quiz.seedDemo(step);
    }
  }

  bool _seeded = false;

  @override
  void dispose() {
    _advance?.cancel();
    super.dispose();
  }

  void _choose(QuizSession quiz, String value) {
    quiz.choose(value);
    _advance?.cancel();
    if (!quiz.isLast) {
      _advance = Timer(const Duration(milliseconds: 320), () {
        if (mounted) quiz.next();
      });
    }
  }

  void _finish(QuizSession quiz) {
    final answers = quiz.answers;
    context.account.saveQuiz(answers);
    context.go(Uri(path: '/quiz/results', queryParameters: answers).toString());
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.quiz;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: quiz,
          builder: (context, _) {
            final q = quiz.question;
            final selected = quiz.currentAnswer;
            final vibe = kQuiz[1].options.where((o) => o.value == quiz.answers['vibe']).firstOrNull;
            return Column(
              children: [
                _Header(accent: vibe?.color),
                _Progress(quiz: quiz),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
                        child: child,
                      ),
                    ),
                    child: ListView(
                      key: ValueKey(quiz.step),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      children: [
                        Text(q.question, style: AppText.display(29, height: 1.12)),
                        const SizedBox(height: 18),
                        for (final o in q.options)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _OptionCard(
                              option: o,
                              selected: selected == o.value,
                              onTap: () => _choose(quiz, o.value),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: BrandColors.line))),
                  child: Row(
                    children: [
                      if (quiz.step > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: SizedBox(
                            width: 52,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, side: const BorderSide(color: BrandColors.line)),
                              onPressed: quiz.back,
                              child: const Icon(Icons.arrow_back_rounded, size: 20),
                            ),
                          ),
                        ),
                      Expanded(
                        child: FilledButton(
                          onPressed: selected == null ? null : () => quiz.isLast ? _finish(quiz) : quiz.next(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(quiz.isLast ? 'SEE MY MATCHES' : 'NEXT QUESTION'),
                              const SizedBox(width: 8),
                              Icon(quiz.isLast ? Icons.auto_awesome : Icons.arrow_forward_rounded, size: 17),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.accent});

  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: Stack(
        children: [
          Positioned(
            right: 54,
            top: 14,
            width: 58,
            height: 84,
            child: Transform.rotate(
              angle: -0.2,
              child: const BottleArt(dark: Color(0xff5a1a2c), light: Color(0xffe9a3b5), shape: BottleShape.round, bare: true),
            ),
          ),
          Positioned(
            right: 12,
            top: 6,
            width: 60,
            height: 92,
            child: Transform.rotate(
              angle: 0.16,
              child: BottleArt(
                dark: accent == null ? const Color(0xff2b2118) : Color.lerp(accent, Colors.black, 0.6)!,
                light: accent ?? const Color(0xffc9a27a),
                shape: BottleShape.tall,
                bare: true,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 130, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('The scent quiz'),
                SizedBox(height: 8),
                EditorialText('Find your *signature*', size: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.quiz});

  final QuizSession quiz;

  @override
  Widget build(BuildContext context) {
    final answered = [
      for (final q in kQuiz.take(quiz.step))
        if (quiz.answers[q.key] != null) (kQuiz.indexOf(q), answerLabel(q.key, quiz.answers[q.key]!)),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'QUESTION ${quiz.step + 1} OF ${kQuiz.length}',
                style: AppText.sans(11, weight: FontWeight.w800, letterSpacing: 1.7, color: BrandColors.muted),
              ),
              const Spacer(),
              Text(
                '${((quiz.step + 1) / kQuiz.length * 100).round()}%',
                style: AppText.sans(11, weight: FontWeight.w800, color: BrandColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < kQuiz.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= quiz.step ? BrandColors.gold : BrandColors.paper3,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (answered.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (index, label) in answered)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(99),
                        onTap: () {
                          while (quiz.step > index) {
                            quiz.back();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: BrandColors.goldSoft.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_rounded, size: 13, color: BrandColors.gold),
                              const SizedBox(width: 4),
                              Text(label, style: AppText.sans(12, weight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.option, required this.selected, required this.onTap});

  final QuizOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? BrandColors.paper : BrandColors.ink;
    final swatch = option.color;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: selected ? BrandColors.ink : BrandColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: selected ? BrandColors.ink : BrandColors.line),
              boxShadow: selected
                  ? [BoxShadow(color: BrandColors.ink.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))]
                  : const [],
            ),
            child: Stack(
              children: [
                if (swatch != null)
                  Positioned(
                    right: -30,
                    top: -36,
                    width: 110,
                    height: 110,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [swatch.withValues(alpha: selected ? 0.55 : 0.4), swatch.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: swatch ?? (selected ? Colors.white.withValues(alpha: 0.1) : BrandColors.paper2),
                        ),
                        child: swatch != null
                            ? null
                            : Icon(_optionIcons[option.value], size: 21, color: selected ? BrandColors.gold2 : BrandColors.gold),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(option.label, style: AppText.display(20, color: fg, height: 1.15)),
                            const SizedBox(height: 2),
                            Text(
                              option.hint,
                              style: AppText.sans(13, color: selected ? BrandColors.paper.withValues(alpha: 0.7) : BrandColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? BrandColors.gold : Colors.transparent,
                          border: Border.all(color: selected ? BrandColors.gold : BrandColors.line, width: 1.5),
                        ),
                        child: selected ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
