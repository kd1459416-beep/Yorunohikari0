import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/labeled_segmented.dart';
import 'chat_repository.dart';
import 'gemini_service.dart';

enum _Mode { plaza, ai }

enum ChatRoom {
  nursing('授乳中'),
  sleeping('寝かしつけ'),
  chatting('雑談');

  const ChatRoom(this.label);
  final String label;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repo = ChatRepository();
  final _gemini = GeminiService();
  final _input = TextEditingController();

  _Mode _mode = _Mode.plaza;
  ChatRoom _room = ChatRoom.nursing;
  late Stream<List<ChatMessage>> _stream = _repo.watchRoom(_room.name);
  bool _aiBusy = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _selectMode(_Mode mode) => setState(() {
    _mode = mode;
    _stream = mode == _Mode.plaza
        ? _repo.watchRoom(_room.name)
        : _repo.watchAi();
  });

  void _selectRoom(ChatRoom room) => setState(() {
    _room = room;
    _stream = _repo.watchRoom(room.name);
  });

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _aiBusy) return;
    _input.clear();
    try {
      if (_mode == _Mode.plaza) {
        await _repo.sendToRoom(_room.name, text);
      } else {
        await _askAi(text);
      }
    } catch (e) {
      debugPrint('送信エラー: $e');
      if (mounted) _showError();
    }
  }

  /// 相談内容を保存 → 空の返信を作る → 届いた分だけ返信を書き換える
  Future<void> _askAi(String text) async {
    setState(() => _aiBusy = true);
    try {
      await _repo.addAiMessage(text, fromAi: false);
      final reply = await _repo.addAiMessage('…', fromAi: true);
      var latest = '';
      var lastWrite = DateTime.fromMillisecondsSinceEpoch(0);
      try {
        await for (final t in _gemini.reply(text)) {
          latest = t;
          // 書き込み回数を抑えるため、更新は0.4秒に1回まで
          if (DateTime.now().difference(lastWrite) >
              const Duration(milliseconds: 400)) {
            lastWrite = DateTime.now();
            await reply?.update({'text': t});
          }
        }
        await reply?.update({
          'text': latest.isEmpty ? '回答を取得できませんでした。' : latest,
        });
      } catch (e) {
        debugPrint('Gemini通信エラー: $e');
        await reply?.update({'text': '回答を取得できませんでした。通信を確認して、もう一度送ってください。'});
      }
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  void _showError() {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('送信できませんでした'),
        content: const Text('通信状況を確認して、もう一度お試しください。'),
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
    final isPlaza = _mode == _Mode.plaza;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: LabeledSegmented<_Mode>(
              value: _mode,
              options: const {_Mode.plaza: 'ママ広場', _Mode.ai: 'AI相談'},
              onChanged: _selectMode,
            ),
          ),
          if (isPlaza) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: LabeledSegmented<ChatRoom>(
                value: _room,
                options: {for (final r in ChatRoom.values) r: r.label},
                onChanged: _selectRoom,
              ),
            ),
            _Caption('誰もが安心して話せる優しい場所にしましょう。'),
          ] else
            _Caption('AIによる回答です。体調や発育が気になるときは、小児科に相談してください。'),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // 初回は複合インデックス未作成のエラーが出ることがある（下記参照）
                  debugPrint('チャット取得エラー: ${snapshot.error}');
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
                  return Center(
                    child: Text(
                      isPlaza ? 'まだ投稿がありません。' : 'こんばんは。気になることを書いてください。',
                      style: TextStyle(color: p.textSecondary),
                    ),
                  );
                }
                final myUid = _repo.uid;
                return ListView.builder(
                  reverse: true, // 新しいものが下に来る
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    final mine = isPlaza ? m.senderId == myUid : !m.isAi;
                    return _Bubble(
                      name: _nameOf(m, mine, isPlaza),
                      text: m.text,
                      time: hm(m.sentAt),
                      mine: mine,
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(
            controller: _input,
            hint: isPlaza ? 'ひとこと投稿する' : 'AIに相談する',
            busy: _aiBusy,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  String _nameOf(ChatMessage m, bool mine, bool isPlaza) {
    if (mine) return '自分';
    if (!isPlaza) return 'AI';
    return '匿名 ${m.senderId.substring(0, min(4, m.senderId.length))}';
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(fontSize: 12, color: p.textSecondary),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.name,
    required this.text,
    required this.time,
    required this.mine,
  });

  final String name, text, time;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.75;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            '$name  $time',
            style: TextStyle(fontSize: 11, color: p.textSecondary),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              // 自分は金、相手は面の色。枠線は使わない
              color: mine ? p.nursing : p.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(mine ? 16 : 4),
                bottomRight: Radius.circular(mine ? 4 : 16),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: mine ? Colors.black87 : p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.hint,
    required this.busy,
    required this.onSend,
  });

  final TextEditingController controller;
  final String hint;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: hint,
              minLines: 1,
              maxLines: 4,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              style: TextStyle(color: p.textPrimary, fontSize: 15),
              placeholderStyle: TextStyle(color: p.textSecondary, fontSize: 15),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          CupertinoButton(
            onPressed: busy ? null : onSend,
            child: busy
                ? const CupertinoActivityIndicator()
                : Icon(
                    CupertinoIcons.arrow_up_circle_fill,
                    size: 32,
                    color: p.accent,
                  ),
          ),
        ],
      ),
    );
  }
}
