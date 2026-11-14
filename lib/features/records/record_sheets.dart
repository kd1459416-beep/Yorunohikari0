import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/select_chip.dart';
import '../../core/widgets/wheel_picker.dart';
import '../map/presentation/nursing_detail_sheet.dart';
import 'record_models.dart';
import 'record_store.dart';
import 'record_widgets.dart';

// ============================================================
//  1. 種別ごとの詳細入力（選択・数値・メモ）
// ============================================================

/// 種別ごとの詳細入力を下から出す。「保存」なら入力結果、閉じたら null を返す。
Future<RecordDetail?> showRecordDetailSheet(
  BuildContext context, {
  required RecordType type,
  RecordDetail initial = const RecordDetail(),
}) {
  return showCupertinoModalPopup<RecordDetail>(
    context: context,
    builder: (_) => _RecordDetailSheet(type: type, initial: initial),
  );
}

class _RecordDetailSheet extends StatefulWidget {
  const _RecordDetailSheet({required this.type, required this.initial});

  final RecordType type;
  final RecordDetail initial;

  @override
  State<_RecordDetailSheet> createState() => _RecordDetailSheetState();
}

class _RecordDetailSheetState extends State<_RecordDetailSheet> {
  late final RecordSpec _spec = widget.type.spec ?? const RecordSpec();

  // 選んだ状態（グループ名 → 選択肢）。もう一度押すと外れる
  late final Map<String, String> _selected = {...widget.initial.attributes};

  // ドラムで選んでいる数値（回すたびに setState しないよう、普通の変数で持つ）
  late double _value = widget.initial.value ?? _spec.number?.initial ?? 0;

  late final _note = TextEditingController(text: widget.initial.note);
  late final _wheel = FixedExtentScrollController(
    initialItem: _spec.number?.indexOf(_value) ?? 0,
  );

  @override
  void dispose() {
    _note.dispose();
    _wheel.dispose();
    super.dispose();
  }

  void _toggle(String group, String option) {
    setState(() {
      if (_selected[group] == option) {
        _selected.remove(group);
      } else {
        _selected[group] = option;
      }
    });
  }

