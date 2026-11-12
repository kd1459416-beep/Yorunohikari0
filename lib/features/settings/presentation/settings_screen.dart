import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/inset_section.dart';
import '../../../core/widgets/labeled_segmented.dart';
import '../data/user_repository.dart';
import 'credits_screen.dart';
import 'profile_edit_screen.dart';
import 'region_screen.dart';
import 'support_section.dart';

Future<void> _push(BuildContext context, Widget page) =>
    Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => page));

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _users = UserRepository();
  late Future<Map<String, dynamic>> _profile = _users.load();

  Future<void> _openProfile() async {
    await _push(context, const ProfileEditScreen());
    // 戻ってきたら、保存した内容を読み直す
    if (mounted) {
      setState(() {
        _profile = _users.load(); // 代入だけ。値を返さない書き方にする
      });
    }
  }

  String? _summary(Map<String, dynamic>? d) {
    final name = (d?['babyName'] as String?)?.trim() ?? '';
    if (name.isEmpty) return null;
    return name.length > 10 ? '${name.substring(0, 10)}…' : name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('マイページ')),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          InsetSection(
            children: [
              FutureBuilder<Map<String, dynamic>>(
                future: _profile,
                builder: (_, snap) => InsetTile(
                  title: 'プロフィール',
                  value: _summary(snap.data),
                  onTap: _openProfile,
                ),
              ),
              InsetTile(
                title: '地域',
                onTap: () => _push(context, const RegionScreen()),
              ),
            ],
          ),
          const InsetSection(
            header: '外観',
            children: [AppearanceTile(), ToneTile()],
          ),
          const SupportSection(),
          InsetSection(
            children: [
              InsetTile(
                title: 'クレジット表記',
                onTap: () => _push(context, const CreditsScreen()),
              ),
            ],
          ),
          InsetSection(
            children: [
              InsetTile(
                title: 'ログアウト',
                destructive: true,
                onTap: FirebaseAuth.instance.signOut,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// [ ライト | ダーク ] の2択
class AppearanceTile extends StatelessWidget {
  const AppearanceTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LabeledSegmented<ThemeMode>(
        value: theme.mode,
        options: const {ThemeMode.light: 'ライト', ThemeMode.dark: 'ダーク'},
        onChanged: theme.setMode,
      ),
    );
  }
}

/// 選んでいるモードの色味を調整する
///  ライト: やわらかい白 ←→ クリーム
///  ダーク: 青み ←→ 漆黒
class ToneTile extends StatelessWidget {
  const ToneTile({super.key});

  /// CupertinoSlider の左右の余白に合わせて、ラベルをトラックの端に揃える
  static const _trackInset = 8.0;

  /// ライト/ダーク切替のフェード時間
  static const _fade = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final p = AppPalette.of(context);
    final isLight = theme.mode == ThemeMode.light;
    final caption = TextStyle(fontSize: 12, color: p.textSecondary);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: AnimatedSwitcher(
        duration: _fade,
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topLeft,
          children: [...previous, if (current != null) current],
        ),
        child: Column(
          key: ValueKey(isLight), // モードが変わったときだけ入れ替わる
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLight ? '色味' : '暗さ',
              style: TextStyle(fontSize: 16, color: p.textPrimary),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity, // カード幅いっぱいに伸ばす
              child: CupertinoSlider(
                value: isLight ? theme.warmth : theme.depth,
                activeColor: p.accent,
                onChangeStart: (_) => theme.beginTuning(), // 触れた瞬間: アニメーションを止める
                onChanged: isLight
                    ? theme.setWarmth
                    : theme.setDepth, // 指に即座に追従
                onChangeEnd: (_) => theme.endTuning(), // 離したら保存
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _trackInset),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isLight ? 'やわらかい白' : '青み', style: caption),
                  Text(isLight ? 'クリーム' : '漆黒', style: caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
