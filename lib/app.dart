import 'package:flutter/material.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/auth_gate.dart';

class YorunohikariApp extends StatelessWidget {
  const YorunohikariApp({super.key, required this.theme});

  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: theme,
      child: ListenableBuilder(
        listenable: theme,
        builder: (_, _) => MaterialApp(
          title: 'ヨルノヒカリ',
          debugShowCheckedModeBanner: false,
          theme: theme.lightTheme,
          darkTheme: theme.darkTheme,
          themeMode: theme.mode, // light / dark のどちらか
          themeAnimationDuration: theme.isTuning
              ? Duration
                    .zero // スライダー操作中は即時
              : const Duration(
                  milliseconds: 350,
                ), // ライト/ダーク切替はふんわり          themeAnimationCurve: Curves.easeInOut,
          home: const AuthGate(),
        ),
      ),
    );
  }
}
