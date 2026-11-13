import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/message_input_bar.dart';
import 'ai_chat_repository.dart';
import 'ai_message_bubble.dart';
import 'gemini_service.dart';

/// AI相談。広場とは違い、1対1の会話（チャット）形式。
class AiChatView extends StatefulWidget {
  const AiChatView({super.key});

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> {
  /// 回答の書き込みを間引く間隔（毎回書くと通信が多すぎるため）
  static const _writeInterval = Duration(milliseconds: 400);

  final _repository = AiChatRepository();
  final _gemini = GeminiService();
  final _input = TextEditingController();
  late final Stream<List<AiMessage>> _messages = _repository.watch();

  bool _isAnswering = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// 送信 → 履歴を取る → 質問を保存 → 空の回答を作る → 届いた分だけ書き換える
  Future<void> _send() async {
    final question = _input.text.trim();
    if (question.isEmpty || _isAnswering) return;

    _input.clear();
    setState(() => _isAnswering = true);
    try {
      final history = await _repository.loadRecentTurns(); // 今回の質問を含めない
      await _repository.addUserMessage(question);
      final reply = await _repository.addAiPlaceholder();
      await _streamAnswer(reply, question, history);
    } catch (e) {
      debugPrint('AI相談の送信エラー: $e');
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _isAnswering = false);
    }
  }

  Future<void> _streamAnswer(
    DocumentReference<Map<String, dynamic>>? reply,
    String question,
    List<AiTurn> history,
  ) async {
    var latest = '';
    var lastWrite = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      await for (final text in _gemini.reply(question, history: history)) {
        latest = text;
        if (DateTime.now().difference(lastWrite) > _writeInterval) {
          lastWrite = DateTime.now();
          await _repository.writeAiText(reply, text);
        }
      }
      await _repository.writeAiText(reply, latest); // 最後の分まで必ず書く
    } on GeminiFailure catch (failure) {
      await _writeFailure(reply, latest, failure.userMessage);
    } catch (e) {
      debugPrint('回答の取得エラー: $e');
      await _writeFailure(
        reply,
        latest,
        const GeminiFailure(GeminiFailureKind.unknown).userMessage,
      );
    }
  }

  /// 途中まで届いた回答があれば残し、なければお知らせを書く
  Future<void> _writeFailure(
    DocumentReference<Map<String, dynamic>>? reply,
    String partial,
    String message,
  ) {
    if (partial.isNotEmpty) {
      return _repository.writeAiText(reply, '$partial\n\n（途中で通信が途切れました）');
    }
    return _repository.writeAiError(reply, message);
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'AIによる回答です。体調や発育が気になるときは、小児科に相談してください。',
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AiMessage>>(
            stream: _messages,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('AI相談の取得エラー: ${snapshot.error}');
                return Center(
                  child: Text(
                    '読み込めませんでした',
                    style: TextStyle(color: p.textSecondary),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CupertinoActivityIndicator());
              }
              final messages = snapshot.data!;
              if (messages.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [
                    AiMessageBubble(
                      name: 'AI',
                      text: 'こんばんは。気になることを書いてください。',
                      time: null,
                      isMine: false,
                    ),
                  ],
                );
              }
              return ListView.builder(
                reverse: true, // 新しいものが下に来る
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final m = messages[i];
                  return AiMessageBubble(
                    name: m.isAi ? 'AI' : '自分',
                    text: m.text,
                    time: m.sentAt,
                    isMine: !m.isAi,
                    isError: m.isError,
                  );
                },
              );
            },
          ),
        ),
        MessageInputBar(
          controller: _input,
          hint: 'AIに相談する',
          busy: _isAnswering,
          onSend: _send,
        ),
      ],
    );
  }
}
