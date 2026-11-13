import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/care_icons.dart';
import '../domain/care_record.dart';

/// 種別ごとの色とアイコン。表示まわりの対応は、ここだけで管理する。
extension RecordTypeStyle on RecordType {
  Color color(AppPalette p) => switch (this) {
    RecordType.nursing => p.nursing,
    RecordType.sleep => p.sleeping,
    RecordType.pee => const Color(0xFF38BDF8),
    RecordType.poop => const Color(0xFFC98A4B),
    RecordType.babyFood => const Color(0xFF4CAF82),
    RecordType.temperature => const Color(0xFFE5739A),
    RecordType.hospital => const Color(0xFFE5736E),
    RecordType.bath => const Color(0xFF2BB5B5),
  };

  Widget icon(Color color, {double size = 24}) => switch (this) {
    RecordType.nursing => BottleIcon(size: size, color: color),
    RecordType.sleep => Icon(
      CupertinoIcons.moon_zzz_fill,
      size: size,
      color: color,
    ),
    RecordType.pee => Icon(CupertinoIcons.drop_fill, size: size, color: color),
    RecordType.poop => PoopIcon(size: size, color: color),
    RecordType.babyFood => Icon(
      Icons.rice_bowl_rounded,
      size: size,
      color: color,
    ),
    RecordType.temperature => Icon(
      CupertinoIcons.thermometer,
      size: size,
      color: color,
    ),
    RecordType.hospital => Icon(
      Icons.local_hospital_rounded,
      size: size,
      color: color,
    ),
    RecordType.bath => Icon(Icons.bathtub_rounded, size: size, color: color),
  };
}

/// うんちのアイコン（3段に重なった形）
class PoopIcon extends StatelessWidget {
  const PoopIcon({super.key, required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _PoopPainter(color)),
  );
}

class _PoopPainter extends CustomPainter {
  const _PoopPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24); // 24x24 の座標で描く
    final paint = Paint()..color = color;

    // 下の段 → 真ん中 → 上の段 → てっぺんのとがり
    for (final (rect, radius) in const [
      (Rect.fromLTRB(3, 15.6, 21, 21.5), 3.0),
      (Rect.fromLTRB(5.5, 10.6, 18.5, 15.0), 2.6),
      (Rect.fromLTRB(8.5, 6.2, 15.5, 10.0), 2.3),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        paint,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(12, 1.8)
        ..quadraticBezierTo(14.8, 3.0, 13.4, 5.6)
        ..lineTo(10.6, 5.6)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_PoopPainter old) => old.color != color;
}
