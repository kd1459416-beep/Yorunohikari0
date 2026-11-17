import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/time_format.dart';
import '../map/presentation/nursing_detail_sheet.dart';
import '../reminder/reminder_service.dart';
import '../reminder/reminder_ui.dart';
import 'record_models.dart';
import 'record_sheets.dart';
import 'record_store.dart';
import 'record_widgets.dart';

// ============================================================
//  1. 記録画面（日付 + 横に並ぶタブ + 左右にスワイプするページ）
// ============================================================

/// 記録タブ。授乳ノートのように、上に日付とカテゴリのタブ、下は左右にスワイプして切り替えるページ。
/// リアルタイムの授乳・寝かしつけの記録は、マップ画面で光を灯して行う。
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen>
    with SingleTickerProviderStateMixin {
  static const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  final _repository = RecordRepository();
  late final _quick = QuickRecordController(_repository);
  late final _tools = RecordsTools(
    repository: _repository,
    quick: _quick,
    showToday: _showToday,
  );
  late final _tabs = TabController(
    length: RecordCategory.values.length,
    vsync: this,
  );

  // 画面の一番上で1回だけ取得して、各ページに渡す
  late final Stream<List<CareRecord>> _recent = _repository.watchRecent();
  late Stream<List<CareRecord>> _dayStream = _repository.watchDay(_day);

  DateTime _day = DateTime.now();

  @override
  void dispose() {
    _tabs.dispose();
    _quick.dispose();
    super.dispose();
  }

  void _showDay(DateTime day) => setState(() {
    _day = day;
    _dayStream = _repository.watchDay(day);
  });

  void _moveDay(int delta) => _showDay(_day.add(Duration(days: delta)));

  void _showToday() {
    if (!DateUtils.isSameDay(_day, DateTime.now())) _showDay(DateTime.now());
  }

  /// 日付をタップしたとき: 日付の選択画面を出す
  Future<void> _pickDay() async {
    final p = AppPalette.of(context);
    var picked = _day;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Material(
        color: p.surface,
        child: SizedBox(
          height: 300,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    '完了',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _day,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (value) => picked = value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!DateUtils.isSameDay(picked, _day)) _showDay(picked);
  }

  /// 「記録しました」の「詳細」: お知らせを閉じてから、入力画面を出す
  void _editJustRecorded(CareRecord record) {
    _quick.dismiss();
    editRecordDetail(context, _repository, record);
  }

  /// 例: 2026/11/13(金)
  String _dayText(DateTime d) =>
      '${d.year}/${two(d.month)}/${two(d.day)}(${_weekdays[d.weekday - 1]})';

  Widget _pageFor(RecordCategory category, RecordsPageData data) =>
      switch (category) {
        RecordCategory.feeding => FeedingPage(data: data),
        RecordCategory.sleep => SleepPage(data: data),
        RecordCategory.excretion => ExcretionPage(data: data),
        RecordCategory.meal => MealPage(data: data),
        RecordCategory.care => CarePage(data: data),
      };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _DateBar(
            text: _dayText(_day),
            isToday: DateUtils.isSameDay(_day, DateTime.now()),
            onMove: _moveDay,
            onPick: _pickDay,
            onReminder: () => openReminderSettings(context),
            onAddMissed: () => _tools.addMissed(context),
          ),
          _CategoryTabBar(controller: _tabs),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: JustRecordedBanner(
              controller: _quick,
              onEditDetail: _editJustRecorded,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CareRecord>>(
              stream: _recent,
              builder: (context, recent) => StreamBuilder<List<CareRecord>>(
                stream: _dayStream,
                builder: (context, day) {
                  final data = RecordsPageData(
                    tools: _tools,
                    recent: recent.data ?? const [],
                    dayRecords: day.data ?? const [],
                  );
                  return TabBarView(
                    controller: _tabs,
                    children: [
                      for (final c in RecordCategory.values) _pageFor(c, data),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 一番上の日付と、右端の2つのアイコン。
/// 「◀ 2026/11/13(金) ▾ ▶」の真ん中をタップすると日付を選べる。
/// ベル = 授乳のお知らせの設定、＋ = 押し忘れた記録の追加。
class _DateBar extends StatelessWidget {
  const _DateBar({
    required this.text,
    required this.isToday,
    required this.onMove,
    required this.onPick,
    required this.onReminder,
    required this.onAddMissed,
  });

  final String text;
  final bool isToday;
  final ValueChanged<int> onMove; // -1 = 前の日、+1 = 次の日
  final VoidCallback onPick;
  final VoidCallback onReminder;
  final VoidCallback onAddMissed;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    // お知らせがオンのときは、ベルを塗りつぶして金色にする
    final reminderOn = NursingReminderScope.of(context).settings.enabled;

    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BarIcon(
                label: '前の日',
                icon: CupertinoIcons.chevron_left,
                onTap: () => onMove(-1),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onPick,
                child: Row(
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      CupertinoIcons.arrowtriangle_down_fill,
                      size: 11,
                      color: p.textSecondary,
                    ),
                  ],
                ),
              ),
              _BarIcon(
                label: '次の日',
                icon: CupertinoIcons.chevron_right,
                onTap: isToday ? null : () => onMove(1),
              ),
            ],
          ),
        ),
        _BarIcon(
          label: '授乳のお知らせ',
          icon: reminderOn ? CupertinoIcons.bell_fill : CupertinoIcons.bell,
          color: reminderOn ? p.accent : null,
          onTap: onReminder,
        ),
        _BarIcon(
          label: '押し忘れを追加',
          icon: CupertinoIcons.plus,
          onTap: onAddMissed,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// 日付バーのアイコン。[onTap] が null のときは薄くして押せなくする
class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String label; // 読み上げ用
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? CupertinoTheme.of(context).primaryColor;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 44,
          child: Center(
            child: Icon(
              icon,
              size: 21,
              color: onTap == null
                  ? iconColor.withValues(alpha: 0.3)
                  : iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// 横に並ぶカテゴリのタブ。選んでいるものに、金色の下線
class _CategoryTabBar extends StatelessWidget {
  const _CategoryTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ColoredBox(
      color: p.surface,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        labelColor: p.textPrimary,
        unselectedLabelColor: p.textSecondary,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: p.accent,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabs: [for (final c in RecordCategory.values) Tab(text: c.title)],
      ),
    );
  }
}

// ============================================================
//  2. ページに渡すデータと道具
// ============================================================

/// ページの中の部品が使う道具（保存・編集・ワンタップ記録）
class RecordsTools {
  const RecordsTools({
    required this.repository,
    required this.quick,
    required this.showToday,
  });

  final RecordRepository repository;
  final QuickRecordController quick;
  final VoidCallback showToday;

  /// 記録ボタンが押されたときの共通処理。別の日を見ていたら、今日に戻してから記録する
  Future<void> run(BuildContext context, QuickAction action) {
    showToday();
    return runQuickAction(
      context,
      action: action,
      repository: repository,
      quick: quick,
    );
  }

  Future<void> editDetail(BuildContext context, CareRecord record) =>
      editRecordDetail(context, repository, record);

  Future<void> editTiming(BuildContext context, CareRecord record) async {
    final id = record.id;
    if (id == null) return;
    final timing = await showRecordTimingSheet(
      context,
      title: '${record.type.label}の時刻を変更',
      type: record.type,
      initialEndedAt: record.endedAt,
      initialDuration: record.duration,
    );
    if (timing == null) return;
    await repository.updateTiming(
      id,
      endedAt: timing.endedAt,
      duration: timing.duration,
    );
  }

  void delete(CareRecord record) {
    final id = record.id;
    if (id != null) repository.delete(id);
  }

  /// 押し忘れの追加: 種類を選ぶ → 時刻を選ぶ →（授乳なら）母乳・ミルク・量を入力
  Future<void> addMissed(BuildContext context) async {
    final type = await showCupertinoModalPopup<RecordType>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('押し忘れた記録を追加'),
        actions: [
          for (final t in const [RecordType.nursing, RecordType.sleep])
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(t),
              child: Text(t.label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('キャンセル'),
        ),
      ),
    );
    if (type == null || !context.mounted) return;

    final timing = await showRecordTimingSheet(
      context,
      title: '${type.label}を追加',
      type: type,
    );
    if (timing == null) return;

    final id = await repository.add(
      CareRecord(
        type: type,
        endedAt: timing.endedAt,
        duration: timing.duration,
      ),
    );
    if (id == null || type != RecordType.nursing || !context.mounted) return;

    // 授乳は、続けて「母乳・ミルク・量」も入力できる（やめてもよい）
    final detail = await showNursingDetailSheet(context);
    if (detail != null) await repository.updateFields(id, {'detail': detail});
  }
}

/// 各ページに渡す、いまのデータ
class RecordsPageData {
  const RecordsPageData({
    required this.tools,
    required this.recent,
    required this.dayRecords,
  });

  final RecordsTools tools;

  /// 直近の記録（新しい順）。「前回の〇〇から」に使う
  final List<CareRecord> recent;

  /// 選んでいる日の記録（全カテゴリ）
  final List<CareRecord> dayRecords;

  /// 選んでいる日の、そのカテゴリの記録
  List<CareRecord> recordsOf(RecordCategory category) =>
      dayRecords.where(category.includes).toList();
}

// ============================================================
//  3. カテゴリページの共通の見た目
// ============================================================

/// 1つのタブのページ。上から「経過時間サマリー → 記録ボタン → 今日の回数 → グラフ → 履歴」。
/// 記録ボタンがないページは [actions] を省略する。
class CategoryPage extends StatelessWidget {
  const CategoryPage({
    super.key,
    required this.category,
    required this.data,
    required this.summaryItems,
    this.actions,
    this.extras,
    this.labelOf,
  });

  final RecordCategory category;
  final RecordsPageData data;
  final List<SummaryItem> summaryItems;

  /// 記録ボタンなど、サマリーのすぐ下に置くもの
  final Widget? actions;

  /// グラフなど、回数の下に置くもの
  final Widget? extras;

  /// 履歴の行の名前を変えたいとき（食事ページで、ミルクの授乳を「ミルク」と出す）
  final String Function(CareRecord)? labelOf;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final tools = data.tools;
    final records = data.recordsOf(category);
    final actions = this.actions;
    final extras = this.extras;

    return ListView(
      key: PageStorageKey<String>(category.name), // タブを行き来しても、スクロール位置を覚える
      padding: const EdgeInsets.only(top: 16, bottom: 48),
      children: [
        if (summaryItems.isNotEmpty) ...[
          _Gutter(
            child: ElapsedSummaryCard(items: summaryItems, recent: data.recent),
          ),
          const SizedBox(height: 28),
        ],
        if (actions != null) ...[
          _Gutter(child: actions),
          const SizedBox(height: 32),
        ],
        _Gutter(child: StatsRow(items: categoryStats(category, records))),
        if (extras != null) ...[
          const SizedBox(height: 28),
          _Gutter(child: extras),
        ],
        const SizedBox(height: 28),
        _Gutter(
          child: records.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'この日の記録はありません',
                      style: TextStyle(fontSize: 14, color: p.textSecondary),
                    ),
                  ),
                )
              : DayRecordList(
                  records: records,
                  labelOf: labelOf,
                  onEditDetail: (r) => tools.editDetail(context, r),
                  onEditTiming: (r) => tools.editTiming(context, r),
                  onDelete: tools.delete,
                ),
        ),
      ],
    );
  }
}

