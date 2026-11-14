import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/time_format.dart';

// ============================================================
//  1. 記録の種類と、1件の記録
// ============================================================

/// 記録の種別。Firestore には日本語の名前（label）を保存する（既存の記録と同じ形）。
enum RecordType {
  nursing('授乳', 'ml'),
  sleep('寝かしつけ', '分'),
  pee('おしっこ', '回'),
  poop('うんち', '回'),
  babyFood('離乳食', 'g'),
  snack('おやつ', '回'),
  temperature('体温', '℃'),
  hospital('病院', '回'),
  bath('お風呂', '回');

  const RecordType(this.label, this.unit);

  final String label;
  final String unit;

  /// 「回数」で数える種別か（グラフの縦軸を整数にするため）
  bool get isCount => unit == '回';

  /// 時間を測る種別か（押し忘れの追加・時刻の変更で、所要時間も入力する）
  bool get hasDuration => this == nursing || this == sleep;

  /// 保存された文字から種別を探す。日本語の名前でも、nursing のような名前でも読める。
  static RecordType? parse(Object? stored) =>
      values.where((t) => t.label == stored || t.name == stored).firstOrNull;

  /// グラフ・合計に使う値（授乳=ml、寝かしつけ=分、おしっこ等=回数）
  double valueOf(CareRecord r) => switch (this) {
    nursing => r.amountMl.toDouble(),
    sleep => r.duration.inSeconds / 60,
    pee || poop || snack || hospital || bath => 1,
    babyFood || temperature => r.value ?? 0,
  };
}

/// 1件の記録。新しい項目（value / attributes / note）は、すべて省略できる。
class CareRecord {
  const CareRecord({
    this.id,
    required this.type,
    required this.endedAt,
    this.duration = Duration.zero,
    this.detail = '',
    this.value,
    this.attributes = const {},
    this.note = '',
  });

  final String? id;
  final RecordType type;
  final DateTime endedAt;

  /// 計測した時間。ワンタップ・手動の記録は 0（時間なし）
  final Duration duration;

  /// 一覧に出す1行の要約（例: 「ミルク (80ml) • 完飲」「硬さ ふつう / 量 多め」）
  final String detail;

  /// 数値（体温 36.8、離乳食の量 30 など）
  final double? value;

  /// 選んだ状態（例: {'硬さ': 'ふつう', '量': '多め'}）
  final Map<String, String> attributes;

  /// 自由メモ
  final String note;

  bool get isInstant => duration == Duration.zero;

  DateTime get startedAt => endedAt.subtract(duration);

  /// 授乳の詳細文字列 "ミルク (80ml) • 完飲" から量を取り出す（昔の記録もこの形）
  int get amountMl =>
      int.tryParse(RegExp(r'(\d+)ml').firstMatch(detail)?.group(1) ?? '') ?? 0;

  /// 哺乳瓶での授乳か（詳細が「ミルク」「混合」で始まる授乳）。
  /// 食事ページにも表示し、「前回の食事・ミルク」の対象にする
  bool get isMilk =>
      type == RecordType.nursing &&
      (detail.startsWith('ミルク') || detail.startsWith('混合'));

  /// 保存する時間の形（"05:30"）。既存の記録と同じ
  static String encodeDuration(Duration d) =>
      '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';

  static CareRecord? fromMap(Map<String, dynamic> m, {String? id}) {
    final type = RecordType.parse(m['type']);
    final ts = (m['timestamp'] as Timestamp?)?.toDate();
    if (type == null || ts == null) return null; // 未知の種別・保存途中は無視

    final parts = (m['duration'] as String? ?? '00:00').split(':');
    final duration = parts.length == 2
        ? Duration(
            minutes: int.tryParse(parts[0]) ?? 0,
            seconds: int.tryParse(parts[1]) ?? 0,
          )
        : Duration.zero;

    final rawAttributes = m['attributes'];
    return CareRecord(
      id: id,
      type: type,
      endedAt: ts,
      duration: duration,
      detail: m['detail'] as String? ?? '',
      value: (m['value'] as num?)?.toDouble(),
      attributes: rawAttributes is Map
          ? {for (final e in rawAttributes.entries) '${e.key}': '${e.value}'}
          : const {},
      note: m['note'] as String? ?? '',
    );
  }

