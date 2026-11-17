import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/time_format.dart';

/// AI相談の吹き出し。自分は右・金色、AIは左・面の色。
class AiMessageBubble extends StatelessWidget {
  const AiMessageBubble({
    super.key,
    required this.name,
    required this.text,
    required this.time,
    required this.isMine,
    this.isError = false,
  });

  final String name;
  final String text;
  final DateTime? time;
  final bool isMine;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.75;
    final textColor = isError
        ? CupertinoColors.systemRed
        : (isMine ? Colors.black87 : p.textPrimary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            time == null ? name : '$name  ${hm(time!)}',
            style: TextStyle(fontSize: 11, color: p.textSecondary),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? p.nursing : p.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMine ? 16 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 16),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: 15, height: 1.4, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
