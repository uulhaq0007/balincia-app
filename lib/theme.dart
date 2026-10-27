import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette from the web store's globals.css.
abstract final class BrandColors {
  static const paper = Color(0xfff6f1e9);
  static const paper2 = Color(0xffeee6d9);
  static const paper3 = Color(0xffe4d9c8);
  static const ink = Color(0xff16120f);
  static const ink2 = Color(0xff2b241f);
  static const inkSoft = Color(0xff4d443c);
  static const muted = Color(0xff8b8073);
  static const line = Color(0xffddd2c2);
  static const gold = Color(0xffa97c48);
  static const gold2 = Color(0xffc9a27a);
  static const goldSoft = Color(0xffecdcc2);
  static const oud = Color(0xff24170f);
  static const sale = Color(0xff9b3a35);
  static const sage = Color(0xff46654f);
  static const card = Color(0xfffffdf9);
}

/// Typography helpers. Fraunces (display serif) and Manrope (sans) are bundled
/// under assets/google_fonts, so only the weights listed there are used.
abstract final class AppText {
  /// Fraunces: 300–600 upright, 300–500 italic.
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w400,
    bool italic = false,
    Color color = BrandColors.ink,
    double height = 1.12,
  }) {
    final w = italic
        ? _clampWeight(weight, FontWeight.w300, FontWeight.w500)
        : _clampWeight(weight, FontWeight.w300, FontWeight.w600);
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: w,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: color,
      height: height,
      letterSpacing: -0.015 * size,
    );
  }

  /// Manrope: 400–800.
  static TextStyle sans(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = BrandColors.ink,
    double height = 1.4,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: _clampWeight(weight, FontWeight.w400, FontWeight.w800),
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Small tracked uppercase label (`.eyebrow` on the web).
  static TextStyle eyebrow({Color color = BrandColors.gold, double size = 10.5}) =>
      sans(size, weight: FontWeight.w700, color: color, letterSpacing: size * 0.2, height: 1.2);

  /// Button text: bold, tracked, uppercase by convention.
  static TextStyle button({Color color = BrandColors.paper, double size = 12.5}) =>
      sans(size, weight: FontWeight.w700, color: color, letterSpacing: size * 0.08, height: 1.1);

  static FontWeight _clampWeight(FontWeight w, FontWeight min, FontWeight max) {
    if (w.value < min.value) return min;
    if (w.value > max.value) return max;
    return w;
  }

  /// Every style the app uses, so fonts can be warmed up before first paint.
  static List<TextStyle> get preload => [
    for (final w in [FontWeight.w300, FontWeight.w400, FontWeight.w500, FontWeight.w600]) display(12, weight: w),
    for (final w in [FontWeight.w300, FontWeight.w400, FontWeight.w500]) display(12, weight: w, italic: true),
    for (final w in [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800])
      sans(12, weight: w),
  ];
}

ThemeData buildTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: BrandColors.ink,
    onPrimary: BrandColors.paper,
    primaryContainer: BrandColors.goldSoft,
    onPrimaryContainer: BrandColors.ink,
    secondary: BrandColors.gold,
    onSecondary: Colors.white,
    secondaryContainer: BrandColors.goldSoft,
    onSecondaryContainer: BrandColors.ink,
    tertiary: BrandColors.sage,
    onTertiary: Colors.white,
    error: BrandColors.sale,
    onError: Colors.white,
    surface: BrandColors.paper,
    onSurface: BrandColors.ink,
    onSurfaceVariant: BrandColors.inkSoft,
    surfaceContainerLowest: BrandColors.card,
    surfaceContainerLow: Color(0xfff2ece2),
    surfaceContainer: BrandColors.paper2,
    surfaceContainerHigh: BrandColors.paper2,
    surfaceContainerHighest: BrandColors.paper3,
    outline: Color(0xffc9bba7),
    outlineVariant: BrandColors.line,
    shadow: BrandColors.ink,
    scrim: BrandColors.ink,
    inverseSurface: BrandColors.ink,
    onInverseSurface: BrandColors.paper,
    inversePrimary: BrandColors.gold2,
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final text = GoogleFonts.manropeTextTheme(base.textTheme).apply(
    bodyColor: BrandColors.ink,
    displayColor: BrandColors.ink,
  );

  final pill = WidgetStatePropertyAll<OutlinedBorder>(
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
  );

  return base.copyWith(
    scaffoldBackgroundColor: BrandColors.paper,
    textTheme: text.copyWith(
      displayLarge: AppText.display(48, weight: FontWeight.w300),
      displayMedium: AppText.display(40, weight: FontWeight.w300),
      displaySmall: AppText.display(34),
      headlineLarge: AppText.display(30),
      headlineMedium: AppText.display(26),
      headlineSmall: AppText.display(22),
      titleLarge: AppText.display(20),
    ),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: BrandColors.paper,
      foregroundColor: BrandColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: AppText.display(21, weight: FontWeight.w500),
      iconTheme: const IconThemeData(color: BrandColors.ink, size: 22),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xfffbf8f3),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 66,
      indicatorColor: BrandColors.goldSoft,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppText.sans(
          11,
          weight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
          color: states.contains(WidgetState.selected) ? BrandColors.ink : BrandColors.muted,
          letterSpacing: 0.3,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 23,
          color: states.contains(WidgetState.selected) ? BrandColors.ink : BrandColors.muted,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? BrandColors.ink.withValues(alpha: 0.35) : BrandColors.ink,
        ),
        foregroundColor: const WidgetStatePropertyAll(BrandColors.paper),
        overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.08)),
        minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24)),
        shape: pill,
        textStyle: WidgetStatePropertyAll(AppText.button()),
        elevation: const WidgetStatePropertyAll(0),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(BrandColors.ink),
        side: const WidgetStatePropertyAll(BorderSide(color: BrandColors.ink, width: 1)),
        minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 22)),
        shape: pill,
        textStyle: WidgetStatePropertyAll(AppText.button(color: BrandColors.ink)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(BrandColors.ink),
        textStyle: WidgetStatePropertyAll(AppText.sans(13, weight: FontWeight.w700)),
        shape: pill,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(foregroundColor: const WidgetStatePropertyAll(BrandColors.ink)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: BrandColors.card,
      selectedColor: BrandColors.ink,
      disabledColor: BrandColors.paper2,
      side: const BorderSide(color: BrandColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: AppText.sans(13, weight: FontWeight.w600, color: BrandColors.ink),
      secondaryLabelStyle: AppText.sans(13, weight: FontWeight.w600, color: BrandColors.paper),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      showCheckmark: false,
      checkmarkColor: BrandColors.paper,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: BrandColors.paper,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: BrandColors.paper,
      showDragHandle: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BrandColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: AppText.sans(14.5, color: BrandColors.muted, weight: FontWeight.w500),
      labelStyle: AppText.sans(14, color: BrandColors.inkSoft),
      floatingLabelStyle: AppText.sans(13, color: BrandColors.gold, weight: FontWeight.w700),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BrandColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BrandColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BrandColors.gold, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BrandColors.sale),
      ),
    ),
    dividerTheme: const DividerThemeData(color: BrandColors.line, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: BrandColors.ink,
      contentTextStyle: AppText.sans(13.5, color: BrandColors.paper, weight: FontWeight.w600),
      actionTextColor: BrandColors.gold2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : BrandColors.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? BrandColors.gold : BrandColors.paper3,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? BrandColors.ink : BrandColors.muted,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: BrandColors.gold,
      linearTrackColor: BrandColors.paper3,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: BrandColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: AppText.sans(14, weight: FontWeight.w600),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
