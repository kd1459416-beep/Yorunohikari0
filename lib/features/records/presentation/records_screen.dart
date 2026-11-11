import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../data/record_repository.dart';
import '../domain/care_record.dart';
import 'recent_summary.dart';
import 'record_line_chart.dart';
import '../../../core/theme/app_palette.dart';
import 'day_record_list.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _repo = RecordRepository();
  late final Stream<List<CareRecord>> _recent = _repo.watchRecent();
  late Stream<List<CareRecord>> _dayStream = _repo.watchDay(_day);
  DateTime _day = DateTime.now();
  RecordType _type = RecordType.nursing;

  void _moveDay(int delta) => setState(() {
    _day = _day.add(Duration(days: delta));
    _dayStream = _repo.watchDay(_day);
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SafeArea(
      child: Column(
        children: [
          _DayHeader(day: _day, onMove: _moveDay),
          Expanded(
            child: StreamBuilder<List<CareRecord>>(
              stream: _dayStream,
              builder: (context, snapshot) {
                final records = snapshot.data ?? const <CareRecord>[];
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    StreamBuilder<List<CareRecord>>(
                      stream: _recent,
                      builder: (_, recent) => RecentSummary(
                        recent: recent.data ?? const [],
                        dayRecords: records,
                      ),
                    ),
                    const SizedBox(height: 28),
                    CupertinoSlidingSegmentedControl<RecordType>(
                      groupValue: _type,
                      children: {
                        for (final t in RecordType.values)
                          t: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(t.label),
                          ),
                      },
                      onValueChanged: (t) => setState(() => _type = t ?? _type),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 240,
                      child: RecordLineChart(
                        values: records
                            .where((r) => r.type == _type)
                            .hourly(_type.valueOf),
                        color: _type.color(p),
                        unit: _type.unit,
                      ),
                    ),
                    const SizedBox(height: 24),
                    DayRecordList(
                      records: records,
                      onDelete: (r) {
                        final id = r.id;
                        if (id != null) _repo.delete(id);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.onMove});

  final DateTime day;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(day, DateTime.now());
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CupertinoButton(
          onPressed: () => onMove(-1),
          child: const Icon(CupertinoIcons.chevron_left, size: 20),
        ),
        Text(
          '${day.year}年${day.month}月${day.day}日',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        CupertinoButton(
          onPressed: isToday ? null : () => onMove(1),
          child: const Icon(CupertinoIcons.chevron_right, size: 20),
        ),
      ],
    );
  }
}
