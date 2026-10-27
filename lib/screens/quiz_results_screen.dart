import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/catalog.dart';
import '../data/quiz.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../theme.dart';
import '../widgets/bottle_art.dart';
import '../widgets/common.dart';

/// Persona + top four matches, scored with the same rules as quiz.ts.
/// `?demo=1` uses the demo answers; otherwise answers come from the query.
class QuizResultsScreen extends StatefulWidget {
  const QuizResultsScreen({super.key, required this.query});

  final Map<String, String> query;

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  QuizAnswers? _answers;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_answers != null) return;
    final fromQuery = widget.query['demo'] == '1' ? kDemoAnswers : answersFromQuery(widget.query);
    if (isComplete(fromQuery)) {
      _answers = fromQuery;
      // Remember the result on the account, without notifying mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.account.saveQuiz(fromQuery);
      });
    } else {
      _answers = context.account.quizAnswers;
    }
  }

  void _retake() {
    context.quiz.reset();
    context.go('/quiz');
  }

  @override
  Widget build(BuildContext context) {
    final answers = _answers;
    if (answers == null || !isComplete(answers)) {
      return Scaffold(
        appBar: AppBar(leading: const BackOrHomeButton(fallback: '/quiz')),
        body: Center(
          child: EmptyState(
            icon: Icons.auto_awesome_outlined,
            title: 'No results yet',
            message: 'Answer five quick questions and we’ll match you with the scents made for you.',
            primaryLabel: 'Take the quiz',
            onPrimary: _retake,
          ),
        ),
      );
    }

    final persona = kPersonas[answers['vibe']] ?? kPersonas['warm']!;
    final matches = rankMatches(answers);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _PersonaHero(persona: persona, onRetake: _retake)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final q in kQuiz)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: BrandColors.card,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: BrandColors.line),
                      ),
                      child: Text(answerLabel(q.key, answers[q.key]!), style: AppText.sans(12, weight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 26, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow('Matched for you'),
                  SizedBox(height: 8),
                  EditorialText('Your top *four*', size: 30),
                ],
              ),
            ),
          ),
          SliverList.separated(
            itemCount: matches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _MatchCard(match: matches[i], rank: i + 1),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              child: Column(
                children: [
                  Text(
                    'Scored on gender, mood, occasion, season and projection across ${quizCandidates.length} perfumes and attars.',
                    textAlign: TextAlign.center,
                    style: AppText.sans(12, color: BrandColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => context.push('/product/top-5-discovery-set'),
                    child: const Text('NOT SURE? TRY THE DISCOVERY SET'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonaHero extends StatelessWidget {
  const _PersonaHero({required this.persona, required this.onRetake});

  final Persona persona;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: persona.dark,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -1.1),
                  radius: 1.1,
                  colors: [persona.light.withValues(alpha: 0.42), persona.light.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Positioned(
            left: -34,
            bottom: -30,
            width: 150,
            height: 180,
            child: Transform.rotate(
              angle: -0.22,
              child: Opacity(
                opacity: 0.75,
                child: BottleArt(dark: persona.dark, light: persona.light, shape: BottleShape.round, bare: true),
              ),
            ),
          ),
          Positioned(
            right: -26,
            bottom: -40,
            width: 120,
            height: 200,
            child: Transform.rotate(
              angle: 0.22,
              child: Opacity(
                opacity: 0.75,
                child: BottleArt(dark: persona.dark, light: persona.light, shape: BottleShape.tall, bare: true),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8, top + 4, 8, 0),
            child: Row(
              children: [
                BackOrHomeButtonLight(onRetake: onRetake),
                const Spacer(),
                IconButton(
                  tooltip: 'Retake the quiz',
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh_rounded, color: BrandColors.paper),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(28, top + 60, 28, 58),
            child: Column(
              children: [
                Text('YOUR SCENT PERSONA', style: AppText.eyebrow(color: persona.light)),
                const SizedBox(height: 14),
                Text(persona.name, textAlign: TextAlign.center, style: AppText.display(46, color: BrandColors.paper, height: 1)),
                const SizedBox(height: 14),
                Text(
                  persona.description,
                  textAlign: TextAlign.center,
                  style: AppText.sans(14.5, color: BrandColors.paper.withValues(alpha: 0.8), height: 1.55),
                ),
                const SizedBox(height: 22),
                TextButton.icon(
                  onPressed: onRetake,
                  style: TextButton.styleFrom(foregroundColor: BrandColors.paper),
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: Text('RETAKE THE QUIZ', style: AppText.button(color: BrandColors.paper, size: 11.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Back arrow in paper colour; falls back to restarting the quiz.
class BackOrHomeButtonLight extends StatelessWidget {
  const BackOrHomeButtonLight({super.key, required this.onRetake});

  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      onPressed: () => context.canPop() ? context.pop() : onRetake(),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: BrandColors.paper),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.rank});

  final QuizMatch match;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final p = match.product;
    return Material(
      color: BrandColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: BrandColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${p.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: 140,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BottleArt.product(p),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Pill(rank == 1 ? 'Best match' : '#$rank'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productEyebrow(p).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(8.6, weight: FontWeight.w700, color: BrandColors.muted, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(p.name, style: AppText.display(20, height: 1.1)),
                    const SizedBox(height: 2),
                    Text(p.tagline, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sans(12, color: BrandColors.inkSoft)),
                    const SizedBox(height: 10),
                    _MatchMeter(percent: match.percent),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: PriceTag.product(p, size: 13.5)),
                        GlassIconButton(
                          icon: Icons.add_shopping_cart_rounded,
                          size: 34,
                          iconSize: 17,
                          background: BrandColors.paper2,
                          tooltip: 'Add to bag',
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
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchMeter extends StatelessWidget {
  const _MatchMeter({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: CustomPaint(painter: _RingPainter(percent / 100)),
        ),
        const SizedBox(width: 8),
        Text('$percent%', style: AppText.display(19, weight: FontWeight.w500, color: BrandColors.gold)),
        const SizedBox(width: 5),
        Text('match', style: AppText.sans(12, weight: FontWeight.w600, color: BrandColors.inkSoft)),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2.5);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = BrandColors.paper3;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = BrandColors.gold;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}
