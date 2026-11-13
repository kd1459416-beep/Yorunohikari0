import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/inset_section.dart';
import '../domain/care_record.dart';
import 'record_type_style.dart';

/// その日の記録一覧。タップすると「詳細を追加・変更」「削除」を選べる。
class DayRecordList extends StatelessWidget {
  const DayRecordList({
    super.key,
    required this.records,
    required this.onEditDetail,
    required this.onDelete,
  });

  final List<CareRecord> records;
  final ValueChanged<CareRecord> onEditDetail;
  final ValueChanged<CareRecord> onDelete;

  void _showActions(BuildContext context, CareRecord record) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('${hm(record.endedAt)} の${record.type.label}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              onEditDetail(record);
            },
            child: const Text('詳細を追加・変更'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete(record);
            },
            child: const Text('この記録を削除'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();
    final p = AppPalette.of(context);
    final sorted = [...records]..sort((a, b) => b.endedAt.compareTo(a.endedAt));

    return InsetSection(
      header: 'この日の記録',
      margin: EdgeInsets.zero, // 親の ListView に余白があるため
      children: [
        for (final record in sorted)
          InkWell(
            onTap: () => _showActions(context, record),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 種別の色の点
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: record.type.color(p),
                        ),
                        child: const SizedBox.square(dimension: 8),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${hm(record.startedAt)}  ${record.type.label}',
                        style: TextStyle(fontSize: 16, color: p.textPrimary),
                      ),
                      const Spacer(),
                      // 時間を測った記録だけ、所要時間を出す
                      if (!record.isInstant)
                        Text(
                          '${record.duration.inMinutes}分',
                          style: TextStyle(
                            fontSize: 15,
                            color: p.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  if (record.detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: Text(
                        record.detail,
                        style: TextStyle(fontSize: 13, color: p.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
