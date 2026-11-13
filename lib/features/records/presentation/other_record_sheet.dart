import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_palette.dart';
import '../domain/care_record.dart';
import 'record_type_style.dart';

/// 「離乳食」「体温」「病院」「お風呂」を選ぶ下からのシート。
/// 選んだ種別を返す（閉じたら null）。
Future<RecordType?> showOtherRecordSheet(BuildContext context) {
  return showCupertinoModalPopup<RecordType>(
    context: context,
    builder: (ctx) {
      final p = AppPalette.of(ctx);
      return CupertinoActionSheet(
        title: const Text('その他の記録'),
        actions: [
          for (final type in RecordType.subTypes)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(type),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  type.icon(type.color(p), size: 22),
                  const SizedBox(width: 10),
                  Text(type.label),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('キャンセル'),
        ),
      );
    },
  );
}