/// ページ全体で、左右の余白をそろえる
class _Gutter extends StatelessWidget {
  const _Gutter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: child,
  );
}

// ============================================================
//  4. 5つのカテゴリページ
// ============================================================

/// 授乳・ミルク。リアルタイムの記録はマップ画面で行い、ここは「ふり返り」。
class FeedingPage extends StatelessWidget {
  const FeedingPage({super.key, required this.data});

  final RecordsPageData data;

  @override
  Widget build(BuildContext context) {
    return CategoryPage(
      category: RecordCategory.feeding,
      data: data,
      summaryItems: [
        SummaryItem(
          label: '前回の母乳',
          type: RecordType.nursing,
          breast: true,
          matches: (r) => r.countsAsBreastfeeding,
        ),
        SummaryItem(
          label: '前回のミルク',
          type: RecordType.nursing,
          matches: (r) => r.isMilk,
        ),
      ],
      extras: RecordChartSection(
        series: [
          ChartSeries(
            label: '母乳',
            type: RecordType.nursing,
            breast: true,
            matches: (r) => r.countsAsBreastfeeding,
          ),
          ChartSeries(
            label: 'ミルク',
            type: RecordType.nursing,
            matches: (r) => r.isMilk,
            value: (r) => r.amountMl.toDouble(),
            unit: 'ml',
          ),
        ],
        records: data.recordsOf(RecordCategory.feeding),
        recent: data.recent,
      ),
    );
  }
}

