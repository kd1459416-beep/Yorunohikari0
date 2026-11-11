import 'package:flutter/material.dart';

@immutable
class _Stop {
  const _Stop(this.minutes, this.color);
  final double minutes;
  final Color color;
}

/// 灯りの経過時間 → 色。区間ごとに滑らかに補間する。
abstract final class PresenceColors {
  // ダーク地図用
  static const _dark = [
    _Stop(0, Color(0xFFFCE788)), //  0〜30分: ゴールド（ベース）
    _Stop(30, Color(0xFFFCE788)),
    _Stop(60, Color(0xFFF5C15C)), // 30〜90分: ウォームゴールド
    _Stop(90, Color(0xFFE8803A)), //          → ディープオレンジ
    _Stop(105, Color(0xFF5B5FC7)), // 90分〜: ナイトパープル寄りのブルー（以降ずっと同じ）
  ];

  // ライト地図用（白地でも見えるよう少し深め）
  static const _light = [
    _Stop(0, Color(0xFFD9A400)),
    _Stop(30, Color(0xFFD9A400)),
    _Stop(60, Color(0xFFE08A00)),
    _Stop(90, Color(0xFFD25A1E)),
    _Stop(105, Color(0xFF4B4FB3)),
  ];

  static Color at(Duration age, {required bool dark}) {
    final stops = dark ? _dark : _light;
    final m = age.inSeconds / 60;
    if (m <= stops.first.minutes) return stops.first.color;
    if (m >= stops.last.minutes) return stops.last.color; // 消灯せず、この色のまま
    for (var i = 1; i < stops.length; i++) {
      final b = stops[i];
      if (m <= b.minutes) {
        final a = stops[i - 1];
        final t = (m - a.minutes) / (b.minutes - a.minutes);
        return Color.lerp(a.color, b.color, t)!;
      }
    }
    return stops.last.color;
  }
}
