import 'package:flutter/cupertino.dart';

class LabeledSegmented<T extends Object> extends StatelessWidget {
  const LabeledSegmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options; // 値 → 表示名
  final ValueChanged<T> onChanged;

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
              child: Text(e.value),
            ),
        },
        onValueChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
