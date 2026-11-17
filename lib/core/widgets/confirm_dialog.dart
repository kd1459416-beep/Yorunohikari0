import 'package:flutter/cupertino.dart';

/// 「はい」のときだけ true を返す。誤操作を避けるため、既定は「いいえ」。
Future<bool> confirmDialog(
  BuildContext context, {
  required String message,
  bool destructive = false,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: const Text('確認'),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true, // 太字 = 既定の選択
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('いいえ'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('はい'),
        ),
      ],
    ),
  );
  return result ?? false;
}
