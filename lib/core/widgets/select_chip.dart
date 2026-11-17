import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// 選択肢の1つ。選ばれると [color] で淡く塗られる（枠線なし）。
/// 面（surface色）の上に置く前提で、未選択は背景色で塗る。
class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final tint = color ?? p.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? tint.withValues(alpha: 0.25) : p.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? tint : p.textSecondary,
          ),
        ),
      ),
    );
  }
}
