import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/format.dart';
import '../data/pricing.dart';
import '../data/quiz.dart';
import '../models/commerce.dart';
import '../state/account_store.dart';
import '../state/app_scope.dart';
import '../theme.dart';
import '../widgets/commerce_widgets.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

/// Profile, Balincia Points and loyalty tier, order history and settings.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.account;
    final wishlist = context.wishlist;
    return ListenableBuilder(
      listenable: Listenable.merge([account, wishlist]),
      builder: (context, _) {
        final c = account.customer;
        final orders = account.orders;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: false,
            titleSpacing: 20,
            toolbarHeight: 64,
            title: Text('Account', style: AppText.display(30)),
            actions: [
              IconButton(
                tooltip: 'Concierge',
                onPressed: () => showConciergeSheet(context),
                icon: const Icon(Icons.support_agent_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BrandColors.goldSoft,
                      border: Border.all(color: BrandColors.gold2),
                    ),
                    child: Text(
                      c.initials,
                      style: AppText.display(23, color: BrandColors.ink2, weight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: AppText.display(23)),
                        const SizedBox(height: 2),
                        Text(c.email, style: AppText.sans(13, color: BrandColors.inkSoft)),
                        Text(
                          'Member since ${formatMonthYear(c.memberSince)}',
                          style: AppText.sans(12, color: BrandColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _LoyaltyCard(account: account),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.05,
                children: [
                  _QuickTile(
                    icon: Icons.favorite_border_rounded,
                    title: 'Wishlist',
                    subtitle: pluralize(wishlist.count, 'scent'),
                    onTap: () => context.push('/wishlist'),
                  ),
                  _QuickTile(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Scent persona',
                    subtitle: account.quizAnswers == null
                        ? 'Take the quiz'
                        : kPersonas[account.quizAnswers!['vibe']]?.name ?? 'View results',
                    onTap: () => account.quizAnswers == null
                        ? context.go('/quiz')
                        : context.go(Uri(path: '/quiz/results', queryParameters: account.quizAnswers).toString()),
                  ),
                  _QuickTile(
                    icon: Icons.storefront_outlined,
                    title: 'Boutiques',
                    subtitle: '8 stores · 6 cities',
                    onTap: () => showBoutiquesSheet(context),
                  ),
                  _QuickTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Concierge',
                    subtitle: 'Call, chat or email',
                    onTap: () => showConciergeSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(child: Text('Your orders', style: AppText.display(24))),
                  Text(
                    pluralize(orders.length, 'order'),
                    style: AppText.sans(12.5, color: BrandColors.muted, weight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final o in orders) ...[_OrderCard(order: o), const SizedBox(height: 10)],
              const SizedBox(height: 16),
              PaperCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionLabel(
                      'Saved address',
                      trailing: TextButton(
                        onPressed: () => showAddressSheet(context, account),
                        child: Text(
                          'Edit',
                          style: AppText.sans(12.5, weight: FontWeight.w700, color: BrandColors.gold),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.home_outlined, size: 20, color: BrandColors.gold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(account.address.fullName, style: AppText.sans(14, weight: FontWeight.w700)),
                              Text(
                                '${account.address.singleLine}\n${account.address.phone}',
                                style: AppText.sans(13, color: BrandColors.inkSoft, height: 1.45),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  const _LoyaltyCard({required this.account});

  final AccountStore account;

  @override
  Widget build(BuildContext context) {
    final (:tier, :next) = loyaltyTier(account.lifetimeSpend);
    final progress = next == null ? 1.0 : ((account.lifetimeSpend - tier.min) / (next.min - tier.min)).clamp(0.0, 1.0);
    final pending = account.pendingPoints;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff2e1d12), BrandColors.oud, Color(0xff120c09)],
        ),
        boxShadow: [
          BoxShadow(color: BrandColors.oud.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('BALINCIA POINTS', style: AppText.eyebrow(color: BrandColors.gold2)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: BrandColors.gold2.withValues(alpha: 0.6)),
                ),
                child: Text(
                  '${tier.name.toUpperCase()} MEMBER',
                  style: AppText.sans(9.5, weight: FontWeight.w800, color: BrandColors.gold2, letterSpacing: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                groupDigits(account.points),
                style: AppText.display(50, color: BrandColors.paper, weight: FontWeight.w300, height: 1),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('points', style: AppText.sans(14, color: BrandColors.paper.withValues(alpha: 0.7))),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '= ${formatPrice(account.points)} off',
                  style: AppText.sans(13, weight: FontWeight.w700, color: BrandColors.gold2),
                ),
              ),
            ],
          ),
          if (pending > 0) ...[
            const SizedBox(height: 6),
            Text(
              '+$pending pending from orders on the way',
              style: AppText.sans(12, color: BrandColors.paper.withValues(alpha: 0.6)),
            ),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              color: BrandColors.gold2,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            next == null ? 'You’ve reached Noir' : '${formatPrice(next.min - account.lifetimeSpend)} to ${next.name}',
            style: AppText.sans(12.5, weight: FontWeight.w700, color: BrandColors.paper),
          ),
          const SizedBox(height: 2),
          Text(
            next == null ? tier.perk : 'Unlocks ${next.perk.toLowerCase()}',
            style: AppText.sans(12, color: BrandColors.paper.withValues(alpha: 0.65), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: BrandColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 21, color: BrandColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.sans(13.5, weight: FontWeight.w800)),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(11.5, color: BrandColors.muted),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: BrandColors.line),
      ),
      child: InkWell(
        onTap: () => context.push('/orders/${order.number}'),
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              BottleStack(products: [for (final l in order.lines) l.product]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(order.number, style: AppText.sans(13.5, weight: FontWeight.w800, letterSpacing: 0.3)),
                        const Spacer(),
                        StatusPill(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDate(order.placedAt)} · ${pluralize(order.itemCount, 'item')}',
                      style: AppText.sans(12, color: BrandColors.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(formatPrice(order.total), style: AppText.display(17, weight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: BrandColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
