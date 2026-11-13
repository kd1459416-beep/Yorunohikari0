import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import 'post.dart';

/// カテゴリごとの色
extension PostCategoryColor on PostCategory {
  Color color(AppPalette p) => switch (this) {
    PostCategory.nursing => p.nursing,
    PostCategory.sleeping => p.sleeping,
    PostCategory.chatting => p.textPrimary.withValues(alpha: 0.75),
    PostCategory.weaning => const Color(0xFF5FBF8F),
    PostCategory.pregnancy => const Color(0xFFE98FB0),
    PostCategory.checkup => p.glow,
  };
}

/// 1つの選択肢。選ばれると、そのカテゴリの色で淡く塗られる（枠線なし）
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.onSurface = false,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  /// カード（surface色）の上に置くときは true（未選択の背景色を変える）
  final bool onSurface;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.22)
              : (onSurface ? p.background : p.surface),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? color : p.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// タイムライン上部の、横にスクロールするカテゴリ切り替え。
/// 「すべて」を選ぶと [onSelected] に null が渡る。
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PostCategory? selected;
  final ValueChanged<PostCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          CategoryChip(
            label: 'すべて',
            color: p.accent,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final category in PostCategory.values) ...[
            const SizedBox(width: 8),
            CategoryChip(
              label: category.label,
              color: category.color(p),
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }
}