  void _save() {
    // 項目の並びを、入力画面の順にそろえる
    final attributes = {
      for (final group in _spec.groups)
        if (_selected[group.name] != null) group.name: _selected[group.name]!,
    };
    Navigator.of(context).pop(
      RecordDetail(
        value: _spec.number == null ? null : _value,
        attributes: attributes,
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final color = widget.type.color(p);
    final number = _spec.number;
    final label = TextStyle(fontSize: 13, color: p.textSecondary);

    return AnimatedPadding(
      // キーボードの高さだけ、シートを持ち上げる
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: p.surface,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー: キャンセル / 種別名 / 保存
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              widget.type.icon(color, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                widget.type.label,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: p.textPrimary,
                                ),
                              ),
                            ],
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

                  // 選ぶだけの項目（硬さ・量・様子など）
                  for (final group in _spec.groups) ...[
                    const SizedBox(height: 16),
                    Text(group.name, style: label),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in group.options)
                          SelectChip(
                            label: option,
                            color: color,
                            selected: _selected[group.name] == option,
                            onTap: () => _toggle(group.name, option),
                          ),
                      ],
                    ),
                  ],

                  // 数値（体温・離乳食の量）
                  if (number != null) ...[
                    const SizedBox(height: 16),
                    Text(number.label, style: label),
                    TextWheelPicker(
                      controller: _wheel,
                      labels: [
                        for (var i = 0; i < number.count; i++)
                          number.format(number.valueAt(i)),
                      ],
                      unit: number.unit,
                      height: 132,
                      onSelectedIndex: (index) =>
                          _value = number.valueAt(index),
                    ),
                  ],

                  // メモ
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _note,
                    placeholder: _spec.noteHint,
                    maxLength: 100,
                    minLines: 1,
                    maxLines: 3,
                    padding: const EdgeInsets.all(12),
                    style: TextStyle(fontSize: 15, color: p.textPrimary),
                    placeholderStyle: TextStyle(
                      fontSize: 15,
                      color: p.textSecondary,
                    ),
                    decoration: BoxDecoration(
                      color: p.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
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

// ============================================================
//  2. 時刻の入力（押し忘れの追加・時刻の変更）
// ============================================================

/// 時刻と所要時間
class RecordTiming {
  const RecordTiming({required this.endedAt, required this.duration});

  final DateTime endedAt;
  final Duration duration;
}

/// 「いつ終わったか」（と、時間を測る種別は所要時間）を選ぶシートを出す。
/// 「保存」なら選んだ値、閉じたら null。
Future<RecordTiming?> showRecordTimingSheet(
  BuildContext context, {
  required String title,
  required RecordType type,
  DateTime? initialEndedAt,
  Duration initialDuration = Duration.zero,
}) {
  return showCupertinoModalPopup<RecordTiming>(
    context: context,
    builder: (_) => _RecordTimingSheet(
      title: title,
      type: type,
      initialEndedAt: initialEndedAt,
      initialDuration: initialDuration,
    ),
  );
}

class _RecordTimingSheet extends StatefulWidget {
  const _RecordTimingSheet({
    required this.title,
    required this.type,
    required this.initialEndedAt,
    required this.initialDuration,
  });

  final String title;
  final RecordType type;
  final DateTime? initialEndedAt;
  final Duration initialDuration;

  @override
  State<_RecordTimingSheet> createState() => _RecordTimingSheetState();
}

class _RecordTimingSheetState extends State<_RecordTimingSheet> {
  static const _maxMinutes = 120;

  // 開いた時刻。これより未来は選べない
  final _now = DateTime.now();

  // ドラムを回すたびに再描画しないよう、普通の変数で持つ（保存時に読むだけ）
  late DateTime _endedAt = widget.initialEndedAt ?? _now;
  late int _minutes = widget.initialDuration.inMinutes.clamp(0, _maxMinutes);
  late final _wheel = FixedExtentScrollController(initialItem: _minutes);

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(
    RecordTiming(
      endedAt: _endedAt,
      duration: Duration(minutes: _minutes),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final label = TextStyle(fontSize: 13, color: p.textSecondary);

    return Material(
      color: p.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        widget.title,
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
              const SizedBox(height: 8),
              Text(widget.type.hasDuration ? '終わった時刻' : '時刻', style: label),
              SizedBox(
                height: 170,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  use24hFormat: true,
                  initialDateTime: _endedAt.isAfter(_now) ? _now : _endedAt,
                  maximumDate: _now,
                  onDateTimeChanged: (value) => _endedAt = value,
                ),
              ),
              if (widget.type.hasDuration) ...[
                const SizedBox(height: 8),
                Text('かかった時間（わからなければ 0 分）', style: label),
                WheelPicker(
                  controller: _wheel,
                  itemCount: _maxMinutes + 1,
                  unit: '分',
                  height: 110,
                  onSelected: (minutes) => _minutes = minutes,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  3. ボタンを押したときの流れ
// ============================================================

/// 保存済みの記録に、詳細（硬さ・量・メモなど）を足す・変える。
/// 種別に合った入力画面を出して、保存まで行う（授乳は、専用のシート）。
Future<void> editRecordDetail(
  BuildContext context,
  RecordRepository repository,
  CareRecord record,
) async {
  final id = record.id;
  if (id == null) return;

  if (record.type == RecordType.nursing) {
    final detail = await showNursingDetailSheet(context);
    if (detail != null) await repository.updateFields(id, {'detail': detail});
    return;
  }

  final input = await showRecordDetailSheet(
    context,
    type: record.type,
    initial: RecordDetail.fromRecord(record),
  );
  if (input != null)
    await repository.updateFields(id, input.toFields(record.type));
}

/// ボタンの種類に応じた記録の流れ。
///  - ミルク: 量の入力 → 授乳（ミルク）として保存
///  - 体温・病院: 入力 → 保存
///  - それ以外: 1タップで保存（あとから「詳細」で足せる）
Future<void> runQuickAction(
  BuildContext context, {
  required QuickAction action,
  required RecordRepository repository,
  required QuickRecordController quick,
}) async {
  switch (action) {
    case QuickAction.milk:
      final detail = await showNursingDetailSheet(
        context,
        startWithFormula: true,
      );
      if (detail == null) return;
      await repository.add(
        CareRecord(
          type: RecordType.nursing,
          endedAt: DateTime.now(),
          detail: detail,
        ),
      );

    case QuickAction.temperature || QuickAction.hospital:
      final input = await showRecordDetailSheet(context, type: action.type);
      if (input == null) return;
      await repository.add(
        CareRecord(
          type: action.type,
          endedAt: DateTime.now(),
          detail: input.summary(action.type),
          value: input.value,
          attributes: input.attributes,
          note: input.note,
        ),
      );

    default:
      await quick.record(action.type);
  }
}
