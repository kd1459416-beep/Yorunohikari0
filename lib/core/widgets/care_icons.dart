import 'package:flutter/cupertino.dart';

/// 哺乳瓶（乳首・キャップ・目盛り付きの本体）
class BottleIcon extends StatelessWidget {
  const BottleIcon({super.key, this.size = 24, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _BottlePainter(color)),
    );
  }
}

class _BottlePainter extends CustomPainter {
  const _BottlePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24); // 24x24 の座標で描く
    final paint = Paint()..color = color;

    // 乳首
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(10.2, 1.2, 13.8, 5.4),
        const Radius.circular(1.8),
      ),
      paint,
    );
    // キャップ（リング）
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(7.5, 5, 16.5, 8),
        const Radius.circular(1.2),
      ),
      paint,
    );
    // 本体 − 目盛り（3本を切り抜く）
    var body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(6, 8.5, 18, 22.5),
          const Radius.circular(3),
        ),
      );
    for (final y in const [12.5, 15.5, 18.5]) {
      body = Path.combine(
        PathOperation.difference,
        body,
        Path()..addRect(Rect.fromLTWH(12, y, 4, 1.1)),
      );
    }
    canvas.drawPath(body, paint);
  }

  @override
  bool shouldRepaint(_BottlePainter old) => old.color != color;
}

/// 授乳＝哺乳瓶、寝かしつけ＝月とZZZ
class CareStatusIcon extends StatelessWidget {
  const CareStatusIcon({
    super.key,
    required this.isNursing,
    required this.color,
    this.size = 22,
  });

  final bool isNursing;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return isNursing
        ? BottleIcon(size: size, color: color)
        : Icon(CupertinoIcons.moon_zzz_fill, size: size, color: color);
  }
}
