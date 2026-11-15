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

/// 母乳（抱っこ）の色。ダークネイビーの背景でも目にやさしい、やわらかいコーラルピンク
const breastColor = Color(0xFFF29E9B);

extension RecordTypeStyle on RecordType {
  /// [breast] が true のときだけ、母乳の色にする（授乳のうち、ミルク以外）
  Color color(AppPalette p, {bool breast = false}) => breast
      ? breastColor
      : switch (this) {
          RecordType.nursing => p.nursing, // ミルクは、これまでの灯りイエロー
          RecordType.sleep => p.sleeping,
          RecordType.pee => const Color(0xFF38BDF8),
          RecordType.poop => const Color(0xFFC98A4B),
          RecordType.babyFood => const Color(0xFF4CAF82),
          RecordType.snack => const Color(0xFFE0A030),
          RecordType.temperature => const Color(0xFFE5739A),
          RecordType.hospital => const Color(0xFFE5736E),
          RecordType.bath => const Color(0xFF2BB5B5),
        };

  /// [breast] が true のときだけ、抱っこのアイコンにする（授乳のうち、ミルク以外）
  Widget icon(Color color, {double size = 24, bool breast = false}) => breast
      ? BreastfeedingIcon(size: size, color: color)
      : switch (this) {
          RecordType.nursing => BottleIcon(size: size, color: color),
          RecordType.sleep => Icon(
            CupertinoIcons.moon_zzz_fill,
            size: size,
            color: color,
          ),
          RecordType.pee => Icon(
            CupertinoIcons.drop_fill,
            size: size,
            color: color,
          ),
          RecordType.poop => PoopIcon(size: size, color: color),
          RecordType.babyFood => Icon(
            Icons.rice_bowl_rounded,
            size: size,
            color: color,
          ),
          // Icons.cookie_rounded が無いというエラーが出たら、Icons.bakery_dining_rounded に
          RecordType.snack => Icon(
            Icons.cookie_rounded,
            size: size,
            color: color,
          ),
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
          RecordType.bath => Icon(
            Icons.bathtub_rounded,
            size: size,
            color: color,
          ),
        };
}

/// 記録1件の色とアイコン。授乳は、母乳とミルクで見た目を変える
extension CareRecordStyle on CareRecord {
  Color color(AppPalette p) => type.color(p, breast: isBreast);

  Widget icon(AppPalette p, {double size = 24}) =>
      type.icon(color(p), size: size, breast: isBreast);
}

/// 母乳のアイコン（赤ちゃんを抱っこしている人のシルエット）
class BreastfeedingIcon extends StatelessWidget {
  const BreastfeedingIcon({super.key, required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _BreastfeedingPainter(color)),
  );
}

class _BreastfeedingPainter extends CustomPainter {
  const _BreastfeedingPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24); // 24x24 の座標で描く
    final paint = Paint()..color = color;

    // 赤ちゃん（体 + 頭）。人の体の上に重ねる
    final baby = Path()
      ..addRRect(
        RRect.fromLTRBR(10.4, 14.6, 21.2, 20.2, const Radius.circular(2.8)),
      )
      ..addOval(Rect.fromCircle(center: const Offset(19.2, 12), radius: 2.3));

    canvas.saveLayer(const Rect.fromLTWH(0, 0, 24, 24), Paint());

    // 抱っこする人（頭と体）
    canvas.drawCircle(const Offset(8.4, 5.4), 3, paint);
    canvas.drawPath(
      Path()
        ..moveTo(2.6, 22)
        ..lineTo(2.6, 15)
        ..quadraticBezierTo(2.6, 9.8, 8.4, 9.8)
        ..quadraticBezierTo(14.2, 9.8, 14.2, 15)
        ..lineTo(14.2, 22)
        ..close(),
      paint,
    );

    // 赤ちゃんのまわりを少し切り抜いて、体と重ならないようにする
    canvas.drawPath(
      baby,
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(baby, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BreastfeedingPainter old) => old.color != color;
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
    this.breast = false, // 母乳なら true（ピンク + 抱っこのアイコン）
  });

  final String label;
  final RecordType type;
  final bool breast;
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
    final color = item.type.color(p, breast: item.breast);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              item.type.icon(color, size: 16, breast: item.breast),
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
                          record.icon(p, size: 20),
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
                    color:
                        item.type?.color(p, breast: item.breast) ??
                        p.textPrimary,
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
                          color: record.color(p),
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
//  5. グラフ（棒グラフ）
// ============================================================

/// 棒グラフ。1本が、1つの時間帯（または1日）。
class RecordBarChart extends StatelessWidget {
  const RecordBarChart({
    super.key,
    required this.values,
    required this.color,
    required this.labelOf,
    required this.tooltipOf,
    this.minTop = 3,
    this.barWidth = 8,
  });

  final List<double> values;
  final Color color;
  final double barWidth;

  /// 縦軸の上限の最小値（回数は 3、ml は 100 など。棒が大げさに伸びないようにする）
  final double minTop;

  /// 横軸の文字。null を返した位置には何も出さない
  final String? Function(int index) labelOf;

  /// 棒を押したときに出す文字
  final String Function(int index, double value) tooltipOf;

  /// 縦軸の目盛りの間隔の候補
  static const _intervals = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final labelStyle = TextStyle(fontSize: 10, color: p.textSecondary);