/// 寝かしつけ。回数と、睡眠時間（分）のグラフを切り替えられる。
class SleepPage extends StatelessWidget {
  const SleepPage({super.key, required this.data});

  final RecordsPageData data;

  @override
  Widget build(BuildContext context) {
    return CategoryPage(
      category: RecordCategory.sleep,
      data: data,
      summaryItems: [
        SummaryItem(
          label: '前回の寝かしつけ',
          type: RecordType.sleep,
          matches: (r) => r.type == RecordType.sleep,
        ),
      ],
      extras: RecordChartSection(
        series: [
          ChartSeries(
            label: '回数',
            type: RecordType.sleep,
            matches: (r) => r.type == RecordType.sleep,
          ),
          ChartSeries(
            label: '所要時間',
            type: RecordType.sleep,
            matches: (r) => r.type == RecordType.sleep,
            value: (r) => r.duration.inSeconds / 60,
            unit: '分',
          ),
        ],
        records: data.recordsOf(RecordCategory.sleep),
        recent: data.recent,
      ),
    );
  }
}

/// 排泄（おしっこ・うんち）。オムツ替えの目安になる「前回から」が一番上。
class ExcretionPage extends StatelessWidget {
  const ExcretionPage({super.key, required this.data});

  final RecordsPageData data;

