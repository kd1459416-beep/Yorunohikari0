import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/time_format.dart';
import '../domain/care_record.dart';

extension RecordTypeColor on RecordType {
  Color color(AppPalette p) =>
      this == RecordType.nursing ? p.nursing : p.sleeping;
}

class RecentSummary extends StatelessWidget {
  const RecentSummary({
    super.key,
    required this.recent,
    required this.dayRecords,
  });

  final List<CareRecord> recent; // 新しい順
  final List<CareRecord> dayRecords;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final (i, type) in RecordType.values.indexed) ...[
              if (i > 0)
                VerticalDivider(width: 0.5, thickness: 0.5, color: p.hairline),
              Expanded(
                child: _Cell(
                  type: type,
                  last: recent.where((r) => r.type == type).firstOrNull,
                  dayTotal: dayRecords
                      .where((r) => r.type == type)
                      .fold(0.0, (sum, r) => sum + type.valueOf(r)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.type, required this.last, required this.dayTotal});

  final RecordType type;
  final CareRecord? last;
  final double dayTotal;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final last = this.last;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '前回の${type.label}',
            style: TextStyle(fontSize: 12, color: p.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            last == null ? '記録なし' : '${hm(last.startedAt)}–${hm(last.endedAt)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: type.color(p),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            last == null ? '' : timeAgo(last.endedAt),
            style: TextStyle(fontSize: 12, color: p.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            'この日の合計 ${dayTotal.round()}${type.unit}',
            style: TextStyle(fontSize: 12, color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}
