import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/inset_section.dart';
import '../map/presentation/nursing_detail_sheet.dart';
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

  // 画面の一番上で1回だけ取得して、4つのページに渡す
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
        RecordCategory.feedingSleep => FeedingSleepPage(data: data),
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

/// 一番上の日付。「◀ 2026/11/13(金) ▾ ▶」。真ん中をタップすると日付を選べる
class _DateBar extends StatelessWidget {
  const _DateBar({
    required this.text,
    required this.isToday,
    required this.onMove,
    required this.onPick,
  });

  final String text;
  final bool isToday;
  final ValueChanged<int> onMove; // -1 = 前の日、+1 = 次の日
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          onPressed: () => onMove(-1),
          child: const Icon(CupertinoIcons.chevron_left, size: 20),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPick,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          onPressed: isToday ? null : () => onMove(1),
          child: const Icon(CupertinoIcons.chevron_right, size: 20),
        ),
      ],
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
class CategoryPage extends StatelessWidget {
  const CategoryPage({
    super.key,
    required this.category,
    required this.data,
    required this.summaryItems,
    required this.actions,
    this.extras,
    this.labelOf,
  });

  final RecordCategory category;
  final RecordsPageData data;
  final List<SummaryItem> summaryItems;

  /// 記録ボタンなど、サマリーのすぐ下に置くもの
  final Widget actions;

  /// グラフなど、回数の下に置くもの
  final Widget? extras;

  /// 履歴の行の名前を変えたいとき（食事ページで、ミルクの授乳を「ミルク」と出す）
  final String Function(CareRecord)? labelOf;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final tools = data.tools;
    final records = data.recordsOf(category);

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
        _Gutter(child: actions),
        const SizedBox(height: 32),
        _Gutter(child: StatsRow(items: categoryStats(category, records))),
        if (extras != null) ...[
          const SizedBox(height: 28),
          _Gutter(child: extras!),
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
//  4. 4つのカテゴリページ
// ============================================================

/// 授乳・ねんね。リアルタイムの記録はマップ画面で行い、ここは「ふり返り」と「押し忘れの追加」。
class FeedingSleepPage extends StatelessWidget {
  const FeedingSleepPage({super.key, required this.data});

  final RecordsPageData data;

  /// 押し忘れの追加: 種類を選ぶ → 時刻を選ぶ →（授乳なら）種類・量を入力
  Future<void> _addMissed(BuildContext context) async {
    final repository = data.tools.repository;

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

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return CategoryPage(
      category: RecordCategory.feedingSleep,
      data: data,
      summaryItems: [
        SummaryItem(
          label: '前回の授乳',
          type: RecordType.nursing,
          matches: (r) => r.type == RecordType.nursing,
        ),
        SummaryItem(
          label: '前回の寝かしつけ',
          type: RecordType.sleep,
          matches: (r) => r.type == RecordType.sleep,
        ),
      ],
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text(
              '授乳・寝かしつけは、マップ画面で光を灯して記録します。',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: p.textSecondary,
              ),
            ),
          ),
          InsetSection(
            margin: EdgeInsets.zero,
            children: [
              const ReminderSettingsTile(),
              InsetTile(title: '押し忘れを追加', onTap: () => _addMissed(context)),
            ],
          ),
        ],
      ),
      extras: HourlyChartSection(
        types: const [RecordType.nursing, RecordType.sleep],
        records: data.recordsOf(RecordCategory.feedingSleep),
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
      extras: HourlyChartSection(
        types: const [RecordType.pee, RecordType.poop],
        records: data.recordsOf(RecordCategory.excretion),
      ),
    );
  }
}

/// 食事（離乳食・ミルク・おやつ）。
/// ミルクは授乳（ミルク）として保存されるので、授乳・ねんねのページにも出る。
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
