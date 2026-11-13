import 'package:flutter/material.dart';
import '../../core/widgets/labeled_segmented.dart';
import 'ai_chat_view.dart';
import 'plaza/plaza_view.dart';

enum _ChatMode { plaza, ai }

/// 「チャット」タブ。投稿ベースの広場と、1対1のAI相談を切り替える。
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  _ChatMode _mode = _ChatMode.plaza;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: LabeledSegmented<_ChatMode>(
              value: _mode,
              options: const {_ChatMode.plaza: 'ママ広場', _ChatMode.ai: 'AI相談'},
              onChanged: (mode) => setState(() => _mode = mode),
            ),
          ),
          Expanded(
            // 切り替えても、それぞれのスクロール位置・入力内容を保つ
            child: IndexedStack(
              index: _mode.index,
              children: const [PlazaView(), AiChatView()],
            ),
          ),
        ],
      ),
    );
  }
}
