import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import 'post.dart';

/// カテゴリごとの色
extension PostCategoryColor on PostCategory {
  Color color(AppPalette p) => switch (this) {
    PostCategory.nursing => p.nursing,
    PostCategory.sleeping => p.sleeping,
    PostCategory.chatting => const Color(0xFFF2A65A),
    PostCategory.weaning => const Color(0xFF5FBF8F),
    PostCategory.pregnancy => const Color(0xFFE98FB0),
    PostCategory.checkup => p.glow,
  };
}

/// 「すべて」はどのカテゴリの色とも被らない、ニュートラルな色にする
const _allColor = Color(0xFFB0B4C3);

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
/// スワイプなどで選択が変わったときは、そのピルが見える位置まで自動でスクロールする。
class CategoryChips extends StatefulWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PostCategory? selected;
  final ValueChanged<PostCategory?> onSelected;

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  final _keys = <PostCategory?, GlobalKey>{
    null: GlobalKey(),
    for (final category in PostCategory.values) category: GlobalKey(),
  };

  @override
  void didUpdateWidget(covariant CategoryChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _scrollToSelected();
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _keys[widget.selected]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          KeyedSubtree(
            key: _keys[null],
            child: CategoryChip(
              label: 'すべて',
              color: _allColor,
              selected: widget.selected == null,
              onTap: () => widget.onSelected(null),
            ),
          ),
          for (final category in PostCategory.values) ...[
            const SizedBox(width: 8),
            KeyedSubtree(
              key: _keys[category],
              child: CategoryChip(
                label: category.label,
                color: category.color(p),
                selected: widget.selected == category,
                onTap: () => widget.onSelected(category),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
