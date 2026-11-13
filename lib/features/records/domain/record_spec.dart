import 'package:cloud_firestore/cloud_firestore.dart';
import 'care_record.dart';

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
