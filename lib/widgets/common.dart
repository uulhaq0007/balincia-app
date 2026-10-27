import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/format.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../theme.dart';

/// Small tracked uppercase label.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = BrandColors.gold, this.size = 10.5});

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: AppText.eyebrow(color: color, size: size));
}

/// Fraunces headline where `*words*` are set in gold italics, like the web's
/// `Our <em>best sellers</em>`.
class EditorialText extends StatelessWidget {
  const EditorialText(
    this.text, {
    super.key,
    this.size = 28,
    this.weight = FontWeight.w400,
    this.color = BrandColors.ink,
    this.accent = BrandColors.gold,
    this.textAlign = TextAlign.start,
    this.height = 1.1,
    this.accentWeight,
  });

  final String text;
  final double size;
  final FontWeight weight;
  final FontWeight? accentWeight;
  final Color color;
  final Color accent;
  final TextAlign textAlign;
  final double height;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('*');
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < parts.length; i++)
            TextSpan(
              text: parts[i],
              style: i.isOdd
                  ? AppText.display(size, weight: accentWeight ?? weight, italic: true, color: accent, height: height)
                  : AppText.display(size, weight: weight, color: color, height: height),
            ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final String eyebrow;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(eyebrow),
                const SizedBox(height: 8),
                EditorialText(title, size: 27),
              ],
            ),
          ),
          if (actionLabel != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(99),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 2, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!.toUpperCase(),
                      style: AppText.sans(10.5, weight: FontWeight.w800, letterSpacing: 1.6),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 15),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "FROM Rs. 2,490  Rs. 2,890"
class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.price, this.compareAtPrice, this.from = false, this.size = 14});

  PriceTag.product(Product p, {super.key, this.size = 14})
    : price = p.price,
      compareAtPrice = p.compareAtPrice,
      from = p.hasRange;

  final int price;
  final int? compareAtPrice;
  final bool from;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sale = compareAtPrice != null && compareAtPrice! > price;
    return Text.rich(
      TextSpan(
        children: [
          if (from)
            TextSpan(
              text: 'FROM ',
              style: AppText.sans(size * 0.68, weight: FontWeight.w700, color: BrandColors.muted, letterSpacing: 0.6),
            ),
          TextSpan(
            text: formatPrice(price),
            style: AppText.sans(size, weight: FontWeight.w700, color: sale ? BrandColors.sale : BrandColors.ink),
          ),
          if (sale)
            TextSpan(
              text: '  ${formatPrice(compareAtPrice!)}',
              style: AppText.sans(size * 0.78, weight: FontWeight.w500, color: BrandColors.muted).copyWith(
                decoration: TextDecoration.lineThrough,
                decorationColor: BrandColors.muted,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class Stars extends StatelessWidget {
  const Stars({super.key, required this.rating, this.size = 12, this.color = BrandColors.gold});

  final double rating;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : rating >= i - 0.5
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
            size: size,
            color: color,
          ),
      ],
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.background = BrandColors.ink, this.foreground = BrandColors.gold2});

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(99)),
      child: Text(text.toUpperCase(), style: AppText.sans(8.5, weight: FontWeight.w800, color: foreground, letterSpacing: 1.1, height: 1.1)),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.value, required this.onChanged, this.min = 1, this.max = 10, this.compact = false});

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 36.0 : 46.0;
    Widget button(IconData icon, VoidCallback? onTap, String label) => SizedBox(
      width: h,
      height: h,
      child: IconButton(
        tooltip: label,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        iconSize: compact ? 16 : 18,
        color: BrandColors.ink,
        disabledColor: BrandColors.muted.withValues(alpha: 0.5),
        icon: Icon(icon),
      ),
    );
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: BrandColors.card,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: BrandColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove_rounded, value > min ? () => onChanged(value - 1) : null, 'Decrease quantity'),
          SizedBox(
            width: compact ? 18 : 24,
            child: Text('$value', textAlign: TextAlign.center, style: AppText.sans(compact ? 13.5 : 15, weight: FontWeight.w700)),
          ),
          button(Icons.add_rounded, value < max ? () => onChanged(value + 1) : null, 'Increase quantity'),
        ],
      ),
    );
  }
}

/// Round translucent icon button used over artwork.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color = BrandColors.ink,
    this.background,
    this.size = 40,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color color;
  final Color? background;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: background ?? BrandColors.paper.withValues(alpha: 0.86),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(width: size, height: size, child: Icon(icon, size: iconSize, color: color)),
        ),
      ),
    );
  }
}

