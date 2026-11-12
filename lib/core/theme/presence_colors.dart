import 'package:flutter/material.dart';

@immutable
class _Stop {
  const _Stop(this.minutes, this.color);
  final double minutes;
  final Color color;
}

/// 灯りの経過時間 → 色。区間ごとに滑らかに補間する。
/// 授乳: ゴールド → 橙 → 深い青 / 寝かしつけ: 明るい青紫 → 深いインディゴ
abstract final class PresenceColors {
  // ---- 授乳 ----
  static const _nursingDark = [
    _Stop(0, Color(0xFFFCE788)), //  0〜30分: ゴールド
    _Stop(30, Color(0xFFFCE788)),
    _Stop(60, Color(0xFFF5C15C)), // 30〜90分: ウォームゴールド
    _Stop(90, Color(0xFFE8803A)), //          → ディープオレンジ
    _Stop(105, Color(0xFF5B5FC7)), // 90分〜: 深い青（以降ずっと同じ）
  ];
  static const _nursingLight = [
    _Stop(0, Color(0xFFD9A400)),
    _Stop(30, Color(0xFFD9A400)),
    _Stop(60, Color(0xFFE08A00)),
    _Stop(90, Color(0xFFD25A1E)),
    _Stop(105, Color(0xFF4B4FB3)),
  ];

  // ---- 寝かしつけ（青紫の濃淡） ----
  static const _sleepingDark = [
    _Stop(0, Color(0xFF9D8CFF)), //  0〜30分: 明るい青紫
    _Stop(30, Color(0xFF9D8CFF)),
    _Stop(60, Color(0xFF7B6CF6)), // 30〜90分: 少し落ち着いた青紫
    _Stop(90, Color(0xFF5B4FD6)),
    _Stop(105, Color(0xFF3F3A9A)), // 90分〜: 深いインディゴ（以降ずっと同じ）
  ];
  static const _sleepingLight = [
    _Stop(0, Color(0xFF7C6CF0)),
    _Stop(30, Color(0xFF7C6CF0)),
    _Stop(60, Color(0xFF6554DC)),
    _Stop(90, Color(0xFF4F42C0)),
    _Stop(105, Color(0xFF342E8C)),
  ];

  static List<_Stop> _stopsFor({required bool dark, required bool sleeping}) {
    if (sleeping) return dark ? _sleepingDark : _sleepingLight;
    return dark ? _nursingDark : _nursingLight;
  }

  /// [age] 経過時間、[dark] ダーク地図か、[sleeping] 寝かしつけの灯りか
  static Color at(Duration age, {required bool dark, bool sleeping = false}) {
    final stops = _stopsFor(dark: dark, sleeping: sleeping);
    final minutes = age.inSeconds / 60;
    if (minutes <= stops.first.minutes) return stops.first.color;
    if (minutes >= stops.last.minutes) return stops.last.color; // 消灯せず、この色のまま

    for (var i = 1; i < stops.length; i++) {
      final next = stops[i];
      if (minutes <= next.minutes) {
        final prev = stops[i - 1];
        final t = (minutes - prev.minutes) / (next.minutes - prev.minutes);
        return Color.lerp(prev.color, next.color, t)!;
      }
    }
    return stops.last.color;
  }
}
