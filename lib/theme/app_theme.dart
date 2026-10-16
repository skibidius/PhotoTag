import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Builds the Material 3 (Material You) theme.
///
/// On Android 12+ the scheme is derived from the system wallpaper via
/// [dynamic_color]; elsewhere it falls back to a seeded baseline scheme. The
/// whole UI uses Google Sans so the app reads like a first-party Google app.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF00696D);

  static ThemeData light() => _base(
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
      );

  static ThemeData dark() => _base(
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      );

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'GoogleSans',
      brightness: scheme.brightness,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: _textTheme(),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'GoogleSans',
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'GoogleSans',
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'GoogleSans',
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: TextStyle(fontFamily: 'GoogleSans'),
      ),
    );
  }

  static TextTheme _textTheme() {
    const TextStyle base = TextStyle(
      fontFamily: 'GoogleSans',
      letterSpacing: 0.1,
    );
    return TextTheme(
      displayLarge: base.copyWith(fontSize: 57, fontWeight: FontWeight.w400),
      displayMedium: base.copyWith(fontSize: 45, fontWeight: FontWeight.w400),
      displaySmall: base.copyWith(fontSize: 36, fontWeight: FontWeight.w500),
      headlineLarge: base.copyWith(fontSize: 32, fontWeight: FontWeight.w500),
      headlineMedium: base.copyWith(fontSize: 28, fontWeight: FontWeight.w500),
      headlineSmall: base.copyWith(fontSize: 24, fontWeight: FontWeight.w500),
      titleLarge: base.copyWith(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: base.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: base.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: base.copyWith(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: base.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: base.copyWith(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: base.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: base.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: base.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
    );
  }
}
