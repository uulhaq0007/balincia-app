import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/product.dart';
import '../theme.dart';

/// Opens the filter bottom sheet and resolves with the applied filters, or
/// null when dismissed.
Future<CatalogFilters?> showFilterSheet(
  BuildContext context, {
  required CatalogFilters initial,
  required List<Product> base,
  Set<String> hide = const {},
}) {
  return showModalBottomSheet<CatalogFilters>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    barrierColor: BrandColors.ink.withValues(alpha: 0.38),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      snap: true,
      snapSizes: const [0.6],
      builder: (context, controller) =>
          FilterSheet(initial: initial, base: base, hide: hide, scrollController: controller),
    ),
  );
}

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.initial,
    required this.base,
    this.hide = const {},
    this.scrollController,
  });

  final ScrollController? scrollController;
  final CatalogFilters initial;

  /// The products being filtered (the whole library, or one collection).
  final List<Product> base;
  final Set<String> hide;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _Group {
  const _Group(this.key, this.title, this.options);
  final String key;
  final String title;
  final List<Option> options;
}

const _groups = [
  _Group('gender', 'Gender', kGenders),
  _Group('family', 'Scent family', kFamilies),
  _Group('season', 'Season', kSeasons),
  _Group('occasion', 'Occasion', kOccasions),
];

class _FilterSheetState extends State<FilterSheet> {
  late CatalogFilters _draft = widget.initial;

  int get _count => widget.base.where(_draft.matches).length;

  @override
  Widget build(BuildContext context) {
    final count = _count;
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(color: BrandColors.paper3, borderRadius: BorderRadius.circular(9)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Filters', style: AppText.display(28)),
                if (!_draft.isEmpty) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: BrandColors.gold, borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      '${_draft.activeCount}',
                      style: AppText.sans(11.5, weight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: _draft.isEmpty ? null : () => setState(() => _draft = _draft.cleared()),
                  child: Text(
                    'Clear all',
                    style: AppText.sans(
                      13,
                      weight: FontWeight.w700,
                      color: _draft.isEmpty ? BrandColors.muted : BrandColors.ink,
                    ).copyWith(decoration: TextDecoration.underline, decorationColor: BrandColors.gold),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
              children: [
                for (final g in _groups)
                  if (!widget.hide.contains(g.key))
                    _Section(
                      title: g.title,
                      trailing: _draft.group(g.key).isEmpty ? null : '${_draft.group(g.key).length} selected',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final o in g.options)
                            ToggleChip(
                              label: o.label,
                              selected: _draft.group(g.key).contains(o.value),
                              onTap: () => setState(() => _draft = _draft.toggle(g.key, o.value)),
                            ),
                        ],
                      ),
                    ),
                _Section(
                  title: 'Price',
                  trailing: _draft.priceRange?.label,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in kPriceRanges)
                        ToggleChip(
                          label: r.label,
                          selected: _draft.priceRange == r,
                          onTap: () => setState(() {
                            _draft = _draft.priceRange == r
                                ? _draft.copyWith(clearPrice: true)
                                : _draft.copyWith(clearPrice: true).copyWith(minPrice: r.min, maxPrice: r.max);
                          }),
                        ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Longevity',
                  trailing: _draft.longevity == null ? null : kLongevityLabels[_draft.longevity],
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final l in kLongevityOptions)
                        ToggleChip(
                          label: l.label,
                          icon: Icons.schedule_rounded,
                          selected: _draft.longevity == int.parse(l.value),
                          onTap: () => setState(() {
                            final v = int.parse(l.value);
                            _draft = _draft.longevity == v
                                ? _draft.copyWith(clearLongevity: true)
                                : _draft.copyWith(longevity: v);
                          }),
                        ),
                    ],
                  ),
                ),
                if (!widget.hide.contains('genre'))
                  _Section(
                    title: 'Genre',
                    trailing: _draft.genre.isEmpty ? null : '${_draft.genre.length} selected',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in kGenres)
                          ToggleChip(
                            label: o.label,
                            selected: _draft.genre.contains(o.value),
                            onTap: () => setState(() => _draft = _draft.toggle('genre', o.value)),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ON SALE ONLY',
                              style: AppText.sans(11.5, weight: FontWeight.w800, letterSpacing: 1.6),
                            ),
                            const SizedBox(height: 2),
                            Text('Limited-time prices', style: AppText.sans(12.5, color: BrandColors.muted)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _draft.sale,
                        onChanged: (v) => setState(() => _draft = _draft.copyWith(sale: v)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: BrandColors.paper,
              border: Border(top: BorderSide(color: BrandColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: count == 0 ? null : () => Navigator.of(context).pop(_draft),
                    child: Text(
                      count == 0
                          ? 'NO MATCHES — TRY FEWER FILTERS'
                          : 'SHOW $count ${count == 1 ? 'RESULT' : 'RESULTS'}',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BrandColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title.toUpperCase(), style: AppText.sans(11.5, weight: FontWeight.w800, letterSpacing: 1.6)),
              const Spacer(),
              if (trailing != null)
                Text(
                  trailing!,
                  style: AppText.sans(12, weight: FontWeight.w600, color: BrandColors.gold),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Pill chip that flips to ink when selected (the web `.chip[data-active]`).
class ToggleChip extends StatelessWidget {
  const ToggleChip({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? BrandColors.paper : BrandColors.ink;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? BrandColors.ink : BrandColors.card,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: selected ? BrandColors.ink : BrandColors.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check_rounded, size: 15, color: fg),
                  const SizedBox(width: 5),
                ] else if (icon != null) ...[
                  Icon(icon, size: 14, color: BrandColors.muted),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: AppText.sans(13, weight: FontWeight.w600, color: fg, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
