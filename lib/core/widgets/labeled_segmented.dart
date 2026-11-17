import 'package:flutter/cupertino.dart';

class LabeledSegmented<T extends Object> extends StatelessWidget {
  const LabeledSegmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.dotColors,
  });

  final T value;
  final Map<T, String> options; // 値 → 表示名
  final ValueChanged<T> onChanged;

  /// 選択肢の左に小さい丸を添えたいときに指定する（例: 母乳=ピンク1つ、混合=ピンクと黄色の2つ）
  final Map<T, List<Color>>? dotColors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: value,
        children: {
          for (final e in options.entries)
            e.key: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final color in dotColors?[e.key] ?? const <Color>[])
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                        child: const SizedBox.square(dimension: 8),
                      ),
                    ),
                  Text(e.value),
                ],
              ),
            ),
        },
        onValueChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
