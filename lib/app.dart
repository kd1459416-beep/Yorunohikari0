import 'package:flutter/material.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/auth_gate.dart';
import 'features/reminder/reminder_service.dart';

class YorunohikariApp extends StatelessWidget {
  const YorunohikariApp({
    super.key,
    required this.theme,
    required this.reminder,
  });

  final ThemeController theme;
  final NursingReminderController reminder;

  @override
  Widget build(BuildContext context) {
    return NursingReminderScope(
      controller: reminder,
      child: ThemeScope(
        controller: theme,
        child: ListenableBuilder(
          listenable: theme,
          builder: (_, _) => MaterialApp(
            title: 'ヨルノヒカリ',
            debugShowCheckedModeBanner: false,
            theme: theme.lightTheme,
            darkTheme: theme.darkTheme,
            themeMode: theme.mode,
            themeAnimationDuration: theme.isTuning
                ? Duration
                      .zero // スライダー操作中は即時
                : const Duration(milliseconds: 350),
            themeAnimationCurve: Curves.easeInOut,
            home: const AuthGate(),
          ),
        ),
      ),
    );
  }
}
