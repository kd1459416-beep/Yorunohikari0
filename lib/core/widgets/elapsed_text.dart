import 'package:flutter/material.dart';
import '../utils/time_format.dart';

/// 経過時間の表示。例: 「2 時間 38 分前」（数字は大きく、単位は小さく）
class ElapsedText extends StatelessWidget {
  const ElapsedText({
    super.key,
    required this.elapsed,
    required this.color,
    this.numberSize = 32,
    this.unitSize = 16,
  });

  final ElapsedTime elapsed;
  final Color color;
  final double numberSize; // 数字の大きさ
  final double unitSize; // 「時間」「分前」の大きさ

  @override
  Widget build(BuildContext context) {
    final numberStyle = TextStyle(
      fontSize: numberSize,
      fontWeight: FontWeight.w700,
      height: 1.1,
      color: color,
    );
    final unitStyle = TextStyle(
      fontSize: unitSize,
      fontWeight: FontWeight.w600,
      color: color,
    );

    return FittedBox(
      fit: BoxFit.scaleDown, // 幅が足りないときだけ縮める
      alignment: Alignment.centerLeft,
      child: elapsed.isJustNow
          ? Text(
              'たった今',
              style: numberStyle.copyWith(fontSize: numberSize * 0.75),
            )
          : Text.rich(
              TextSpan(
                children: [
                  for (final (number, unit) in elapsed.segments) ...[
                    TextSpan(text: number, style: numberStyle),
                    TextSpan(text: unit, style: unitStyle),
                  ],
                ],
              ),
            ),
    );
  }
}
