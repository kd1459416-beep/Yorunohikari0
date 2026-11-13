import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/time_format.dart';

/// 記録画面での置き場所。メインは上に常時表示、サブは「＋その他」から選ぶ。
enum RecordGroup { main, sub }

/// 記録の種別。
/// Firestore には日本語の名前（label）を保存する。既存の「授乳」「寝かしつけ」の
/// 記録と同じ形のまま、新しい種別を足している。
enum RecordType {
  // ---- メイン（ワンタップで記録）----
  nursing('授乳', 'ml', RecordGroup.main),
  sleep('寝かしつけ', '分', RecordGroup.main),
  pee('おしっこ', '回', RecordGroup.main),
  poop('うんち', '回', RecordGroup.main),

  // ---- サブ（「＋その他」から入力して記録）----
  babyFood('離乳食', 'g', RecordGroup.sub),
  temperature('体温', '℃', RecordGroup.sub),
  hospital('病院', '回', RecordGroup.sub),
  bath('お風呂', '回', RecordGroup.sub);

  const RecordType(this.label, this.unit, this.group);

  final String label;
  final String unit;
  final RecordGroup group;

  static const mainTypes = [nursing, sleep, pee, poop];
  static const subTypes = [babyFood, temperature, hospital, bath];

  /// グラフで見られる種別
  static const chartTypes = [nursing, sleep, pee, poop];

  /// 「回数」で数える種別か（グラフの縦軸を整数にするため）
  bool get isCount => unit == '回';

  /// 保存された文字から種別を探す。日本語の名前でも、nursing のような名前でも読める。
  static RecordType? parse(Object? stored) =>
      values.where((t) => t.label == stored || t.name == stored).firstOrNull;

  /// グラフ・合計に使う値（授乳=ml、寝かしつけ=分、おしっこ等=回数）
  double valueOf(CareRecord r) => switch (this) {
    nursing => r.amountMl.toDouble(),
    sleep => r.duration.inSeconds / 60,
    pee || poop || hospital || bath => 1,
    babyFood || temperature => r.value ?? 0,
  };
}

/// 1件の記録。
/// 新しく足した項目（value / attributes / note）は、すべて省略できる。
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

  /// 計測した時間。ワンタップの記録は 0（時間なし）
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

  /// 保存する形。種別は、これまでと同じく日本語の名前で書く。
  /// 時刻は端末の時刻を使う（通信待ちでも、すぐ一覧に出るように）。
  Map<String, dynamic> toMap() => {
    'type': type.label,
    'duration': '${two(duration.inMinutes)}:${two(duration.inSeconds % 60)}',
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
