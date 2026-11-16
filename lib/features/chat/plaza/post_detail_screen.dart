import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/message_input_bar.dart';
import 'plaza_repository.dart';
import 'post.dart';
import 'post_card.dart';

/// 1つの投稿と、そのコメントの一覧。下の入力欄からコメントできる。
class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.post,
    required this.repository,
  });

  final Post post;
  final PlazaRepository repository;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _input = TextEditingController();
  late final Stream<List<PostComment>> _comments = widget.repository
      .watchComments(widget.post.id);
  bool _isSending = false;

  bool get _isMine => widget.post.authorId == widget.repository.uid;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _input.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await widget.repository.addComment(postId: widget.post.id, text: text);
      _input.clear();
    } on PlazaNgContentException {
      if (mounted) _showError('この内容は投稿できません。言葉を見直して、もう一度お試しください。');
    } catch (e) {
      debugPrint('コメント送信エラー: $e');
      if (mounted) _showError('通信を確認して、もう一度お試しください。');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deletePost() async {
    final ok = await confirmDialog(
      context,
      message: 'この投稿を削除しますか？\nコメントも一緒に消えます。',
      destructive: true,
    );
    if (!ok) return;
    await widget.repository.deletePost(widget.post);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reportPost() async {
    final ok = await confirmDialog(
      context,
      message: 'この投稿を通報しますか？\n複数人から通報された投稿は自動的に非表示になります。',
    );
    if (ok) await widget.repository.reportPost(widget.post.id);
  }

  Future<void> _reportComment(PostComment comment) async {
    final ok = await confirmDialog(
      context,
      message: 'このコメントを通報しますか？\n複数人から通報されたコメントは自動的に非表示になります。',
    );
    if (ok) {
      await widget.repository.reportComment(
        postId: widget.post.id,
        commentId: comment.id,
      );
    }
  }

  void _showError(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('送信できませんでした'),
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
    final p = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('投稿')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<PostComment>>(
              stream: _comments,
              builder: (context, snapshot) {
                final comments = snapshot.data ?? const <PostComment>[];
                return ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  children: [
                    PostCard(
                      post: widget.post,
                      onDelete: _isMine ? _deletePost : null,
                      onReport: _isMine ? null : _reportPost,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
                      child: Text(
                        'コメント ${comments.length}',
                        style: TextStyle(fontSize: 13, color: p.textSecondary),
                      ),
                    ),
                    if (comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 8,
                        ),
                        child: Text(
                          'まだコメントはありません。気が向いたら、ひとことどうぞ。',
                          style: TextStyle(
                            fontSize: 14,
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                    for (final comment in comments)
                      _CommentTile(
                        comment: comment,
                        onReport: comment.authorId == widget.repository.uid
                            ? null
                            : () => _reportComment(comment),
                      ),
                  ],
                );
              },
            ),
          ),
          MessageInputBar(
            controller: _input,
            hint: 'コメントする',
            busy: _isSending,
            maxLength: PlazaRepository.maxCommentLength,
            onSend: _sendComment,
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, this.onReport});

  final PostComment comment;

  /// 自分以外のコメントのときだけ渡す。渡されると「…」ボタンが出る
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${anonymousName(comment.authorId)}  ${timeAgo(comment.createdAt)}',
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ),
                  if (onReport != null)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onReport,
                      child: Icon(
                        CupertinoIcons.ellipsis,
                        size: 16,
                        color: p.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment.text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
