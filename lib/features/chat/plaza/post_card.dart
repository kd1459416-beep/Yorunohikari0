import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/time_format.dart';
import 'category_chips.dart';
import 'post.dart';

/// タイムライン上の1枚の投稿カード。
/// [onTap] が null のとき（詳細画面）は、タップできない見た目にする。
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.onTap, this.onDelete});

  final Post post;
  final VoidCallback? onTap;

  /// 自分の投稿のときだけ渡す。渡されると「…」ボタンが出る
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final categoryColor = post.category.color(p);
    final meta = TextStyle(fontSize: 12, color: p.textSecondary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 上段: カテゴリ・投稿者・時間
                Row(
                  children: [
                    Text(
                      post.category.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(anonymousName(post.authorId), style: meta),
                    const SizedBox(width: 10),
                    Text(timeAgo(post.createdAt), style: meta),
                    const Spacer(),
                    if (onDelete != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onDelete,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            size: 20,
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // 本文
                Text(
                  post.text,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.55,
                    color: p.textPrimary,
                  ),
                ),

                // 下段: コメント数（コメントは任意なので、控えめに）
                if (onTap != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.chat_bubble,
                        size: 16,
                        color: p.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        post.commentCount == 0
                            ? 'コメントする'
                            : 'コメント ${post.commentCount}',
                        style: meta,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
