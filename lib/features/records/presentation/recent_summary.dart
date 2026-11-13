import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/elapsed_text.dart';
import '../domain/care_record.dart';
import 'record_type_style.dart';

/// 「前回の授乳／寝かしつけ／おしっこ／うんち」を、2×2で並べたカード。
/// どれも「2時間38分前」のように分単位まで表示する（オムツ替えの目安に）。
class RecentSummary extends StatefulWidget {
  const RecentSummary({
    super.key,
    required this.recent,
    required this.dayRecords,
  });

  final List<CareRecord> recent; // 新しい順
  final List<CareRecord> dayRecords; // 選んだ日の記録

  @override
  State<RecentSummary> createState() => _RecentSummaryState();
}

class _RecentSummaryState extends State<RecentSummary> {
  static const _rows = [
    [RecordType.nursing, RecordType.sleep],
    [RecordType.pee, RecordType.poop],
  ];

  // 「〇分前」を最新に保つため、1分ごとに現在時刻を流す
  late final Stream<DateTime> _clock = Stream.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );

  Widget _cell(RecordType type, DateTime now) {
    return _SummaryCell(
      type: type,
      last: widget.recent.where((r) => r.type == type).firstOrNull,
      dayTotal: widget.dayRecords
          .where((r) => r.type == type)
          .fold(0.0, (sum, r) => sum + type.valueOf(r)),
      now: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: StreamBuilder<DateTime>(
        stream: _clock,
        initialData: DateTime.now(),
        builder: (context, snapshot) {
          final now = snapshot.requireData;
          return Column(
            children: [
              for (final (i, row) in _rows.indexed) ...[
                if (i > 0)
                  Divider(height: 0.5, thickness: 0.5, color: p.hairline),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      for (final (j, type) in row.indexed) ...[
                        if (j > 0)
                          VerticalDivider(
                            width: 0.5,
                            thickness: 0.5,
                            color: p.hairline,
                          ),
                        Expanded(child: _cell(type, now)),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.type,
    required this.last,
    required this.dayTotal,
    required this.now,
  });

  final RecordType type;
  final CareRecord? last; // 前回の記録（なければ null）
  final double dayTotal;
  final DateTime now;

  /// 時刻の表示。時間を測っていない記録（ワンタップ）は、時刻ひとつだけ
  String _timeText(CareRecord r) =>
      r.isInstant ? hm(r.endedAt) : '${hm(r.startedAt)}–${hm(r.endedAt)}';

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final record = last;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              type.icon(type.color(p), size: 16),
              const SizedBox(width: 6),
              Text(
                '前回の${type.label}',
                style: TextStyle(fontSize: 13, color: p.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 一番目立たせる: 前回からの経過時間（2時間38分前）
          if (record == null)
            Text('記録なし', style: TextStyle(fontSize: 20, color: p.textSecondary))
          else
            ElapsedText(
              elapsed: ElapsedTime.since(record.endedAt, now: now),
              color: type.color(p),
            ),

          const SizedBox(height: 8),
          Text(
            record == null ? ' ' : _timeText(record),
            style: TextStyle(fontSize: 14, color: p.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'この日の合計 ${dayTotal.round()}${type.unit}',
            style: TextStyle(fontSize: 13, color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}