/// Heart toggle bound to the wishlist store.
class WishlistButton extends StatelessWidget {
  const WishlistButton({super.key, required this.product, this.size = 34, this.background});

  final Product product;
  final double size;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.wishlist;
    return ListenableBuilder(
      listenable: wishlist,
      builder: (context, _) {
        final saved = wishlist.contains(product);
        return GlassIconButton(
          tooltip: saved ? 'Remove from wishlist' : 'Save to wishlist',
          size: size,
          iconSize: size * 0.5,
          background: background,
          color: saved ? BrandColors.sale : BrandColors.ink,
          icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          onPressed: () {
            final added = wishlist.toggle(product);
            showToast(
              context,
              added ? '${product.name} saved to your wishlist' : '${product.name} removed from your wishlist',
              actionLabel: added ? 'View' : null,
              onAction: added ? () => context.push('/wishlist') : null,
            );
          },
        );
      },
    );
  }
}

/// App bar bag icon with a live count badge.
class BagButton extends StatelessWidget {
  const BagButton({super.key, this.color = BrandColors.ink});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final cart = context.cart;
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => IconButton(
        tooltip: 'Bag',
        onPressed: () => context.go('/bag'),
        icon: Badge(
          isLabelVisible: cart.count > 0,
          backgroundColor: BrandColors.gold,
          textColor: Colors.white,
          label: Text('${cart.count}', style: AppText.sans(9.5, weight: FontWeight.w800, color: Colors.white)),
          child: Icon(Icons.shopping_bag_outlined, color: color),
        ),
      ),
    );
  }
}

class WishlistIconButton extends StatelessWidget {
  const WishlistIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.wishlist;
    return ListenableBuilder(
      listenable: wishlist,
      builder: (context, _) => IconButton(
        tooltip: 'Wishlist',
        onPressed: () => context.push('/wishlist'),
        icon: Badge(
          isLabelVisible: wishlist.count > 0,
          backgroundColor: BrandColors.ink,
          textColor: BrandColors.paper,
          label: Text('${wishlist.count}', style: AppText.sans(9.5, weight: FontWeight.w800, color: BrandColors.paper)),
          child: const Icon(Icons.favorite_border_rounded),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(color: BrandColors.paper2, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: BrandColors.gold),
          ),
          const SizedBox(height: 22),
          Text(title, textAlign: TextAlign.center, style: AppText.display(28)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: AppText.sans(14.5, color: BrandColors.inkSoft, height: 1.5)),
          const SizedBox(height: 24),
          if (primaryLabel != null)
            FilledButton(onPressed: onPrimary, child: Text(primaryLabel!.toUpperCase())),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onSecondary, child: Text(secondaryLabel!.toUpperCase())),
          ],
        ],
      ),
    );
  }
}

/// Floating snackbar in the brand style.
void showToast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(milliseconds: 2600),
      action: actionLabel == null ? null : SnackBarAction(label: actionLabel.toUpperCase(), onPressed: onAction ?? () {}),
    ),
  );
}

/// Back button that falls back to [fallback] when the page was opened directly.
class BackOrHomeButton extends StatelessWidget {
  const BackOrHomeButton({super.key, this.fallback = '/', this.glass = false});

  final String fallback;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    void back() => context.canPop() ? context.pop() : context.go(fallback);
    if (glass) {
      return GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, iconSize: 17, tooltip: 'Back', onPressed: back);
    }
    return IconButton(tooltip: 'Back', onPressed: back, icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19));
  }
}

/// Paper card with a hairline border.
class PaperCard extends StatelessWidget {
  const PaperCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.color = BrandColors.card, this.radius = 22});

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: BrandColors.line.withValues(alpha: 0.8)),
        boxShadow: [BoxShadow(color: BrandColors.ink.withValues(alpha: 0.03), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }
}

/// A totals row: label on the left, amount on the right.
class AmountRow extends StatelessWidget {
  const AmountRow(this.label, this.value, {super.key, this.accent, this.bold = false});

  final String label;
  final String value;
  final Color? accent;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppText.sans(14, color: accent ?? BrandColors.inkSoft, weight: bold ? FontWeight.w700 : FontWeight.w500)),
          ),
          Text(value, style: AppText.sans(14, weight: FontWeight.w700, color: accent ?? BrandColors.ink)),
        ],
      ),
    );
  }
}
