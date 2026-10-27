import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.wishlist;
    return ListenableBuilder(
      listenable: wishlist,
      builder: (context, _) {
        final products = wishlist.products;
        return Scaffold(
          appBar: AppBar(
            leading: const BackOrHomeButton(fallback: '/account'),
            title: const Text('Wishlist'),
            actions: const [BagButton(), SizedBox(width: 6)],
          ),
          body: products.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: EmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'Nothing saved yet',
                      message: 'Tap the heart on any scent to keep it here for later.',
                      primaryLabel: 'Browse the library',
                      onPrimary: () => context.go('/shop'),
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EditorialText('Saved for *later*', size: 30),
                            const SizedBox(height: 6),
                            Text(
                              '${products.length} ${products.length == 1 ? 'scent' : 'scents'} saved. Tap a heart to remove one, or add them all to your bag.',
                              style: AppText.sans(13.5, color: BrandColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ProductSliverGrid(products: products),
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  ],
                ),
          bottomNavigationBar: products.isEmpty
              ? null
              : Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: const BoxDecoration(
                    color: Color(0xfffbf8f3),
                    border: Border(top: BorderSide(color: BrandColors.line)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: FilledButton(
                      onPressed: () {
                        final cart = context.cart;
                        for (final p in products) {
                          cart.add(p, p.cheapest);
                        }
                        showToast(context, '${products.length} scents added to your bag');
                        context.go('/bag');
                      },
                      child: const Text('ADD ALL TO BAG'),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
