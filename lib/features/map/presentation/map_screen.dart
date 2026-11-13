import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/presence_colors.dart';
import '../../../core/widgets/glow_dot.dart';
import '../care_session_controller.dart';
import '../data/presence_repository.dart';
import '../domain/cheer.dart';
import '../domain/presence.dart';
import 'care_controls.dart';
import 'cheer_bubble.dart';
import 'japan_light_map.dart';
import 'map_frame.dart'; // AmbientGlow から MapFrame に変更
import 'pulse_glow_dot.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.session});

  final CareSessionController session;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final _repo = PresenceRepository();
  late final Stream<List<Presence>> _presence = _repo.watch();

  // エールを受け取ったときの、自分の灯りのパルス
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  StreamSubscription<CheerKind>? _cheerSub;
  Timer? _tick;
  DateTime _now = DateTime.now();

  String? _selectedUid; // 吹き出しを出している灯り
  final _lastSent = <String, DateTime>{}; // 相手ごとの送信時刻（連続送信の抑制）

  @override
  void initState() {
    super.initState();
    _cheerSub = _repo.watchReceivedCheers().listen(
      (_) => _pulse.forward(from: 0),
    );
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _cheerSub?.cancel();
    _tick?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  // 同じ灯りをもう一度タップすると閉じる
  void _onTapLight(Presence target) {
    setState(
      () => _selectedUid = _selectedUid == target.uid ? null : target.uid,
    );
  }

  void _closeBubble() {
    if (_selectedUid != null) setState(() => _selectedUid = null);
  }

  bool _canSendTo(String uid) {
    final last = _lastSent[uid];
    return last == null ||
        DateTime.now().difference(last) > const Duration(minutes: 1);
  }

  Future<void> _send(Presence target, CheerKind kind) async {
    _lastSent[target.uid] = DateTime.now();
    try {
      await _repo.sendCheer(toUid: target.uid, kind: kind);
    } catch (e) {
      debugPrint('エール送信エラー: $e');
    }
  }

  Marker _lightMarker(
    Presence e, {
    required bool dark,
    required String? myUid,
  }) {
    final color = PresenceColors.at(
      e.ageAt(_now),
      dark: dark,
      sleeping: e.status == CareStatus.sleeping, // 寝かしつけの灯りは青紫
    );
    final mine = e.uid == myUid;
    return Marker(
      point: e.position!,
      width: 40, // 灯りは小さいので、タップできる範囲を広げる
      height: 40,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: mine ? null : () => _onTapLight(e), // 自分の灯りには送れない
        child: Center(
          child: SizedBox.square(
            dimension: 8,
            child: mine
                ? PulseGlowDot(color: color, pulse: _pulse)
                : GlowDot(color: color),
          ),
        ),
      ),
    );
  }

  /// 下端が灯りの位置に来るので、吹き出しは灯りの真上に出る
  Marker _bubbleMarker(Presence target) {
    return Marker(
      point: target.position!,
      width: CheerBubble.width,
      height: CheerBubble.height,
      alignment: Alignment.topCenter,
      child: CheerBubble(
        key: ValueKey(target.uid), // 別の灯りに切り替えたら、出現アニメーションをやり直す
        canSend: _canSendTo(target.uid),
        onPicked: (kind) => _send(target, kind),
        onDismissed: _closeBubble,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final myUid = _repo.uid;

    return SafeArea(
      child: StreamBuilder<List<Presence>>(
        stream: _presence,
        builder: (context, snapshot) {
          final list = snapshot.data ?? const <Presence>[];
          int count(CareStatus s) => list.where((e) => e.status == s).length;
          final selected = list.where((e) => e.uid == _selectedUid).firstOrNull;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _Count(
                        '授乳中',
                        count(CareStatus.nursing),
                        p.nursing,
                      ),
                    ),
                    Expanded(
                      child: _Count(
                        '寝かしつけ中',
                        count(CareStatus.sleeping),
                        p.sleeping,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                // 自分の状態が変わるたびに、枠の色・表示が切り替わる
                child: ListenableBuilder(
                  listenable: widget.session,
                  builder: (_, _) => MapFrame(
                    status: widget.session.status,
                    child: JapanLightMap(
                      markers: [
                        for (final e in list)
                          if (e.position != null)
                            _lightMarker(e, dark: dark, myUid: myUid),
                      ],
                      overlayMarkers: [
                        if (selected != null && selected.position != null)
                          _bubbleMarker(selected),
                      ],
                      onMapTap: _closeBubble,
                    ),
                  ),
                ),
              ),
              CareControls(session: widget.session),
            ],
          );
        },
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: p.textSecondary)),
        Text(
          '$count人',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w300,
            color: color,
          ),
        ),
      ],
    );
  }
}
