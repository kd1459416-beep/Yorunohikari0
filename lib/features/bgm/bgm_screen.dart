import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/inset_section.dart';
import 'bgm_controller.dart';
import 'bgm_icon.dart';
import 'sound_data.dart';

const _timerOptions = [5, 15, 30, 60, 120, 240, 0]; // 0 = オフ

class BgmScreen extends StatefulWidget {
  const BgmScreen({super.key, required this.controller});

  final BgmController controller;

  @override
  State<BgmScreen> createState() => _BgmScreenState();
}

class _BgmScreenState extends State<BgmScreen> {
  late final Future<List<SoundItem>> _sounds = loadSounds();

  BgmController get _c => widget.controller;

  void _showTimerSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('スリープタイマー'),
        actions: [
          for (final m in _timerOptions)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _c.setTimer(m);
              },
              child: Text(m == 0 ? 'オフ（ループ再生）' : '$m分'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SafeArea(
      child: FutureBuilder<List<SoundItem>>(
        future: _sounds,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '音源を読み込めませんでした',
                style: TextStyle(color: p.textSecondary),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CupertinoActivityIndicator());
          }

          final grouped = <String, List<SoundItem>>{};
          for (final s in snapshot.data!) {
            grouped.putIfAbsent(s.category, () => []).add(s);
          }

          return ListenableBuilder(
            listenable: _c,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 16, 16),
                  child: Text(
                    'BGM',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                InsetSection(
                  children: [
                    InsetTile(
                      title: 'スリープタイマー',
                      onTap: _showTimerSheet,
                      trailing: ValueListenableBuilder<Duration>(
                        valueListenable: _c.remaining,
                        builder: (_, d, _) => Text(
                          _c.timerActive ? BgmController.format(d) : 'オフ',
                          style: TextStyle(
                            fontSize: 15,
                            color: _c.timerActive ? p.accent : p.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                for (final MapEntry(:key, :value) in grouped.entries)
                  InsetSection(
                    header: key,
                    children: [
                      for (final s in value)
                        _SoundTile(
                          item: s,
                          playing: _c.isPlayingItem(s),
                          onTap: () => _c.toggle(s),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SoundTile extends StatelessWidget {
  const _SoundTile({
    required this.item,
    required this.playing,
    required this.onTap,
  });

  final SoundItem item;
  final bool playing;
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
            // 再生中は少し大きく、背景も濃くなる
            AnimatedScale(
              scale: playing ? 1.08 : 1,
              duration: const Duration(milliseconds: 150),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: playing ? 0.32 : 0.16),
                ),
                child: Center(child: BgmIcon(kind: kind, dark: true)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: playing ? FontWeight.w600 : FontWeight.w400,
                  color: p.textPrimary,
                ),
              ),
            ),
            Icon(
              playing
                  ? CupertinoIcons.speaker_2_fill
                  : CupertinoIcons.play_fill,
              size: 18,
              color: playing ? p.accent : p.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
