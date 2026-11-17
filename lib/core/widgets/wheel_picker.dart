import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../theme/app_palette.dart';

/// 数字 + 単位のドラムロール（整数）。
/// 表示する数字は `firstValue + 行の番号 * step`。
class WheelPicker extends StatelessWidget {
  const WheelPicker({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.unit,
    required this.onSelected,
    this.firstValue = 0,
    this.step = 1,
    this.height = 150,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final String unit;

  /// 選ばれた「数字」（行の番号ではない）を受け取る
  final ValueChanged<int> onSelected;

  final int firstValue;
  final int step;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TextWheelPicker(
      controller: controller,
      labels: [for (var i = 0; i < itemCount; i++) '${firstValue + i * step}'],
      unit: unit,
      onSelectedIndex: (index) => onSelected(firstValue + index * step),
      height: height,
    );
  }
}

/// 好きな文字（「36.5」など）を並べるドラムロール。
/// 目盛りを越えるたびに、軽い触覚を返す。
class TextWheelPicker extends StatelessWidget {
  const TextWheelPicker({
    super.key,
    required this.controller,
    required this.labels,
    required this.unit,
    required this.onSelectedIndex,
    this.height = 150,
  });

  final FixedExtentScrollController controller;
  final List<String> labels;
  final String unit;

  /// 選ばれた行の番号
  final ValueChanged<int> onSelectedIndex;

  final double height;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final labelStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: p.textPrimary,
    );
    final unitStyle = TextStyle(fontSize: 15, color: p.textSecondary);

    return SizedBox(
      height: height,
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 38, // 1行の高さ
        useMagnifier: true,
        magnification: 1.08,
        // 中央の選択帯。枠線ではなく、淡い塗りだけ
        selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
          background: p.accent.withValues(alpha: 0.14),
        ),
        onSelectedItemChanged: (index) {
          HapticFeedback.selectionClick();
          onSelectedIndex(index);
        },
        children: [
          for (final label in labels)
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: label, style: labelStyle),
                    TextSpan(text: ' $unit', style: unitStyle),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