  /// 保存する形。時刻は端末の時刻を使う（通信待ちでも、すぐ一覧に出るように）。
  Map<String, dynamic> toMap() => {
    'type': type.label,
    'duration': encodeDuration(duration),
    'detail': detail,
    'timestamp': Timestamp.fromDate(endedAt),
    if (value != null) 'value': value,
    if (attributes.isNotEmpty) 'attributes': attributes,
    if (note.isNotEmpty) 'note': note,
  };
}

extension RecordAggregation on Iterable<CareRecord> {
  /// 開始時刻の「時」ごとに値を合計した24要素のリスト
  List<double> hourly(double Function(CareRecord) valueOf) {
    final buckets = List.filled(24, 0.0);
    for (final r in this) {
      buckets[r.startedAt.hour] += valueOf(r);
    }
    return buckets;
  }
}

// ============================================================
//  2. カテゴリ（記録タブのメニュー）
// ============================================================

/// 記録タブの4つのメニュー。どの記録がどのカテゴリに入るかを、ここで決める。
enum RecordCategory {
  feedingSleep('授乳・ねんね', '前回からの時間・ふり返り・押し忘れの追加'),
  excretion('排泄', 'おしっこ・うんち'),
  meal('食事', '離乳食・ミルク・おやつ'),
  care('体調・ケア', '体温・お風呂・病院・お薬');

  const RecordCategory(this.title, this.subtitle);

  final String title;
  final String subtitle;

  /// この記録が、このカテゴリのページに載るか
  bool includes(CareRecord r) => switch (this) {
    feedingSleep => r.type == RecordType.nursing || r.type == RecordType.sleep,
    excretion => r.type == RecordType.pee || r.type == RecordType.poop,
    // ミルク（哺乳瓶の授乳）は、授乳・ねんねと食事の両方に出る
    meal =>
      r.type == RecordType.babyFood || r.type == RecordType.snack || r.isMilk,
    care =>
      r.type == RecordType.temperature ||
          r.type == RecordType.bath ||
          r.type == RecordType.hospital,
  };
}

// ============================================================
//  3. その日の回数・量（画面に依存しない関数）
// ============================================================

/// 「ラベル + 値」の1組
class StatItem {
  const StatItem(this.label, this.value);

  final String label;
  final String value;
}

/// その日の、カテゴリごとの回数・量。[records] は、そのカテゴリの記録だけを渡す。
List<StatItem> categoryStats(
  RecordCategory category,
  List<CareRecord> records,
) {
  int count(bool Function(CareRecord) test) => records.where(test).length;
  int milkMl() =>
      records.where((r) => r.isMilk).fold(0, (sum, r) => sum + r.amountMl);

  return switch (category) {
    RecordCategory.feedingSleep => [
      StatItem('授乳', '${count((r) => r.type == RecordType.nursing)}回'),
      StatItem('ねんね', '${count((r) => r.type == RecordType.sleep)}回'),
      StatItem('ミルク', '${milkMl()}ml'),
    ],
    RecordCategory.excretion => [
      StatItem('おしっこ', '${count((r) => r.type == RecordType.pee)}回'),
      StatItem('うんち', '${count((r) => r.type == RecordType.poop)}回'),
    ],
    RecordCategory.meal => [
      StatItem('離乳食', '${count((r) => r.type == RecordType.babyFood)}回'),
      StatItem('ミルク', '${milkMl()}ml'),
      StatItem('おやつ', '${count((r) => r.type == RecordType.snack)}回'),
    ],
    RecordCategory.care => [
      StatItem('体温（最高）', _maxTemperature(records)),
      StatItem('お風呂', '${count((r) => r.type == RecordType.bath)}回'),
      StatItem('病院', '${count((r) => r.type == RecordType.hospital)}回'),
    ],
  };
}

String _maxTemperature(List<CareRecord> records) {
  final values = records
      .where((r) => r.type == RecordType.temperature && r.value != null)
      .map((r) => r.value!);
  if (values.isEmpty) return '—';
  return '${values.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}℃';
}

// ============================================================
//  4. 種別ごとの「詳細入力」の項目と、その結果
// ============================================================

