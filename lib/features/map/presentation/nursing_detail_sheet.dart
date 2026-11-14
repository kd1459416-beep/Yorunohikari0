import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/labeled_segmented.dart';

/// 保存したら詳細文字列を返す。閉じたら null（計測は続く）。
Future<String?> showNursingDetailSheet(
  BuildContext context, {
  bool startWithFormula = false,
}) {
  return showCupertinoModalPopup<String>(
    context: context,
    builder: (_) => _NursingDetailSheet(startWithFormula: startWithFormula),
  );
}

enum _FeedType {
  breast('母乳'),
  formula('ミルク'),
  mixed('混合');

  const _FeedType(this.label);
  final String label;

  bool get hasBreast => this != formula;
  bool get hasFormula => this != breast;
}

const _sides = ['両方', '左のみ', '右のみ'];
const _memos = ['寝落ち', '完飲', 'よく飲んだ', '吐き戻しなし'];

// ---- ミルク量の範囲（ここを変えれば選択肢が変わる） ----
const _mlMin = 30;
const _mlMax = 250;
const _mlStep = 10;
const _mlInitial = 100;
const _mlCount = (_mlMax - _mlMin) ~/ _mlStep + 1; // 23個（30, 40, … 250）

int _indexOf(int ml) =>
    ((ml - _mlMin) / _mlStep).round().clamp(0, _mlCount - 1);

class _NursingDetailSheet extends StatefulWidget {
  const _NursingDetailSheet({required this.startWithFormula});
  final bool startWithFormula;

  @override
  State<_NursingDetailSheet> createState() => _NursingDetailSheetState();
}

class _NursingDetailSheetState extends State<_NursingDetailSheet> {
  late _FeedType _type = widget.startWithFormula
      ? _FeedType.formula
      : _FeedType.breast;
  String _side = _sides.first;
  int _ml = _mlInitial;
  String? _memo;

  /// 例: "混合 (両方 / 80ml) • 完飲"（グラフが `80ml` を読むので形式は変えない）
  String get _detail {
    final body = switch (_type) {
      _FeedType.breast => '母乳 ($_side)',
      _FeedType.formula => 'ミルク (${_ml}ml)',
      _FeedType.mixed => '混合 ($_side / ${_ml}ml)',
    };
    return _memo == null ? body : '$body • $_memo';
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final label = TextStyle(fontSize: 13, color: p.textSecondary);

    return Material(
      color: p.surface,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          // 小さい画面でも、はみ出さずスクロールできるようにする
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    '授乳の記録',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                LabeledSegmented<_FeedType>(
                  value: _type,
                  options: {for (final t in _FeedType.values) t: t.label},
                  onChanged: (t) => setState(() => _type = t),
                ),
                if (_type.hasBreast) ...[
                  const SizedBox(height: 20),
                  Text('おっぱい', style: label),
                  const SizedBox(height: 8),
                  LabeledSegmented<String>(
                    value: _side,
                    options: {for (final s in _sides) s: s},
                    onChanged: (s) => setState(() => _side = s),
                  ),
                ],
                if (_type.hasFormula) ...[
                  const SizedBox(height: 20),
                  Text('ミルクの量', style: label),
                  const SizedBox(height: 4),
                  // 保存時に読むだけなので setState は不要（再描画でピッカーが動かないように）
                  _MlPicker(value: _ml, onChanged: (v) => _ml = v),
                ],
                const SizedBox(height: 20),
                Text('メモ', style: label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in _memos)
                      _Tag(
                        label: m,
                        selected: _memo == m,
                        onTap: () =>
                            setState(() => _memo = _memo == m ? null : m),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: p.accent,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => Navigator.of(context).pop(_detail),
                    child: const Text(
                      '保存',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// iOS風のドラムロール。上下にスワイプして 30〜250ml を10ml刻みで選ぶ。
class _MlPicker extends StatefulWidget {
  const _MlPicker({required this.value, required this.onChanged});

  final int value; // 最初に合わせる位置
  final ValueChanged<int> onChanged;

  @override
  State<_MlPicker> createState() => _MlPickerState();
}

class _MlPickerState extends State<_MlPicker> {
  // 表示されるたびに、現在の値の位置から始める
  late final _controller = FixedExtentScrollController(
    initialItem: _indexOf(widget.value),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final number = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: p.textPrimary,
    );
    final unit = TextStyle(fontSize: 15, color: p.textSecondary);

    return SizedBox(
      height: 132,
      child: CupertinoPicker(
        scrollController: _controller,
        itemExtent: 38, // 1行の高さ
        useMagnifier: true,
        magnification: 1.08,
        // 中央の選択帯。枠線ではなく、淡い塗りだけ
        selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
          background: p.accent.withValues(alpha: 0.14),
        ),
        onSelectedItemChanged: (i) {
          HapticFeedback.selectionClick(); // 目盛りを越えるたびに軽いクリック
          widget.onChanged(_mlMin + i * _mlStep);
        },
        children: [
          for (var i = 0; i < _mlCount; i++)
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${_mlMin + i * _mlStep}', style: number),
                    TextSpan(text: ' ml', style: unit),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 背景色の濃淡だけで選択状態を示す（枠線なし）
class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? p.accent.withValues(alpha: 0.25) : p.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? p.accent : p.textSecondary,
          ),
        ),
      ),
    );
  }
}
