import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/time_format.dart';

enum RecordType {
  nursing('授乳', 'ml'),
  sleep('寝かしつけ', '分');

  const RecordType(this.label, this.unit);
  final String label, unit;

  /// グラフに載せる値（授乳=ml、寝かしつけ=分）
  double valueOf(CareRecord r) => switch (this) {
    nursing => r.amountMl.toDouble(),
    sleep => r.duration.inSeconds / 60,
  };
}

class CareRecord {
  const CareRecord({
    this.id,
    required this.type,
    required this.endedAt,
    required this.duration,
    required this.detail,
  });

  final String? id;
  final RecordType type;
  final DateTime endedAt;
  final Duration duration;
  final String detail;

  DateTime get startedAt => endedAt.subtract(duration);

  /// 詳細文字列 "ミルク (80ml) • 完飲" から量を取り出す
  int get amountMl =>
      int.tryParse(RegExp(r'(\d+)ml').firstMatch(detail)?.group(1) ?? '') ?? 0;

  static CareRecord? fromMap(Map<String, dynamic> m, {String? id}) {
    final type = RecordType.values
        .where((t) => t.label == m['type'])
        .firstOrNull;
    final ts = (m['timestamp'] as Timestamp?)?.toDate();
    if (type == null || ts == null) return null; // 旧形式・保存途中は無視

    final parts = (m['duration'] as String? ?? '00:00').split(':');
    final duration = parts.length == 2
        ? Duration(
            minutes: int.tryParse(parts[0]) ?? 0,
            seconds: int.tryParse(parts[1]) ?? 0,
          )
        : Duration.zero;
    return CareRecord(
      id: id,
      type: type,
      endedAt: ts,
      duration: duration,
      detail: m['detail'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.label,
    'duration': '${two(duration.inMinutes)}:${two(duration.inSeconds % 60)}',
    'detail': detail,
    'timestamp': FieldValue.serverTimestamp(),
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
