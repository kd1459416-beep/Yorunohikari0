import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/inset_section.dart';
import '../../core/widgets/wheel_picker.dart';
import 'reminder_service.dart';

// ============================================================
//  1. 設定の行（マイページと、授乳・ねんねページに置く）
// ============================================================

/// 「授乳のお知らせ  12:30 に通知」の1行。タップで設定シートを開く。
class ReminderSettingsTile extends StatelessWidget {
  const ReminderSettingsTile({super.key});

  Future<void> _open(
    BuildContext context,
    NursingReminderController controller,
  ) async {
    final result = await showReminderSettingsSheet(
      context,
      initial: controller.settings,
    );
    if (result == null) return;

    final ok = await controller.update(
      enabled: result.enabled,
      interval: result.interval,
    );
    if (ok || !context.mounted) return;

    // 通知が許可されなかったとき
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('通知が許可されていません'),
        content: const Text('設定アプリの「通知」から、ヨルノヒカリの通知を許可してください。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursingReminderScope.of(context);
    final settings = controller.settings;
    final next = controller.nextReminderAt;

    final String value;
    if (!settings.enabled) {
      value = 'オフ';
    } else if (next != null) {
      value = '${hm(next)} に通知'; // 予約できているときは、次の時刻を見せる
    } else {
      value = '${formatSpan(settings.interval)}後';
    }

    return InsetTile(
      title: '授乳のお知らせ',
      value: value,
      onTap: () => _open(context, controller),
    );
  }
}

// ============================================================
//  2. 設定シート（オン/オフと間隔）
// ============================================================

/// 授乳のお知らせの、オン/オフと間隔（時間 + 分）を設定するシートを出す。
/// 「保存」なら設定、閉じたら null を返す。
Future<NursingReminderSettings?> showReminderSettingsSheet(
  BuildContext context, {
  required NursingReminderSettings initial,
}) {
  return showCupertinoModalPopup<NursingReminderSettings>(
    context: context,
    builder: (_) => _ReminderSettingsSheet(initial: initial),
  );
}

class _ReminderSettingsSheet extends StatefulWidget {
  const _ReminderSettingsSheet({required this.initial});

  final NursingReminderSettings initial;

  @override
  State<_ReminderSettingsSheet> createState() => _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState extends State<_ReminderSettingsSheet> {
  static const _maxHours = 12;
  static const _minuteStep = 5;

  late bool _enabled = widget.initial.enabled;

  // ドラムを回すたびに全体を再描画しないよう、値は ValueNotifier に持たせる
  late final _hours = ValueNotifier<int>(
    widget.initial.interval.inHours.clamp(0, _maxHours),
  );
  late final _minutes = ValueNotifier<int>(
    (((widget.initial.interval.inMinutes % 60) / _minuteStep).round() *
            _minuteStep)
        .clamp(0, 55),
  );

  late final _hourWheel = FixedExtentScrollController(
    initialItem: _hours.value,
  );
  late final _minuteWheel = FixedExtentScrollController(
    initialItem: _minutes.value ~/ _minuteStep,
  );

  /// 選んだ間隔（最小より短くならないようにする）
  Duration get _interval {
    final d = Duration(hours: _hours.value, minutes: _minutes.value);
    return d < NursingReminderSettings.minInterval
        ? NursingReminderSettings.minInterval
        : d;
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    _hourWheel.dispose();
    _minuteWheel.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(
    context,
  ).pop(NursingReminderSettings(enabled: _enabled, interval: _interval));

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Material(
      color: p.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ヘッダー: キャンセル / タイトル / 保存
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'キャンセル',
                      style: TextStyle(color: p.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '授乳のお知らせ',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _save,
                    child: const Text(
                      '保存',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),

              // オン / オフ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'お知らせする',
                        style: TextStyle(fontSize: 16, color: p.textPrimary),
                      ),
                    ),
                    CupertinoSwitch(
                      value: _enabled,
                      activeTrackColor: p.accent,
                      onChanged: (value) => setState(() => _enabled = value),
                    ),
                  ],
                ),
              ),

              // 間隔（オフのときは薄くして、触れないようにする）
              Opacity(
                opacity: _enabled ? 1 : 0.35,
                child: IgnorePointer(
                  ignoring: !_enabled,
                  child: Row(
                    children: [
                      Expanded(
                        child: WheelPicker(
                          controller: _hourWheel,
                          itemCount: _maxHours + 1,
                          unit: '時間',
                          onSelected: (hours) => _hours.value = hours,
                        ),
                      ),
                      Expanded(
                        child: WheelPicker(
                          controller: _minuteWheel,
                          itemCount: 60 ~/ _minuteStep,
                          step: _minuteStep,
                          unit: '分',
                          onSelected: (minutes) => _minutes.value = minutes,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListenableBuilder(
                listenable: Listenable.merge([_hours, _minutes]),
                builder: (_, _) => Text(
                  '前回の授乳から${formatSpan(_interval)}後にお知らせします',
                  style: TextStyle(fontSize: 13, color: p.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
