import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/select_chip.dart';
import '../../../core/widgets/wheel_picker.dart';
import '../domain/care_record.dart';
import '../domain/record_spec.dart';
import 'record_type_style.dart';

/// 種別ごとの詳細入力（選択・数値・メモ）を下から出す。
/// 「保存」なら入力結果、閉じたら null を返す。
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
