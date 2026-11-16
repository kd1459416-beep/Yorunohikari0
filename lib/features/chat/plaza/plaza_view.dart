import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/confirm_dialog.dart';
import 'category_chips.dart';
import 'plaza_repository.dart';
import 'post.dart';
import 'post_card.dart';
import 'post_composer_sheet.dart';
import 'post_detail_screen.dart';

/// ママ広場。カテゴリで絞り込める投稿のタイムライン。
/// 会話を続ける必要はなく、ひとことつぶやくだけ。コメントは任意。
class PlazaView extends StatefulWidget {
  const PlazaView({super.key});

  @override
  State<PlazaView> createState() => _PlazaViewState();
}

class _PlazaViewState extends State<PlazaView> {
  final _repository = PlazaRepository();

  PostCategory? _filter; // null = すべて
  late final Stream<List<Post>> _posts = _repository.watchPosts();

  void _selectFilter(PostCategory? category) =>
      setState(() => _filter = category);

  Future<void> _compose() async {
    final draft = await showPostComposer(
      context,
      initialCategory: _filter ?? PostCategory.chatting,
    );
    if (draft == null) return;
    try {
      await _repository.addPost(text: draft.text, category: draft.category);
    } on PlazaNgContentException {
      if (mounted) _showError('この内容は投稿できません。言葉を見直して、もう一度お試しください。');
    } catch (e) {
      debugPrint('投稿エラー: $e');
      if (mounted) _showError('通信を確認して、もう一度お試しください。');
    }
  }

  Future<void> _delete(Post post) async {
    final ok = await confirmDialog(
      context,
      message: 'この投稿を削除しますか？',
      destructive: true,
    );
    if (ok) await _repository.deletePost(post);
  }

  Future<void> _report(Post post) async {
    final ok = await confirmDialog(
      context,
      message: 'この投稿を通報しますか？\n複数人から通報された投稿は自動的に非表示になります。',
    );
    if (ok) await _repository.reportPost(post.id);
  }

  void _openDetail(Post post) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => PostDetailScreen(post: post, repository: _repository),
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('投稿できませんでした'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 4),
            CategoryChips(selected: _filter, onSelected: _selectFilter),
            const SizedBox(height: 8),
            Expanded(
              child: _PostFeed(
                posts: _posts,
                category: _filter,
                myUid: _repository.uid,
                onOpen: _openDetail,
                onDelete: _delete,
                onReport: _report,
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: _ComposeButton(onPressed: _compose),
        ),
      ],
    );
  }
}

/// 投稿の一覧部分。[category] が null でなければ、そのカテゴリだけを出す
class _PostFeed extends StatelessWidget {
  const _PostFeed({
    required this.posts,
    required this.category,
    required this.myUid,
    required this.onOpen,
    required this.onDelete,
    required this.onReport,
  });

  final Stream<List<Post>> posts;
  final PostCategory? category;
  final String? myUid;
  final ValueChanged<Post> onOpen;
  final ValueChanged<Post> onDelete;
  final ValueChanged<Post> onReport;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return StreamBuilder<List<Post>>(
      stream: posts,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('投稿の取得エラー: ${snapshot.error}');
          return Center(
            child: Text('読み込めませんでした', style: TextStyle(color: p.textSecondary)),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }
        final list = snapshot.data!
            .where((post) => category == null || post.category == category)
            .toList();
        if (list.isEmpty) {
          return Center(
            child: Text(
              'まだ投稿がありません。\nひとことつぶやいてみませんか。',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textSecondary, height: 1.6),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 88), // 右下のボタンと重ならないように
          itemCount: list.length,
          itemBuilder: (_, i) {
            final post = list[i];
            final isMine = post.authorId == myUid;
            return PostCard(
              post: post,
              onTap: () => onOpen(post),
              onDelete: isMine ? () => onDelete(post) : null,
              onReport: isMine ? null : () => onReport(post),
            );
          },
        );
      },
    );
  }
}

/// 右下の「つぶやく」ボタン
class _ComposeButton extends StatelessWidget {
  const _ComposeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.square_pencil,
                size: 20,
                color: Colors.black87,
              ),
              SizedBox(width: 8),
              Text(
                'つぶやく',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
