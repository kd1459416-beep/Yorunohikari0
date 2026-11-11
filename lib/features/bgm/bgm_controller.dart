import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/time_format.dart';
import 'sound_data.dart';

class BgmController extends ChangeNotifier {
  BgmController() {
    _player
      ..setReleaseMode(ReleaseMode.loop)
      ..setVolume(0.2);
  }

  final _player = AudioPlayer();

  /// 毎秒更新。画面全体ではなくタイマー表示だけを再描画する。
  final remaining = ValueNotifier(Duration.zero);

  String? _currentId;
  bool _isPlaying = false;
  int _timerMinutes = 0; // 0 = オフ（ループ再生）
  Timer? _ticker;

  // 音の処理を1つずつ順番に行う（連打で処理が重ならないように）
  Future<void> _audioQueue = Future.value();

  bool get timerActive => _timerMinutes > 0;
  bool isPlayingItem(SoundItem item) => _isPlaying && _currentId == item.id;

  static String format(Duration d) =>
      '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';

  void _enqueue(Future<void> Function() job) {
    _audioQueue = _audioQueue
        .then((_) => job())
        .catchError((Object e) => debugPrint('BGM処理エラー: $e'));
  }

  /// タップ → まず表示を更新（0秒）→ 裏で音を鳴らす
  void toggle(SoundItem item) {
    if (isPlayingItem(item)) {
      _isPlaying = false;
      _ticker?.cancel(); // 残り時間は保持したまま、カウントだけ止める
      notifyListeners();
      _enqueue(_player.pause);
      return;
    }

    final sameSound = _currentId == item.id; // 一時停止からの再開か
    _currentId = item.id;
    _isPlaying = true;
    _startTicker();
    notifyListeners(); // ← ここで画面はもう「再生中」

    _enqueue(() async {
      // 待っている間に別の操作があったら、この処理は捨てる
      if (!(_isPlaying && _currentId == item.id)) return;
      try {
        if (sameSound) {
          await _player.resume();
        } else {
          await _player.stop();
          await _player.play(AssetSource(item.assetPath));
        }
      } catch (e) {
        debugPrint('BGM再生エラー: $e');
        if (_currentId == item.id) {
          // 鳴らせなかったときだけ、表示を元に戻す
          _isPlaying = false;
          _ticker?.cancel();
          notifyListeners();
        }
      }
    });
  }

  /// 0 を渡すとタイマーオフ
  void setTimer(int minutes) {
    _timerMinutes = minutes;
    remaining.value = Duration(minutes: minutes);
    _ticker?.cancel();
    if (_isPlaying) _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    if (!timerActive || remaining.value <= Duration.zero) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      remaining.value -= const Duration(seconds: 1);
      if (remaining.value <= Duration.zero) _stopByTimer();
    });
  }

  void _stopByTimer() {
    _ticker?.cancel();
    _isPlaying = false;
    _currentId = null; // 次回は最初から再生
    _timerMinutes = 0;
    remaining.value = Duration.zero;
    notifyListeners();
    _enqueue(_player.stop);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _player.dispose();
    remaining.dispose();
    super.dispose();
  }
}
