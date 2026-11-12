import 'dart:ui' show FontFeature;
import 'package:flutter/cupertino.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/time_format.dart';
import 'bgm_controller.dart';
import 'sleep_timer_dialog.dart';

/// BGM画面の右上に置くタイマーボタン。
/// 作動中は、アイコンの左に「残り 12:34」をリアルタイムで表示する。
class SleepTimerButton extends StatelessWidget {
  const SleepTimerButton({super.key, required this.controller});

  final BgmController controller;

  Future<void> _openDialog(BuildContext context) async {
    final selected = await showSleepTimerDialog(
      context,
      initial: controller.timerPreset,
    );
    if (selected != null) controller.setTimer(selected);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isActive = controller.timerActive;
        final color = isActive ? p.accent : p.textSecondary;

        return CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          onPressed: () => _openDialog(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive)
                // 毎秒変わるのはこの文字だけ。画面全体は再描画しない
                ValueListenableBuilder<Duration>(
                  valueListenable: controller.remaining,
                  builder: (_, remaining, _) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '残り ${formatCountdown(remaining)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        // 数字の幅をそろえて、カウントダウン中に文字がぶれないようにする
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              Icon(CupertinoIcons.timer, size: 26, color: color),
            ],
          ),
        );
      },
    );
  }
}
