import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/care_icons.dart';
import '../../core/widgets/elapsed_text.dart';
import '../../core/widgets/inset_section.dart';
import '../../core/widgets/labeled_segmented.dart';
import 'record_models.dart';
import 'record_store.dart';

// ============================================================
//  1. 種別・カテゴリの色とアイコン
// ============================================================

extension RecordTypeStyle on RecordType {
  Color color(AppPalette p) => switch (this) {
    RecordType.nursing => p.nursing,
    RecordType.sleep => p.sleeping,
    RecordType.pee => const Color(0xFF38BDF8),
    RecordType.poop => const Color(0xFFC98A4B),
    RecordType.babyFood => const Color(0xFF4CAF82),
    RecordType.snack => const Color(0xFFE0A030),
    RecordType.temperature => const Color(0xFFE5739A),
    RecordType.hospital => const Color(0xFFE5736E),
    RecordType.bath => const Color(0xFF2BB5B5),
  };

  Widget icon(Color color, {double size = 24}) => switch (this) {
    RecordType.nursing => BottleIcon(size: size, color: color),
    RecordType.sleep => Icon(
      CupertinoIcons.moon_zzz_fill,
      size: size,
      color: color,
    ),
    RecordType.pee => Icon(CupertinoIcons.drop_fill, size: size, color: color),
    RecordType.poop => PoopIcon(size: size, color: color),
    RecordType.babyFood => Icon(
      Icons.rice_bowl_rounded,
      size: size,
      color: color,
    ),
    // Icons.cookie_rounded が無いというエラーが出たら、Icons.bakery_dining_rounded に
    RecordType.snack => Icon(Icons.cookie_rounded, size: size, color: color),
    RecordType.temperature => Icon(
      CupertinoIcons.thermometer,
      size: size,
      color: color,
    ),
    RecordType.hospital => Icon(
      Icons.local_hospital_rounded,
      size: size,
      color: color,
    ),
    RecordType.bath => Icon(Icons.bathtub_rounded, size: size, color: color),
  };
}

/// うんちのアイコン（3段に重なった形）
class PoopIcon extends StatelessWidget {
  const PoopIcon({super.key, required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _PoopPainter(color)),
  );
}

class _PoopPainter extends CustomPainter {
  const _PoopPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24); // 24x24 の座標で描く
    final paint = Paint()..color = color;

    // 下の段 → 真ん中 → 上の段 → てっぺんのとがり
    for (final (rect, radius) in const [
      (Rect.fromLTRB(3, 15.6, 21, 21.5), 3.0),
      (Rect.fromLTRB(5.5, 10.6, 18.5, 15.0), 2.6),
      (Rect.fromLTRB(8.5, 6.2, 15.5, 10.0), 2.3),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        paint,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(12, 1.8)
        ..quadraticBezierTo(14.8, 3.0, 13.4, 5.6)
        ..lineTo(10.6, 5.6)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_PoopPainter old) => old.color != color;
}

// ============================================================
//  2. ページ上部: 経過時間サマリー
// ============================================================

/// サマリーの1項目。例: 「前回のおしっこ」
class SummaryItem {
  const SummaryItem({
    required this.label,
    required this.type,
    required this.matches,
  });

  final String label;

  /// 色とアイコンを借りる種別
  final RecordType type;

  /// 「前回」の対象にする記録の条件
  final bool Function(CareRecord) matches;
}

/// 「前回の〇〇から 2時間38分前」を、1〜2項目ならべたカード。
class ElapsedSummaryCard extends StatefulWidget {
  const ElapsedSummaryCard({
    super.key,
    required this.items,
    required this.recent,
  });

  final List<SummaryItem> items;
  final List<CareRecord> recent; // 新しい順

  @override
  State<ElapsedSummaryCard> createState() => _ElapsedSummaryCardState();
}

