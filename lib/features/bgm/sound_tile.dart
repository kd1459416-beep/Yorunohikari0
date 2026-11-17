import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import 'bgm_icon.dart';
import 'sound_data.dart';

/// 曲の1行。左にカテゴリのイラスト、右に再生状態のアイコン。
class SoundTile extends StatelessWidget {
  const SoundTile({
    super.key,
    required this.item,
    required this.isPlaying,
    required this.onTap,
  });

  final SoundItem item;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final kind = BgmIconKind.of(item.category);
    final color = kind.color(dark);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // 再生中は、少し大きく・背景も濃くなる
            AnimatedScale(
              scale: isPlaying ? 1.08 : 1,
              duration: const Duration(milliseconds: 150),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: isPlaying ? 0.32 : 0.16),
                ),
                child: Center(
                  child: Center(
                    child: BgmIcon(kind: kind, dark: dark),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w400,
                  color: p.textPrimary,
                ),
              ),
            ),
            Icon(
              isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
              size: 22,
              color: isPlaying ? p.accent : p.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