/// 選ぶだけの入力（例: うんちの硬さ）
class ChoiceGroup {
  const ChoiceGroup(this.name, this.options);

  final String name;
  final List<String> options;
}

/// 数字を選ぶ入力（例: 体温 36.8℃）
class NumberField {
  const NumberField({
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.initial,
    this.decimals = 0,
  });

  final String label;
  final String unit;
  final double min, max, step, initial;
  final int decimals; // 小数点以下の桁数

  int get count => ((max - min) / step).round() + 1;

  /// ドラムの n 番目の値（浮動小数の誤差が出ないよう丸める）
  double valueAt(int index) =>
      double.parse((min + index * step).toStringAsFixed(decimals));

  int indexOf(double value) =>
      ((value - min) / step).round().clamp(0, count - 1);

  String format(double value) => value.toStringAsFixed(decimals);
}

/// 1つの種別の「詳細入力」の中身。すべて任意入力。
class RecordSpec {
  const RecordSpec({
    this.groups = const [],
    this.number,
    this.noteHint = 'メモ（任意）',
  });

  final List<ChoiceGroup> groups;
  final NumberField? number;
  final String noteHint;
}

extension RecordTypeSpec on RecordType {
  /// 詳細入力の項目。授乳だけは専用の入力画面があるので null
  RecordSpec? get spec => switch (this) {
    RecordType.nursing => null,
    RecordType.sleep => const RecordSpec(),
    RecordType.pee => const RecordSpec(
      groups: [
        ChoiceGroup('量', ['少なめ', 'ふつう', '多め']),
      ],
    ),
    RecordType.poop => const RecordSpec(
      groups: [
        ChoiceGroup('硬さ', ['かため', 'ふつう', 'やわらかい', '水っぽい']),
        ChoiceGroup('量', ['少なめ', 'ふつう', '多め']),
      ],
    ),
    RecordType.babyFood => const RecordSpec(
      groups: [
        ChoiceGroup('食べっぷり', ['完食', '半分くらい', '少し', '食べなかった']),
      ],
      number: NumberField(
        label: '量',
        unit: 'g',
        min: 5,
        max: 300,
        step: 5,
        initial: 30,
      ),
      noteHint: 'メニュー（例: おかゆ・にんじん）',
    ),
    RecordType.snack => const RecordSpec(noteHint: 'おやつの内容（例: ボーロ）'),
    RecordType.temperature => const RecordSpec(
      number: NumberField(
        label: '体温',
        unit: '℃',
        min: 35.0,
        max: 42.0,
        step: 0.1,
        initial: 36.5,
        decimals: 1,
      ),
    ),
    RecordType.hospital => const RecordSpec(
      groups: [
        ChoiceGroup('内容', ['受診', 'お薬', '予防接種']),
      ],
      noteHint: '病名・薬の名前など',
    ),
    RecordType.bath => const RecordSpec(
      groups: [
        ChoiceGroup('様子', ['ごきげん', 'ふつう', 'いやがった']),
      ],
    ),
  };
}

/// 詳細入力の結果（数値・選んだ状態・メモ）
class RecordDetail {
  const RecordDetail({this.value, this.attributes = const {}, this.note = ''});

  factory RecordDetail.fromRecord(CareRecord r) =>
      RecordDetail(value: r.value, attributes: r.attributes, note: r.note);

  final double? value;
  final Map<String, String> attributes;
  final String note;

  /// 一覧に出す1行の要約。例: 「36.8℃」「硬さ ふつう / 量 多め • 緑っぽい」
  String summary(RecordType type) {
    final number = type.spec?.number;
    final parts = [
      if (value != null && number != null)
        '${number.format(value!)}${number.unit}',
      for (final e in attributes.entries) '${e.key} ${e.value}',
    ];
    return [parts.join(' / '), note].where((s) => s.isNotEmpty).join(' • ');
  }

  /// 既存の記録を書き換えるときの項目。空にした項目は削除する
  Map<String, dynamic> toFields(RecordType type) => {
    'detail': summary(type),
    'value': value ?? FieldValue.delete(),
    'attributes': attributes.isEmpty ? FieldValue.delete() : attributes,
    'note': note.isEmpty ? FieldValue.delete() : note,
  };
}
