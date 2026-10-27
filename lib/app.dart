import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'state/app_scope.dart';
import 'theme.dart';

/// Screenshot mode: `?shot=1` simulates an iPhone's safe areas on the web so
/// the portfolio mockup's status bar and home indicator never cover content.
final bool shotMode = kIsWeb && Uri.base.queryParameters.containsKey('shot');

class BalinciaApp extends StatefulWidget {
  const BalinciaApp({super.key, this.initialLocation});

  /// Used by tests; on the web the browser URL decides.
  final String? initialLocation;

  @override
  State<BalinciaApp> createState() => _BalinciaAppState();
}

class _BalinciaAppState extends State<BalinciaApp> {
  late final AppState _state = AppState.demo();
  late final GoRouter _router = buildRouter(_state, initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp.router(
        title: 'Balincia — Maison de Parfum',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: _router,
        builder: (context, child) {
          if (!shotMode) return child!;
          const pad = EdgeInsets.only(top: 47, bottom: 34);
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(padding: pad, viewPadding: pad),
            child: child!,
          );
        },
      ),
    );
  }
}
