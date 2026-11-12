import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/wheel_picker.dart';

/// 画面中央にドラムロールを出す。
/// 「決定」なら選んだ時間、キャンセルなら null を返す（0時間0分 = タイマーをオフにする）。
Future<Duration?> showSleepTimerDialog(
  BuildContext context, {
  required Duration initial,
}) {
  return showCupertinoDialog<Duration>(
    context: context,
    barrierDismissible: true, // 外側をタップするとキャンセル
    builder: (_) => SleepTimerDialog(initial: initial),
  );
}

class SleepTimerDialog extends StatefulWidget {
  const SleepTimerDialog({super.key, required this.initial});

  /// ドラムを最初に合わせる時間
  final Duration initial;

  static const maxHours = 9; // 選べる時間は 0〜9 時間
  static const minutesPerHour = 60; // 選べる分は 0〜59 分

  @override
  State<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<SleepTimerDialog> {
  // ドラムを回すたびに setState すると全体が再描画されるので、
  // 値は ValueNotifier に持たせ、「結果の文言」だけを再描画する
  late final _hours = ValueNotifier<int>(
    widget.initial.inHours.clamp(0, SleepTimerDialog.maxHours),
  );
  late final _minutes = ValueNotifier<int>(widget.initial.inMinutes % 60);

  late final _hourController = FixedExtentScrollController(
    initialItem: _hours.value,
  );
  late final _minuteController = FixedExtentScrollController(
    initialItem: _minutes.value,
  );

  Duration get _selected =>
      Duration(hours: _hours.value, minutes: _minutes.value);

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  /// 例: 「1時間30分後に停止」「オフ（ループ再生）」
  String _describe(Duration d) {
    if (d == Duration.zero) return 'オフ（ループ再生）';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return '${[if (hours > 0) '$hours時間', if (minutes > 0) '$minutes分'].join()}後に停止';
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: p.surface,
          child: SizedBox(
            width: 320,
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'スリープタイマー',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: WheelPicker(
                          controller: _hourController,
                          itemCount: SleepTimerDialog.maxHours + 1,
                          unit: '時間',
                          onSelected: (hours) => _hours.value = hours,
                        ),
                      ),
                      Expanded(
                        child: WheelPicker(
                          controller: _minuteController,
                          itemCount: SleepTimerDialog.minutesPerHour,
                          unit: '分',
                          onSelected: (minutes) => _minutes.value = minutes,
                        ),
                      ),
                    ],
                  ),
                  ListenableBuilder(
                    listenable: Listenable.merge([_hours, _minutes]),
                    builder: (_, _) => Text(
                      _describe(_selected),
                      style: TextStyle(fontSize: 13, color: p.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'キャンセル',
                            style: TextStyle(color: p.textSecondary),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 24,
                        child: VerticalDivider(color: p.hairline),
                      ),
                      Expanded(
                        child: CupertinoButton(
                          onPressed: () => Navigator.of(context).pop(_selected),
                          child: Text(
                            '決定',
                            style: TextStyle(
                              color: p.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
