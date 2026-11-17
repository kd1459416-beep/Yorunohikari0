import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../theme/app_palette.dart';

/// 画面下の入力欄。左に入力、右に送信ボタン。
class MessageInputBar extends StatelessWidget {
  const MessageInputBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onSend,
    this.busy = false,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;

  /// true の間は、送信ボタンの代わりに待機表示を出す
  final bool busy;
  final int? maxLength;

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
              inputFormatters: [
                if (maxLength != null)
                  LengthLimitingTextInputFormatter(maxLength),
              ],
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
