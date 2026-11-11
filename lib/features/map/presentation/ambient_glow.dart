import 'package:flutter/material.dart';

class AmbientGlow extends StatefulWidget {
  const AmbientGlow({super.key, required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  State<AmbientGlow> createState() => _AmbientGlowState();
}

class _AmbientGlowState extends State<AmbientGlow>
    with SingleTickerProviderStateMixin {
  static const _thickness = 140.0; // 光が内側へ広がる幅

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _breath.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AmbientGlow old) {
    super.didUpdateWidget(old);
    if (widget.active == old.active) return;
    widget.active ? _breath.repeat(reverse: true) : _breath.stop();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  Positioned _edge({
    required Alignment begin,
    required Alignment end,
    required double k,
    double? top,
    double? bottom,
    double? left,
    double? right,
    double? width,
    double? height,
  }) {
    final c = widget.color;
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: [
              c.withValues(alpha: 0.34 * k),
              c.withValues(alpha: 0.10 * k),
              c.withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1], // 端が濃く、内側へなめらかに消える
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: widget.active ? 1 : 0, // 授乳の開始・終了でゆっくり出入りする
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        child: AnimatedBuilder(
          animation: _breath,
          builder: (context, _) {
            final k =
                0.7 +
                0.3 * Curves.easeInOut.transform(_breath.value); // 70%〜100%
            return Stack(
              children: [
                _edge(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  k: k,
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _thickness,
                ),
                _edge(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  k: k,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: _thickness,
                ),
                _edge(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  k: k,
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: _thickness,
                ),
                _edge(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  k: k,
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: _thickness,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
