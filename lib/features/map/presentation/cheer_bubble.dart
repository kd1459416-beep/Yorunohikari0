import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../domain/cheer.dart';

/// 灯りの真上に出るすりガラス風の吹き出し。
/// 出現: 矢印の先を起点に、フェード + 拡大。
/// 送信: 淡く発光 → 縮みながら消える。
class CheerBubble extends StatefulWidget {
  const CheerBubble({
    super.key,
    required this.canSend,
    required this.onPicked,
    required this.onDismissed,
  });

  /// false のときは、スタンプの代わりに「送信済み」を表示する
  final bool canSend;

  /// スタンプをタップした瞬間に呼ぶ（送信処理）
  final ValueChanged<CheerKind> onPicked;

  /// 消えるアニメーションが終わったあとに呼ぶ（吹き出しを閉じる）
  final VoidCallback onDismissed;

  // Marker の大きさと一致させるための寸法
  static const width = 232.0;
  static const _bodyHeight = 62.0;
  static const _arrowHeight = 8.0;
  static const _gap = 10.0; // 灯りとの隙間
  static const height = _bodyHeight + _arrowHeight + _gap;

  @override
  State<CheerBubble> createState() => _CheerBubbleState();
}

class _CheerBubbleState extends State<CheerBubble>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _exit;
  CheerKind? _picked;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..forward();
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
  }

  @override
  void dispose() {
    _enter.dispose();
    _exit.dispose();
    super.dispose();
  }

  Future<void> _pick(CheerKind kind) async {
    if (_picked != null) return; // 二度押し防止
    setState(() => _picked = kind);
    widget.onPicked(kind); // 送信は即座に開始する
    await _exit.forward();
    if (mounted) widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_enter, _exit]),
      builder: (context, _) {
        // ---- 出現 ----
        final fadeIn = Curves.easeOut.transform(_enter.value);
        final scaleIn = lerpDouble(
          0.6,
          1.0,
          Curves.easeOutBack.transform(_enter.value),
        )!;

        // ---- 送信後 ----
        final t = _exit.value;
        final glow = sin(pi * (t / 0.7).clamp(0.0, 1.0)); // 0→1→0（前半で光る）
        final shrink = Curves.easeIn.transform(
          ((t - 0.4) / 0.6).clamp(0.0, 1.0),
        );

        final scale = scaleIn * (1 - 0.7 * shrink);
        final opacity = fadeIn * (1 - shrink);

        // ガラスの色。発光中は金色を重ねる
        final base = p.surface.withValues(alpha: 0.72 * opacity);
        final tint = Color.alphaBlend(
          p.accent.withValues(alpha: 0.40 * glow),
          base,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: CheerBubble._gap),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.bottomCenter, // 矢印の先（=灯り）を起点に拡大縮小
            child: ClipPath(
              clipper: const _BubbleClipper(
                arrow: CheerBubble._arrowHeight,
                radius: 18,
              ),
              child: BackdropFilter(
                // Opacity で包むと背景のぼかしが消えるため、ぼかしの強さ自体で薄くする
                filter: ImageFilter.blur(
                  sigmaX: 18 * opacity,
                  sigmaY: 18 * opacity,
                ),
                child: ColoredBox(
                  color: tint,
                  child: Column(
                    children: [
                      SizedBox(
                        height: CheerBubble._bodyHeight,
                        child: Opacity(opacity: opacity, child: _content(p)),
                      ),
                      const SizedBox(height: CheerBubble._arrowHeight),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _content(AppPalette p) {
    if (_picked == null && !widget.canSend) {
      return Center(
        child: Text(
          'さきほど送りました',
          style: TextStyle(fontSize: 13, color: p.textSecondary),
        ),
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            for (final kind in CheerKind.values)
              Expanded(
                child: _Stamp(
                  kind: kind,
                  chosen: _picked == kind,
                  dimmed: _picked != null && _picked != kind,
                  onTap: () => _pick(kind),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.kind,
    required this.chosen,
    required this.dimmed,
    required this.onTap,
  });

  final CheerKind kind;
  final bool chosen; // 選んだスタンプは少し大きくする
  final bool dimmed; // 選ばなかったスタンプは薄くする
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: dimmed ? 0.3 : 1,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          scale: chosen ? 1.25 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                kind.emoji,
                style: const TextStyle(fontSize: 24, height: 1.1),
              ),
              const SizedBox(height: 4),
              Text(
                kind.label,
                style: TextStyle(fontSize: 10, color: p.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 角丸の四角 + 下向きの小さな三角（吹き出しの矢印）を1つの形にする
class _BubbleClipper extends CustomClipper<Path> {
  const _BubbleClipper({required this.arrow, required this.radius});

  final double arrow;
  final double radius;

  @override
  Path getClip(Size size) {
    final bodyBottom = size.height - arrow;
    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, bodyBottom),
          Radius.circular(radius),
        ),
      );

    final cx = size.width / 2;
    final tip = Path()
      ..moveTo(cx - 8, bodyBottom - 0.5) // 0.5 は継ぎ目が見えないための重なり
      ..lineTo(cx, size.height)
      ..lineTo(cx + 8, bodyBottom - 0.5)
      ..close();

    return Path.combine(PathOperation.union, body, tip);
  }

  @override
  bool shouldReclip(_BubbleClipper old) =>
      old.arrow != arrow || old.radius != radius;
}
