import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../bgm/bgm_screen.dart';
import '../chat/chat_screen.dart';
import '../map/care_session_controller.dart';
import '../map/presentation/map_screen.dart';
import '../records/presentation/records_screen.dart';
import '../settings/presentation/settings_screen.dart';
import '../bgm/bgm_controller.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _session = CareSessionController();
  final _bgm = BgmController();
  late final _pages = [
    MapScreen(session: _session),
    const RecordsScreen(),
    const ChatScreen(),
    BgmScreen(controller: _bgm),
    const SettingsScreen(),
  ];
  int _index = 0;

  @override
  void dispose() {
    _session.dispose();
    _bgm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: p.surface.withValues(alpha: 0.85), // すりガラス
        border: Border(top: BorderSide(color: p.hairline, width: 0.5)),
        activeColor: p.accent,
        inactiveColor: p.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.map), label: 'マップ'),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.doc_text),
            label: '記録',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble),
            label: 'チャット',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.music_note),
            label: 'BGM',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'マイページ',
          ),
        ],
      ),
    );
  }
}
