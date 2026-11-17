import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
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

  void _toggleMode() {
    setState(() {
      _mode = _mode == _ChatMode.plaza ? _ChatMode.ai : _ChatMode.plaza;
    });
  }

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
            child: Stack(
              children: [
                // 切り替えても、それぞれのスクロール位置・入力内容を保つ
                IndexedStack(
                  index: _mode.index,
                  children: const [PlazaView(), AiChatView()],
                ),
                _SwitchModeArrow(mode: _mode, onTap: _toggleMode),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 上部のタブと同じ役割（ママ広場⇄AI相談の切替）を、親指が届きやすい
/// 画面中央よりやや下・端の位置でも操作できるようにするボタン。
/// 矢印はこれから移る先を指す（広場にいれば右＝AI相談、AI相談にいれば左＝広場）。
class _SwitchModeArrow extends StatelessWidget {
  const _SwitchModeArrow({required this.mode, required this.onTap});

  final _ChatMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isPlaza = mode == _ChatMode.plaza;
    return Align(
      alignment: Alignment(isPlaza ? 0.95 : -0.95, 0.35),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: p.surface.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPlaza ? Icons.chevron_right : Icons.chevron_left,
            color: p.accent,
            size: 22,
          ),
        ),
      ),
    );
  }
}
