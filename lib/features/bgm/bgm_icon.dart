import 'package:flutter/material.dart';

/// カテゴリごとのアイコン素材と色定義
enum BgmIconKind {
  musicBox(
    Icons.star_rounded,
    Color(0xFFF5C15C),
    Color(0xFFB98A00),
  ), // オルゴール1 = 星
  hospital(
    Icons.local_hospital_rounded,
    Color.fromARGB(255, 226, 125, 122),
    Color.fromARGB(255, 240, 234, 234),
  ), // オルゴール2 = 病院・歯医者
  night(
    Icons.hotel_rounded,
    Color(0xFF9FA8DA),
    Color(0xFF3F51B5),
  ), // オルゴール3 = ベッド（すやすや）
  leaf(Icons.spa_rounded, Color(0xFF7BC8A4), Color(0xFF2F8F67)), // 自然 = 葉っぱ
  heart(
    Icons.favorite_rounded,
    Color(0xFFF29BB5),
    Color(0xFFD0527A),
  ), // 心臓音 = ハート
  bird(Icons.flutter_dash, Color(0xFF7DD3FC), Color(0xFF0E86C7)), // 鳥のさえずり = 鳥
  womb(
    Icons.graphic_eq_rounded,
    Color(0xFFA5A8F0),
    Color(0xFF5B5FC7),
  ), // 胎内音 = 波形
  wave(Icons.waves_rounded, Color(0xFF67D4D4), Color(0xFF1A8F8F)); // その他 = 波

  const BgmIconKind(this.iconData, this._dark, this._light);

  final IconData iconData;
  final Color _dark, _light;

  Color color(bool dark) => dark ? _dark : _light;

  /// カテゴリ名から適切な BgmIconKind を判定して返す
  static BgmIconKind of(String category) {
    if (category == 'オルゴール1') return musicBox;
    if (category == 'オルゴール2') return hospital;
    if (category == 'オルゴール3') return night;
    if (category.contains('心臓')) return heart;
    if (category.contains('鳥')) return bird;
    if (category.contains('自然')) return leaf;
    if (category.contains('胎内')) return womb;
    return wave;
  }
}

/// BGMカテゴリのアイコン表示ウィジェット
class BgmIcon extends StatelessWidget {
  const BgmIcon({
    super.key,
    required this.kind,
    required this.dark,
    this.size = 24.0,
  });

  final BgmIconKind kind;
  final bool dark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(kind.iconData, size: size, color: kind.color(dark));
  }
}