  @override
  Widget build(BuildContext context) {
    return CategoryPage(
      category: RecordCategory.excretion,
      data: data,
      summaryItems: [
        SummaryItem(
          label: '前回のおしっこ',
          type: RecordType.pee,
          matches: (r) => r.type == RecordType.pee,
        ),
        SummaryItem(
          label: '前回のうんち',
          type: RecordType.poop,
          matches: (r) => r.type == RecordType.poop,
        ),
      ],
      actions: QuickActionBar(
        actions: const [QuickAction.pee, QuickAction.poop],
        onAction: (action) => data.tools.run(context, action),
      ),
      extras: RecordChartSection(
        series: [
          ChartSeries.countOf(RecordType.pee),
          ChartSeries.countOf(RecordType.poop),
        ],
        records: data.recordsOf(RecordCategory.excretion),
        recent: data.recent,
      ),
    );
  }
}

/// 食事（離乳食・ミルク・おやつ）。
/// ミルクは授乳（ミルク）として保存されるので、授乳・ミルクのページにも出る。
class MealPage extends StatelessWidget {
  const MealPage({super.key, required this.data});

  final RecordsPageData data;

  @override
  Widget build(BuildContext context) {
    return CategoryPage(
      category: RecordCategory.meal,
      data: data,
      summaryItems: [
        SummaryItem(
          label: '前回の食事・ミルク',
          type: RecordType.babyFood,
          matches: RecordCategory.meal.includes,
        ),
      ],
      // 授乳として保存されたミルクを、「ミルク」の名前で出す
      labelOf: (r) => r.isMilk ? 'ミルク' : r.type.label,
      actions: QuickActionBar(
        actions: const [
          QuickAction.babyFood,
          QuickAction.milk,
          QuickAction.snack,
        ],
        onAction: (action) => data.tools.run(context, action),
      ),
    );
  }
}

/// 体調・ケア（体温・お風呂・病院・お薬）。
/// 上のサマリーは「前回の体温」だけ。いらなければ summaryItems を空にする。
class CarePage extends StatelessWidget {
  const CarePage({super.key, required this.data});

  final RecordsPageData data;

  @override
  Widget build(BuildContext context) {
    return CategoryPage(
      category: RecordCategory.care,
      data: data,
      summaryItems: [
        SummaryItem(
          label: '前回の体温',
          type: RecordType.temperature,
          matches: (r) => r.type == RecordType.temperature,
        ),
      ],
      actions: QuickActionBar(
        actions: const [
          QuickAction.temperature,
          QuickAction.bath,
          QuickAction.hospital,
        ],
        onAction: (action) => data.tools.run(context, action),
      ),
    );
  }
}
