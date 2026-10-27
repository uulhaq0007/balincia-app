import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/common.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackOrHomeButton()),
      body: Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: Icons.explore_off_outlined,
            title: 'This page has evaporated',
            message: "We couldn't find what you were looking for. It may have moved or sold out.",
            primaryLabel: 'Back to home',
            onPrimary: () => context.go('/'),
            secondaryLabel: 'Browse the library',
            onSecondary: () => context.go('/shop'),
          ),
        ),
      ),
    );
  }
}