class _ElapsedSummaryCardState extends State<ElapsedSummaryCard> {
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: StreamBuilder<DateTime>(
        stream: _clock,
        initialData: DateTime.now(),
        builder: (context, snapshot) {
          final now = snapshot.requireData;
          return IntrinsicHeight(
            child: Row(
              children: [
                for (final (i, item) in widget.items.indexed) ...[
                  if (i > 0)
                    VerticalDivider(
                      width: 0.5,
                      thickness: 0.5,
                      color: p.hairline,
                    ),
                  Expanded(
                    child: _SummaryCell(
                      item: item,
                      last: widget.recent.where(item.matches).firstOrNull,
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
    required this.item,
    required this.last,
    required this.now,
  });

  final SummaryItem item;
  final CareRecord? last;
  final DateTime now;

  /// 時間を測っていない記録は、時刻ひとつだけ
  String _timeText(CareRecord r) =>
      r.isInstant ? hm(r.endedAt) : '${hm(r.startedAt)}–${hm(r.endedAt)}';

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final record = last;
    final color = item.type.color(p);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              item.type.icon(color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  item.label,
                  style: TextStyle(fontSize: 13, color: p.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (record == null)
            Text('記録なし', style: TextStyle(fontSize: 20, color: p.textSecondary))
          else
            ElapsedText(
              elapsed: ElapsedTime.since(record.endedAt, now: now),
              color: color,
            ),
          const SizedBox(height: 8),
          Text(
            record == null ? ' ' : _timeText(record),
            style: TextStyle(fontSize: 14, color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  3. 記録ボタン
// ============================================================

/// 記録ページに並べるボタン。
/// [asksFirst] が true のものは、押すと先に入力画面が出る（体温・ミルク量・病院の内容）。
/// それ以外は、1タップで「いま」の記録を保存する。
enum QuickAction {
  pee(RecordType.pee),
  poop(RecordType.poop),
  babyFood(RecordType.babyFood),
  milk(RecordType.nursing, label: 'ミルク', asksFirst: true), // 授乳（ミルク）として保存
  snack(RecordType.snack),
  temperature(RecordType.temperature, asksFirst: true),
  bath(RecordType.bath),
  hospital(RecordType.hospital, label: '病院・お薬', asksFirst: true);

  const QuickAction(this.type, {this.label, this.asksFirst = false});

  /// 保存する種別（ミルクは授乳）。色とアイコンも、ここから決まる
  final RecordType type;
  final String? label;
  final bool asksFirst;

  String get displayLabel => label ?? type.label;
}

/// ページの上に置く、大きな記録ボタン。片手・夜間でも押しやすい高さ。
class QuickActionBar extends StatelessWidget {
  const QuickActionBar({
    super.key,
    required this.actions,
    required this.onAction,
  });

  final List<QuickAction> actions;
  final ValueChanged<QuickAction> onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Row(
        children: [
          for (final (i, action) in actions.indexed) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                action: action,
                onTap: () => onAction(action),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 押している間だけ少し縮むボタン
class _ActionButton extends StatefulWidget {
  const _ActionButton({required this.action, required this.onTap});

  final QuickAction action;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  void _setPressed(bool value) => setState(() => _isPressed = value);

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final type = widget.action.type;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 80),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              type.icon(type.color(p), size: 32),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.action.displayLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ワンタップで記録した直後に、約8秒だけ出るお知らせ。
/// 「詳細」で硬さ・量などを足せる。「取消」で記録を消せる。
class JustRecordedBanner extends StatelessWidget {
  const JustRecordedBanner({
    super.key,
    required this.controller,
    required this.onEditDetail,
  });

  final QuickRecordController controller;
  final ValueChanged<CareRecord> onEditDetail;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final record = controller.last;
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: record == null
              ? const SizedBox(width: double.infinity) // 高さ0 = 非表示
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 2, 4, 2),
                      child: Row(
                        children: [
                          record.type.icon(record.type.color(p), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${record.type.label}を記録しました  ${hm(record.endedAt)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: p.textPrimary,
                              ),
                            ),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            onPressed: () => onEditDetail(record),
                            child: const Text(
                              '詳細',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            onPressed: controller.undo,
                            child: Text(
                              '取消',
                              style: TextStyle(
                                fontSize: 14,
                                color: p.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// その日の回数・量を、横にならべる
class StatsRow extends StatelessWidget {
  const StatsRow({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// その日の履歴。行をタップすると「詳細を追加・変更」「時刻を変更」「削除」を選べる。
class DayRecordList extends StatelessWidget {
  const DayRecordList({
    super.key,
    required this.records,
    required this.onEditDetail,
    required this.onEditTiming,
    required this.onDelete,
    this.labelOf,
  });

  final List<CareRecord> records;
  final ValueChanged<CareRecord> onEditDetail;
  final ValueChanged<CareRecord> onEditTiming;
  final ValueChanged<CareRecord> onDelete;

  /// 行の名前を変えたいとき（食事ページで、ミルクの授乳を「ミルク」と出す）
  final String Function(CareRecord)? labelOf;

  String _label(CareRecord r) => labelOf?.call(r) ?? r.type.label;

  void _showActions(BuildContext context, CareRecord record) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        void choose(ValueChanged<CareRecord> action) {
          Navigator.of(ctx).pop();
          action(record);
        }

        return CupertinoActionSheet(
          title: Text('${hm(record.endedAt)} の${_label(record)}'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => choose(onEditDetail),
              child: const Text('詳細を追加・変更'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => choose(onEditTiming),
              child: const Text('時刻を変更'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => choose(onDelete),
              child: const Text('この記録を削除'),
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

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final sorted = [...records]..sort((a, b) => b.endedAt.compareTo(a.endedAt));

    return InsetSection(
      header: 'この日の記録',
      margin: EdgeInsets.zero, // 親が左右の余白を持っているため
      children: [
        for (final record in sorted)
          InkWell(
            onTap: () => _showActions(context, record),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: record.type.color(p),
                        ),
                        child: const SizedBox.square(dimension: 8),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${hm(record.startedAt)}  ${_label(record)}',
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

// ============================================================
//  5. グラフ
// ============================================================

/// 0〜23時の24点を滑らかな曲線で描く。
class RecordLineChart extends StatelessWidget {
  const RecordLineChart({
    super.key,
    required this.values,
    required this.color,
    required this.unit,
    this.minTop = 1,
    this.yInterval,
  }) : assert(values.length == 24);

  final List<double> values;
  final Color color;
  final String unit;

  /// 縦軸の上限の最小値（回数のグラフを、0・1・2…の整数で見せるため）
  final double minTop;

  /// 縦軸の目盛りの間隔（null なら自動）
  final double? yInterval;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final labelStyle = TextStyle(fontSize: 10, color: p.textSecondary);
    final maxY = math.max(values.reduce(math.max) * 1.25, minTop);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 23,
        minY: 0,
        maxY: maxY,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: p.hairline, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 6,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${v.toInt()}時', style: labelStyle),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yInterval,
              maxIncluded: false,
              getTitlesWidget: (v, _) =>
                  Text('${v.round()}$unit', style: labelStyle),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => p.surface,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${s.x.toInt()}時  ${s.y.round()}$unit',
                  TextStyle(color: p.textPrimary, fontSize: 12),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (final (i, v) in values.indexed) FlSpot(i.toDouble(), v),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true, // 0未満に膨らまない
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 1日の時間帯別グラフ。[types] が2つ以上なら、切り替えのタブを出す。
class HourlyChartSection extends StatefulWidget {
  const HourlyChartSection({
    super.key,
    required this.types,
    required this.records,
  });

  final List<RecordType> types;
  final List<CareRecord> records; // 選んだ日の記録

  @override
  State<HourlyChartSection> createState() => _HourlyChartSectionState();
}

class _HourlyChartSectionState extends State<HourlyChartSection> {
  late RecordType _type = widget.types.first;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      children: [
        if (widget.types.length > 1) ...[
          LabeledSegmented<RecordType>(
            value: _type,
            options: {for (final t in widget.types) t: t.label},
            onChanged: (t) => setState(() => _type = t),
          ),
          const SizedBox(height: 20),
        ],
        SizedBox(
          height: 220,
          child: RecordLineChart(
            values: widget.records
                .where((r) => r.type == _type)
                .hourly(_type.valueOf),
            color: _type.color(p),
            unit: _type.unit,
            minTop: _type.isCount ? 4 : 1,
            yInterval: _type.isCount ? 1 : null,
          ),
        ),
      ],
    );
  }
}
