import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/inset_section.dart';
import '../domain/care_record.dart';

/// その日の記録一覧。タップすると削除の確認が出る。
class DayRecordList extends StatelessWidget {
  const DayRecordList({
    super.key,
    required this.records,
    required this.onDelete,
  });

  final List<CareRecord> records;
  final ValueChanged<CareRecord> onDelete;

  void _confirm(BuildContext context, CareRecord r) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('${hm(r.startedAt)} の${r.type.label}'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete(r);
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
        for (final r in sorted)
          InkWell(
            onTap: () => _confirm(context, r),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${hm(r.startedAt)}  ${r.type.label}',
                        style: TextStyle(fontSize: 16, color: p.textPrimary),
                      ),
                      const Spacer(),
                      Text(
                        '${r.duration.inMinutes}分',
                        style: TextStyle(fontSize: 15, color: p.textSecondary),
                      ),
                    ],
                  ),
                  if (r.detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      r.detail,
                      style: TextStyle(fontSize: 13, color: p.textSecondary),
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
