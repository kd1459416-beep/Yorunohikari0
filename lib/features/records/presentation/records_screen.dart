import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/labeled_segmented.dart';
import '../data/record_repository.dart';
import '../domain/care_record.dart';
import '../domain/record_spec.dart';
import '../quick_record_controller.dart';
import 'day_record_list.dart';
import 'just_recorded_banner.dart';
import 'other_record_sheet.dart';
import 'quick_record_bar.dart';
import 'recent_summary.dart';
import 'record_detail_editor.dart';
import 'record_detail_sheet.dart';
import 'record_line_chart.dart';
import 'record_type_style.dart';

/// 記録タブ。上から「日付」「ワンタップ記録」「直前の記録のお知らせ」、
/// その下がスクロールする「前回のサマリー」「グラフ」「その日の一覧」。
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _repository = RecordRepository();
  late final _quick = QuickRecordController(_repository);
  late final Stream<List<CareRecord>> _recent = _repository.watchRecent();
  late Stream<List<CareRecord>> _dayStream = _repository.watchDay(_day);

  DateTime _day = DateTime.now();
  RecordType _chartType = RecordType.nursing;

  @override
  void dispose() {
    _quick.dispose();
    super.dispose();
  }

  void _showDay(DateTime day) => setState(() {
    _day = day;
    _dayStream = _repository.watchDay(day);
  });

  void _moveDay(int delta) => _showDay(_day.add(Duration(days: delta)));

  /// メインのボタン: 「いま」の記録を保存。別の日を見ていたら、今日に戻す
  void _recordNow(RecordType type) {
    _quick.record(type);
    if (!DateUtils.isSameDay(_day, DateTime.now())) _showDay(DateTime.now());
  }

  /// 「＋その他」: 種類を選ぶ → 入力する → 保存
  Future<void> _addOtherRecord() async {
    final type = await showOtherRecordSheet(context);
    if (type == null || !mounted) return;

    final input = await showRecordDetailSheet(context, type: type);
    if (input == null) return;

    await _repository.add(
      CareRecord(
        type: type,
        endedAt: DateTime.now(),
        detail: input.summary(type),
        value: input.value,
        attributes: input.attributes,
        note: input.note,
      ),
    );
    if (mounted && !DateUtils.isSameDay(_day, DateTime.now()))
      _showDay(DateTime.now());
  }

  void _editJustRecorded(CareRecord record) {
    _quick.dismiss(); // お知らせは閉じてから、入力画面を出す
    editRecordDetail(context, _repository, record);
  }

  void _delete(CareRecord record) {
    final id = record.id;
    if (id != null) _repository.delete(id);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return SafeArea(
      child: Column(
        children: [
          _DayHeader(day: _day, onMove: _moveDay),
          QuickRecordBar(onRecord: _recordNow, onMore: _addOtherRecord),
          JustRecordedBanner(
            controller: _quick,
            onEditDetail: _editJustRecorded,
          ),
          Expanded(
            child: StreamBuilder<List<CareRecord>>(
              stream: _dayStream,
              builder: (context, snapshot) {
                final records = snapshot.data ?? const <CareRecord>[];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    StreamBuilder<List<CareRecord>>(
                      stream: _recent,
                      builder: (_, recent) => RecentSummary(
                        recent: recent.data ?? const [],
                        dayRecords: records,
                      ),
                    ),
                    const SizedBox(height: 28),
                    LabeledSegmented<RecordType>(
                      value: _chartType,
                      options: {
                        for (final t in RecordType.chartTypes) t: t.label,
                      },
                      onChanged: (t) => setState(() => _chartType = t),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 240,
                      child: RecordLineChart(
                        values: records
                            .where((r) => r.type == _chartType)
                            .hourly(_chartType.valueOf),
                        color: _chartType.color(p),
                        unit: _chartType.unit,
                        // 回数のグラフは、縦軸を 0・1・2… の整数で出す
                        minTop: _chartType.isCount ? 4 : 1,
                        yInterval: _chartType.isCount ? 1 : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    DayRecordList(
                      records: records,
                      onEditDetail: (r) =>
                          editRecordDetail(context, _repository, r),
                      onDelete: _delete,
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
