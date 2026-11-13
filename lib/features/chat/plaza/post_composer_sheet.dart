import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import 'category_chips.dart';
import 'plaza_repository.dart';
import 'post.dart';

/// 投稿の下書き（本文とカテゴリ）
class PostDraft {
  const PostDraft({required this.text, required this.category});
  final String text;
  final PostCategory category;
}

/// 投稿画面を下から出す。「投稿」なら下書き、閉じたら null を返す。
Future<PostDraft?> showPostComposer(
  BuildContext context, {
  required PostCategory initialCategory,
}) {
  return showCupertinoModalPopup<PostDraft>(
    context: context,
    builder: (_) => _PostComposerSheet(initialCategory: initialCategory),
  );
}

class _PostComposerSheet extends StatefulWidget {
  const _PostComposerSheet({required this.initialCategory});

  final PostCategory initialCategory;

  @override
  State<_PostComposerSheet> createState() => _PostComposerSheetState();
}

class _PostComposerSheetState extends State<_PostComposerSheet> {
  final _text = TextEditingController();
  late PostCategory _category = widget.initialCategory;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canPost => _text.text.trim().isNotEmpty;

  void _submit() => Navigator.of(
    context,
  ).pop(PostDraft(text: _text.text.trim(), category: _category));

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return AnimatedPadding(
      // キーボードの高さだけ、シートを持ち上げる
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: p.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー: キャンセル / タイトル / 投稿
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'キャンセル',
                        style: TextStyle(color: p.textSecondary),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'つぶやく',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    // 文字が入ったときだけ「投稿」が押せる（このボタンだけ再描画する）
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _text,
                      builder: (_, _, _) => CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _canPost ? _submit : null,
                        child: const Text(
                          '投稿',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // カテゴリの選択
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in PostCategory.values)
                      CategoryChip(
                        label: category.label,
                        color: category.color(p),
                        selected: _category == category,
                        onTap: () => setState(() => _category = category),
                        onSurface: true,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 本文
                CupertinoTextField(
                  controller: _text,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: PlazaRepository.maxPostLength,
                  placeholder: '今の気持ちを、ひとことどうぞ',
                  padding: const EdgeInsets.all(12),
                  style: TextStyle(fontSize: 16, color: p.textPrimary),
                  placeholderStyle: TextStyle(
                    fontSize: 16,
                    color: p.textSecondary,
                  ),
                  decoration: BoxDecoration(
                    color: p.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '誰からかは表示されません。返信は気にしなくて大丈夫です。',
                        style: TextStyle(fontSize: 12, color: p.textSecondary),
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _text,
                      builder: (_, value, _) => Text(
                        '${value.text.characters.length}/${PlazaRepository.maxPostLength}',
                        style: TextStyle(fontSize: 12, color: p.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
