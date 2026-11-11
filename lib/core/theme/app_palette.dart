import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.hairline,
    required this.textPrimary,
    required this.textSecondary,
    required this.nursing,
    required this.sleeping,
    required this.glow,
  });

  /// ダーク。[depth] 0 = 青みのある紺 〜 1 = ほぼ黒
  factory AppPalette.dark({double depth = 0.5}) => AppPalette(
    background: Color.lerp(
      const Color(0xFF0B132B),
      const Color(0xFF000000),
      depth,
    )!,
    surface: Color.lerp(
      const Color(0xFF16264C),
      const Color(0xFF0A0A0C),
      depth,
    )!,
    hairline: const Color(0x1FFFFFFF),
    textPrimary: const Color(0xFFF1F5F9),
    textSecondary: const Color(0x99F1F5F9),
    nursing: const Color(0xFFFCE788), // シャンパンゴールド
    sleeping: const Color(0xFF8B9CF0),
    glow: const Color(0xFF7DD3FC), // シアンの微光
  );

  /// ライト。[warmth] 0 = やわらかい白 〜 1 = 濃いクリーム（純白は使わない）
  factory AppPalette.light({double warmth = 0.5}) => AppPalette(
    background: Color.lerp(
      const Color(0xFFF1EFEA),
      const Color(0xFFE9DEC6),
      warmth,
    )!,
    surface: Color.lerp(
      const Color(0xFFF9F7F2),
      const Color(0xFFF3EAD5),
      warmth,
    )!,
    hairline: const Color(0x1F3A2E1A),
    textPrimary: const Color(0xFF2B2620), // 黒ではなく暖かい焦げ茶
    textSecondary: const Color(0x992B2620),
    nursing: const Color(0xFFB98A00), // クリーム地で読める深めのゴールド
    sleeping: const Color(0xFF6D5BD0),
    glow: const Color(0xFF0EA5E9),
  );

  final Color background, surface, hairline;
  final Color textPrimary, textSecondary;
  final Color nursing, sleeping, glow;

  Color get accent => nursing;

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? hairline,
    Color? textPrimary,
    Color? textSecondary,
    Color? nursing,
    Color? sleeping,
    Color? glow,
  }) => AppPalette(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    hairline: hairline ?? this.hairline,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    nursing: nursing ?? this.nursing,
    sleeping: sleeping ?? this.sleeping,
    glow: glow ?? this.glow,
  );

  /// テーマ切替のアニメーション中に呼ばれる
  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      nursing: Color.lerp(nursing, other.nursing, t)!,
      sleeping: Color.lerp(sleeping, other.sleeping, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
    );
  }
}
