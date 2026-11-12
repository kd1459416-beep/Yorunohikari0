import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/inset_section.dart';
import 'bgm_controller.dart';
import 'now_playing_bar.dart';
import 'sleep_timer_button.dart';
import 'sound_tile.dart';
import 'sound_data.dart';

/// BGMタブ。上から「見出し + タイマー」「曲の一覧」「プレイヤー」。
class BgmScreen extends StatelessWidget {
  const BgmScreen({super.key, required this.controller});

  final BgmController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _BgmHeader(controller: controller),
          Expanded(child: _SoundList(controller: controller)),
          NowPlayingBar(controller: controller),
        ],
      ),
    );
  }
}

/// 「BGM」の見出しと、右上のタイマーボタン
class _BgmHeader extends StatelessWidget {
  const _BgmHeader({required this.controller});

  final BgmController controller;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'BGM',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
          SleepTimerButton(controller: controller),
        ],
      ),
    );
  }
}

/// カテゴリごとにまとめた曲の一覧
class _SoundList extends StatelessWidget {
  const _SoundList({required this.controller});

  final BgmController controller;

  /// カテゴリ名 → その曲たち（読み込み順を保つ）
  Map<String, List<SoundItem>> _groupByCategory(List<SoundItem> sounds) {
    final grouped = <String, List<SoundItem>>{};
    for (final sound in sounds) {
      grouped.putIfAbsent(sound.category, () => []).add(sound);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return FutureBuilder<List<SoundItem>>(
      future: controller.soundsFuture,
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

        final grouped = _groupByCategory(snapshot.data!);

        // 再生状態が変わったときだけ、一覧を作り直す
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              for (final MapEntry(:key, :value) in grouped.entries)
                InsetSection(
                  header: key,
                  children: [
                    for (final sound in value)
                      SoundTile(
                        item: sound,
                        isPlaying: controller.isPlayingItem(sound),
                        onTap: () => controller.toggle(sound),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
