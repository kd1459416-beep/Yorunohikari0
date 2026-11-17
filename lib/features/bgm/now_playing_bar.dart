import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import 'bgm_controller.dart';
import 'bgm_icon.dart';
import 'sound_data.dart';

/// 画面下部のプレイヤー。曲が選ばれているときだけ、下からせり上がって表示する。
class NowPlayingBar extends StatelessWidget {
  const NowPlayingBar({super.key, required this.controller});

  final BgmController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final song = controller.current;
        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: song == null
              ? const SizedBox(width: double.infinity) // 高さ0 = 非表示
              : _PlayerCard(
                  song: song,
                  isPlaying: controller.isPlaying,
                  onTogglePlay: controller.togglePlayPause,
                  onPrevious: controller.playPrevious,
                  onNext: controller.playNext,
                ),
        );
      },
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.song,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onPrevious,
    required this.onNext,
  });

  final SoundItem song;
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final kind = BgmIconKind.of(song.category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              BgmIcon(kind: kind, dark: dark, size: 28),
              const SizedBox(width: 12),
              // 曲名とカテゴリ。長い曲名は省略記号で切る
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    Text(
                      song.category,
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              _ControlButton(
                icon: CupertinoIcons.backward_fill,
                color: p.textPrimary,
                size: 22,
                onTap: onPrevious,
              ),
              // 再生/一時停止のアイコンは、ふわっと入れ替える
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: _ControlButton(
                  key: ValueKey(isPlaying),
                  icon: isPlaying
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  color: p.accent,
                  size: 30,
                  onTap: onTogglePlay,
                ),
              ),
              _ControlButton(
                icon: CupertinoIcons.forward_fill,
                color: p.textPrimary,
                size: 22,
                onTap: onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 押しやすい 44pt 四方のアイコンボタン
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox.square(
        dimension: 44,
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}
