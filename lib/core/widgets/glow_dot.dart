import 'package:flutter/material.dart';

class GlowDot extends StatelessWidget {
  const GlowDot({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}
