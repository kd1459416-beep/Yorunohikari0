import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/time_format.dart';
import '../domain/care_record.dart';

extension RecordTypeColor on RecordType {
  Color color(AppPalette p) =>
      this == RecordType.nursing ? p.nursing : p.sleeping;
}

/// 「前回の授乳」「前回の寝かしつけ」を左右に並べたカード。
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
  // 「〇分前」を最新に保つため、1分ごとに現在時刻を流す
  late final Stream<DateTime> _clock = Stream.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );

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
          return IntrinsicHeight(
            child: Row(
              children: [
                for (final (i, type) in RecordType.values.indexed) ...[
                  if (i > 0)
                    VerticalDivider(
                      width: 0.5,
                      thickness: 0.5,
                      color: p.hairline,
                    ),
                  Expanded(
                    child: _SummaryCell(
                      type: type,
                      last: widget.recent
                          .where((r) => r.type == type)
                          .firstOrNull,
                      dayTotal: widget.dayRecords
                          .where((r) => r.type == type)
                          .fold(0.0, (sum, r) => sum + type.valueOf(r)),
                      now: now,
                    ),
                  ),
                ],
              ],
            ),
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

  /// 経過時間の文字の大きさ。夜間や片手でも読めるよう大きくしている
  static const _elapsedFontSize = 32.0;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final record = last;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '前回の${type.label}',
            style: TextStyle(fontSize: 13, color: p.textSecondary),
          ),
          const SizedBox(height: 8),

          // 一番目立たせる: 前回からの経過時間
          if (record == null)
            Text('記録なし', style: TextStyle(fontSize: 20, color: p.textSecondary))
          else
            FittedBox(
              fit: BoxFit.scaleDown, // 幅が足りないときだけ縮める
              alignment: Alignment.centerLeft,
              child: Text(
                timeAgo(record.endedAt, now: now),
                style: TextStyle(
                  fontSize: _elapsedFontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: type.color(p),
                ),
              ),
            ),

          const SizedBox(height: 8),
          // 補助情報: 時刻の範囲と、その日の合計
          Text(
            record == null
                ? ' '
                : '${hm(record.startedAt)}–${hm(record.endedAt)}',
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
