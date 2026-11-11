import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_palette.dart';

abstract final class AppTheme {
  // アクセント色はスライダーで変わらないので、配色は1度だけ作って使い回す
  static final _darkScheme = ColorScheme.fromSeed(
    seedColor: AppPalette.dark().accent,
    brightness: Brightness.dark,
  );
  static final _lightScheme = ColorScheme.fromSeed(
    seedColor: AppPalette.light().accent,
    brightness: Brightness.light,
  );

  static ThemeData build(AppPalette p, Brightness brightness) {
    final base = brightness == Brightness.dark ? _darkScheme : _lightScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: base.copyWith(
        primary: p.accent,
        onPrimary: Colors.black87,
        surface: p.surface,
        onSurface: p.textPrimary,
      ),
      dividerTheme: DividerThemeData(
        color: p.hairline,
        thickness: 0.5,
        space: 0.5,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: [p],
    );
  }
}
