import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/widgets/glow_dot.dart';

/// 自分の灯り。[pulse] が動いている間だけ、ふわっと膨らんで広がる。
/// 音も振動も使わない。
class PulseGlowDot extends StatelessWidget {
  const PulseGlowDot({super.key, required this.color, required this.pulse});

  final Color color;
  final Animation<double> pulse; // 0 → 1（約1.8秒）

  static const _base = 8.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = pulse.value;
        final swell = sin(pi * t); // 0 → 1 → 0。膨らんで元に戻る
        final ringSize = _base + 64 * t; // 外側の光の輪が広がる
        final offset = -(ringSize - _base) / 2;

        return Stack(
          clipBehavior: Clip.none, // 8x8 の外側にも描画する
          children: [
            if (pulse.isAnimating)
              Positioned(
                left: offset,
                top: offset,
                width: ringSize,
                height: ringSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // 広がるにつれて透明になる（枠線ではなく塗りの光）
                    color: color.withValues(alpha: 0.30 * (1 - t)),
                  ),
                ),
              ),
            Positioned.fill(
              child: Transform.scale(
                scale: 1 + 0.9 * swell,
                child: GlowDot(color: color),
              ),
            ),
          ],
        );
      },
    );
  }
}
