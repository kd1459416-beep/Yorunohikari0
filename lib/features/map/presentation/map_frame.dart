import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../care_session_controller.dart';

// ============================================================
//  地図のフチから内側へ滲み出る光の調整（線の芯はなし）
//  反映されないときは、ターミナルで大文字の R（ホットリスタート）
// ============================================================
abstract final class MapFrameStyle {
  /// 光の位置。地図の外周から「内側へ」何pt離すか（左, 上, 右, 下）。
  /// 大きくすると小さく、マイナスにすると外側へ広がる。
  static const margin = EdgeInsets.fromLTRB(1, 1, 1, 1);

  /// 角の丸み（地図の角・光の角に合わせて調整）
  static const radius = 6.0;

  /// 光が内側へ届く深さ（大きいほど、中まで広く滲む）
  static const glowDepth = 56.0;

  /// 縁での光の濃さ（0.0 〜 1.0）。最初の発光は 0.34 でした
  static const glowAlpha = 0.4;

  /// 縁より外側へ滲み出す幅。0 にすると縁で光が急に切れて、線に見える
  static const outerSpill = 8.0;

  /// ゆっくり明滅させるか
  static const breathe = true;
  static const breathDuration = Duration(milliseconds: 3200);

  /// 出入りのフェード時間
  static const fade = Duration(milliseconds: 500);

  /// 授乳時の光の色（あたたかい黄色・ゴールド）
  static Color nursing(bool dark) => dark
      ? const Color.fromARGB(255, 248, 223, 143)
      : const Color.fromARGB(255, 234, 212, 161);

  /// 寝かしつけ時の光の色（静かな青紫色）
  static Color sleeping(bool dark) => dark
      ? const Color.fromARGB(255, 134, 150, 242)
      : const Color.fromARGB(255, 118, 135, 228);
}

/// 地図（[child]）のフチに、授乳/寝かしつけに応じた光を重ねる。
/// 地図の操作は妨げない。
class MapFrame extends StatefulWidget {
  const MapFrame({super.key, required this.status, required this.child});

  final CareStatus status;
  final Widget child;

  @override
  State<MapFrame> createState() => _MapFrameState();
}

