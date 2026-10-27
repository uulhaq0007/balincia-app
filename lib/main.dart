import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'theme.dart';

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // Fraunces and Manrope ship in assets/google_fonts, so nothing is fetched at
  // runtime; warm them up so the first frame is already in the brand faces.
  GoogleFonts.config.allowRuntimeFetching = false;
  await GoogleFonts.pendingFonts(AppText.preload).timeout(const Duration(seconds: 4), onTimeout: () => const []);

  runApp(const BalinciaApp());
}
