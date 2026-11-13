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
    } catch (e) {
      debugPrint('コメント送信エラー: $e');
      if (mounted) _showError();
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

  void _showError() {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('送信できませんでした'),
        content: const Text('通信を確認して、もう一度お試しください。'),
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
                      _CommentTile(comment: comment),
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
  const _CommentTile({required this.comment});

  final PostComment comment;

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
              Text(
                '${anonymousName(comment.authorId)}  ${timeAgo(comment.createdAt)}',
                style: TextStyle(fontSize: 12, color: p.textSecondary),
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