class _MapFrameState extends State<MapFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: MapFrameStyle.breathDuration,
  );

  // 光の明るさ（70%〜100%）。形は描き直さず、透明度だけを動かす
  late final Animation<double> _brightness = MapFrameStyle.breathe
      ? Tween<double>(
          begin: 0.7,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)).animate(_breath)
      : const AlwaysStoppedAnimation<double>(1.0);

  // フェードアウト中も色が変わらないよう、最後の種類を覚えておく
  CareStatus _shown = CareStatus.nursing;

  bool get _active => widget.status != CareStatus.none;

  @override
  void initState() {
    super.initState();
    if (_active) {
      _shown = widget.status;
      if (MapFrameStyle.breathe) _breath.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MapFrame old) {
    super.didUpdateWidget(old);
    if (_active) _shown = widget.status;
    final wasActive = old.status != CareStatus.none;
    if (_active && !wasActive && MapFrameStyle.breathe) {
      _breath.repeat(reverse: true);
    } else if (!_active && wasActive) {
      _breath.stop();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = _shown == CareStatus.nursing
        ? MapFrameStyle.nursing(dark)
        : MapFrameStyle.sleeping(dark);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _active ? 1 : 0,
              duration: MapFrameStyle.fade,
              curve: Curves.easeInOut,
              child: FadeTransition(
                opacity: _brightness,
                child: RepaintBoundary(
                  child: CustomPaint(painter: _EdgeGlowPainter(color: color)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 四角の縁から内側へ薄れていく光を描く（線の芯はなし）。
/// 四辺は直線のグラデーション、四隅は丸みに沿った放射状のグラデーション。
class _EdgeGlowPainter extends CustomPainter {
  const _EdgeGlowPainter({required this.color});

  final Color color;

  static const _samples = 14; // グラデーションの滑らかさ

  /// 縁からの距離 u（内側が正、外側が負）での光の濃さ
  static double _alpha(double u) {
    const o = MapFrameStyle.outerSpill;
    const t = MapFrameStyle.glowDepth;
    const peak = MapFrameStyle.glowAlpha;
    if (u <= -o || u >= t) return 0;
    if (u < 0) {
      // 外側: 0 からなめらかに立ち上がる（縁で硬い線にならない）
      final x = (u + o) / o;
      return peak * x * x * (3 - 2 * x);
    }
    // 内側: 縁が一番明るく、なだらかに薄れる
    final x = 1 - u / t;
    return peak * x * x;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const m = MapFrameStyle.margin;
    final rect = Rect.fromLTRB(
      m.left,
      m.top,
      size.width - m.right,
      size.height - m.bottom,
    );
    if (rect.width <= 0 || rect.height <= 0) return;

    const o = MapFrameStyle.outerSpill;
    const t = MapFrameStyle.glowDepth;
    final r = math.max(
      1.0,
      math.min(MapFrameStyle.radius, rect.shortestSide / 2),
    );

    // --- 四辺用: 外側(-o) → 内側(t) の濃さを並べる ---
    final linColors = <Color>[];
    final linStops = <double>[];
    for (var i = 0; i <= _samples; i++) {
      final k = i / _samples;
      linColors.add(color.withValues(alpha: _alpha(-o + (o + t) * k)));
      linStops.add(k);
    }

    // --- 四隅用: 角の円の中心から外へ向かう濃さ ---
    final uMax = math.min(t, r);
    final cornerR = r + o;
    final cornerColors = <Color>[];
    final cornerStops = <double>[];
    if (t < r) {
      cornerColors.add(color.withValues(alpha: 0));
      cornerStops.add(0);
    }
    for (var i = 0; i <= _samples; i++) {
      final k = i / _samples;
      final u = uMax - (uMax + o) * k; // uMax → -o
      cornerColors.add(color.withValues(alpha: _alpha(u)));
      cornerStops.add((r - u) / cornerR);
    }

    void fill(Rect area, Gradient g) {
      if (area.width <= 0 || area.height <= 0) return;
      canvas.drawRect(area, Paint()..shader = g.createShader(area));
    }

    LinearGradient edge(Alignment from, Alignment to) => LinearGradient(
      begin: from,
      end: to,
      colors: linColors,
      stops: linStops,
    );

    RadialGradient corner(Alignment center) => RadialGradient(
      center: center,
      radius: 1.0, // 四隅の正方形（辺 = r + o）の一辺ぶん
      colors: cornerColors,
      stops: cornerStops,
    );

    final l = rect.left, tp = rect.top, rt = rect.right, b = rect.bottom;

    // 四辺
    fill(
      Rect.fromLTRB(l + r, tp - o, rt - r, tp + t),
      edge(Alignment.topCenter, Alignment.bottomCenter),
    );
    fill(
      Rect.fromLTRB(l + r, b - t, rt - r, b + o),
      edge(Alignment.bottomCenter, Alignment.topCenter),
    );
    fill(
      Rect.fromLTRB(l - o, tp + r, l + t, b - r),
      edge(Alignment.centerLeft, Alignment.centerRight),
    );
    fill(
      Rect.fromLTRB(rt - t, tp + r, rt + o, b - r),
      edge(Alignment.centerRight, Alignment.centerLeft),
    );

    // 四隅（角の丸みに沿う）
    fill(
      Rect.fromLTRB(l - o, tp - o, l + r, tp + r),
      corner(Alignment.bottomRight),
    );
    fill(
      Rect.fromLTRB(rt - r, tp - o, rt + o, tp + r),
      corner(Alignment.bottomLeft),
    );
    fill(Rect.fromLTRB(l - o, b - r, l + r, b + o), corner(Alignment.topRight));
    fill(
      Rect.fromLTRB(rt - r, b - r, rt + o, b + o),
      corner(Alignment.topLeft),
    );
  }

  @override
  bool shouldRepaint(_EdgeGlowPainter old) => old.color != color;
}
