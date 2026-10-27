import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/app_scope.dart';
import '../theme.dart';

/// Bottom navigation: Home, Shop, Quiz, Bag, Account.
class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final cart = context.cart;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: BrandColors.line))),
        child: ListenableBuilder(
          listenable: cart,
          builder: (context, _) => NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Shop',
              ),
              const NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Quiz',
              ),
              NavigationDestination(
                icon: _bagIcon(cart.count, selected: false),
                selectedIcon: _bagIcon(cart.count, selected: true),
                label: 'Bag',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bagIcon(int count, {required bool selected}) => Badge(
    isLabelVisible: count > 0,
    backgroundColor: BrandColors.gold,
    textColor: Colors.white,
    label: Text('$count', style: AppText.sans(9.5, weight: FontWeight.w800, color: Colors.white)),
    child: Icon(selected ? Icons.shopping_bag_rounded : Icons.shopping_bag_outlined),
  );
}