    // 縦軸の上限と目盛りの間隔。目盛りはおよそ4本になる、切りのいい数にする
    final raw = math.max(values.reduce(math.max), minTop);
    final interval = raw <= 6
        ? 1.0
        : _intervals
              .firstWhere((i) => i >= raw / 4, orElse: () => 1000)
              .toDouble();
    final top = (raw / interval).ceil() * interval;

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: top,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: p.hairline, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) {
                final text = labelOf(v.toInt());
                if (text == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(text, style: labelStyle),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: interval,
              getTitlesWidget: (v, _) =>
                  Text('${v.round()}', style: labelStyle),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => p.surface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
                  tooltipOf(group.x, rod.toY),
                  TextStyle(color: p.textPrimary, fontSize: 12),
                ),
          ),
        ),
        barGroups: [
          for (final (i, value) in values.indexed)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: color,
                  width: barWidth,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(barWidth / 2),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// グラフの期間
enum ChartRange {
  day('1日'),
  week('7日間');

  const ChartRange(this.label);
  final String label;
}

/// グラフに描く1種類のデータ。例: 「授乳（回数）」「ミルク（ml）」
class ChartSeries {
  ChartSeries({
    required this.label,
    required this.type,
    required this.matches,
    this.value = _one,
    this.unit = '回',
    this.breast = false, // 母乳なら true（ピンクの棒）
  });

  /// 種別ごとの回数グラフ（おしっこ・うんちなど）
  factory ChartSeries.countOf(RecordType type) => ChartSeries(
    label: type.label,
    type: type,
    matches: (r) => r.type == type,
  );

  final String label;

  /// 棒の色を借りる種別
  final RecordType type;

  /// このデータに数える記録の条件
  final bool Function(CareRecord) matches;

  /// 1件ぶんの値。省略すると 1（= 回数）
  final double Function(CareRecord) value;

  /// 単位（回・ml・分）
  final String unit;

  /// 母乳（ミルク以外の授乳）か
  final bool breast;

  /// グラフ・切り替えに使う色
  Color color(AppPalette p) => type.color(p, breast: breast);

  /// 縦軸の上限の最小値
  double get minTop => switch (unit) {
    'ml' => 100.0,
    '分' => 60.0,
    _ => 3.0,
  };

  static double _one(CareRecord _) => 1;
}

const _weekdayNames = ['月', '火', '水', '木', '金', '土', '日'];

/// グラフに描くデータの切り替え。選んでいるものは、そのデータの色でうっすら塗る（凡例も兼ねる）
class _SeriesSwitch extends StatelessWidget {
  const _SeriesSwitch({
    required this.series,
    required this.selected,
    required this.onChanged,
  });

  final List<ChartSeries> series;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        for (final (i, s) in series.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36,
                decoration: BoxDecoration(
                  color: i == selected
                      ? s.color(p).withValues(alpha: 0.22)
                      : p.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.color(p),
                      ),
                      child: const SizedBox.square(dimension: 8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: i == selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: i == selected ? s.color(p) : p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 棒グラフのまとまり。[series] が2つ以上なら種類の切り替え、期間は「1日 / 7日間」を切り替える。
/// 1日は時間帯ごと、7日間は日ごとの合計を出す。
class RecordChartSection extends StatefulWidget {
  const RecordChartSection({
    super.key,
    required this.series,
    required this.records,
    required this.recent,
  });

  final List<ChartSeries> series;

  /// 選んだ日の記録（1日のグラフ用）
  final List<CareRecord> records;

  /// 直近の記録（7日間のグラフ用）
  final List<CareRecord> recent;

  @override
  State<RecordChartSection> createState() => _RecordChartSectionState();
}

class _RecordChartSectionState extends State<RecordChartSection> {
  // series は画面が更新されるたびに作り直されるので、選んだものは番号で覚える
  int _index = 0;
  ChartRange _range = ChartRange.day;

  ChartSeries get _series =>
      widget.series[math.min(_index, widget.series.length - 1)];

  Widget _dayChart(Color color) {
    final s = _series;
    return RecordBarChart(
      values: widget.records.where(s.matches).hourlyTotals(s.value),
      color: color,
      minTop: s.minTop,
      labelOf: (i) => i % 6 == 0 ? '$i時' : null,
      tooltipOf: (i, v) => '$i時  ${v.round()}${s.unit}',
    );
  }

  Widget _weekChart(Color color) {
    final s = _series;
    final today = DateTime.now();
    // i 番目の棒の日付（6 = 今日）
    DateTime dateOf(int i) =>
        DateTime(today.year, today.month, today.day - (6 - i));
    String weekdayOf(int i) => _weekdayNames[dateOf(i).weekday - 1];

    return RecordBarChart(
      values: widget.recent.where(s.matches).dailyTotals(s.value, today: today),
      color: color,
      minTop: s.minTop,
      barWidth: 20,
      labelOf: (i) => i == 6 ? '今日' : weekdayOf(i),
      tooltipOf: (i, v) {
        final d = dateOf(i);
        return '${d.month}/${d.day}(${weekdayOf(i)})  ${v.round()}${s.unit}';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final color = _series.color(p);

    return Column(
      children: [
        if (widget.series.length > 1) ...[
          _SeriesSwitch(
            series: widget.series,
            selected: math.min(_index, widget.series.length - 1),
            onChanged: (i) => setState(() => _index = i),
          ),
          const SizedBox(height: 12),
        ],
        LabeledSegmented<ChartRange>(
          value: _range,
          options: {for (final r in ChartRange.values) r: r.label},
          onChanged: (r) => setState(() => _range = r),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          // 一番上の数字が、上に少しはみ出しても切れないように、余白をあける
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _range == ChartRange.day
                ? _dayChart(color)
                : _weekChart(color),
          ),
        ),
      ],
    );
  }
}
