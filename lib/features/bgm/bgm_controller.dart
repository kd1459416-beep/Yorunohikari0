import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'sound_data.dart';

/// BGMの再生状態とスリープタイマーを管理する。
///
/// 画面（Widget）は状態を読むだけで、音の操作はすべてここを通す。
class BgmController extends ChangeNotifier {
  BgmController() {
    _player
      ..setReleaseMode(ReleaseMode.loop)
      ..setVolume(0.2); // 控えめな音量（0.0〜1.0）
  }

  static const _defaultTimerPreset = Duration(minutes: 30);

  final _player = AudioPlayer();

  /// 残り時間（毎秒更新）。画面全体ではなく表示部分だけを再描画するため、別に持つ
  final remaining = ValueNotifier(Duration.zero);

  // ---- 曲の一覧 ----

  List<SoundItem> _playlist = const [];

  /// 曲の一覧。初めて参照したときに読み込み、「前へ・次へ」用に覚えておく
  late final Future<List<SoundItem>> soundsFuture = loadSounds().then(
    (list) => _playlist = list,
  );

  // ---- 再生の状態 ----

  SoundItem? _current; // 選ばれている曲（null = 何も選ばれていない）
  bool _isPlaying = false;

  SoundItem? get current => _current;
  bool get isPlaying => _isPlaying;
  bool isPlayingItem(SoundItem item) => _isPlaying && _current?.id == item.id;

  // ---- タイマーの状態 ----

  Duration _timerSetting = Duration.zero; // 0 = オフ（ループ再生）
  Duration _timerPreset = _defaultTimerPreset; // ダイアログで最初に出す時間
  Timer? _ticker;

  bool get timerActive => _timerSetting > Duration.zero;
  Duration get timerPreset => _timerPreset;

  // ---- 音の処理を1つずつ順番に行うための待ち行列 ----

  Future<void> _audioQueue = Future.value();

  void _enqueue(Future<void> Function() job) {
    _audioQueue = _audioQueue
        .then((_) => job())
        .catchError((Object e) => debugPrint('BGM処理エラー: $e'));
  }

  // ============================================================
  //  操作
  // ============================================================

  /// 曲の行をタップしたとき: 再生中なら一時停止、それ以外なら再生
  void toggle(SoundItem item) {
    isPlayingItem(item) ? _pause() : _play(item);
  }

  /// プレイヤーの再生/一時停止ボタン
  void togglePlayPause() {
    final song = _current;
    if (song == null) return;
    _isPlaying ? _pause() : _play(song);
  }

  void playNext() => _skip(1);
  void playPrevious() => _skip(-1);

  /// 0 を渡すとタイマーオフ
  void setTimer(Duration duration) {
    _timerSetting = duration;
    if (duration > Duration.zero) _timerPreset = duration;
    remaining.value = duration;
    _ticker?.cancel();
    if (_isPlaying) _startTicker();
    notifyListeners();
  }

  // ============================================================
  //  内部処理
  // ============================================================

  void _skip(int step) {
    final song = _current;
    if (song == null || _playlist.isEmpty) return;
    final index = _playlist.indexWhere((s) => s.id == song.id);
    // 最後の次は最初、最初の前は最後に戻る（Dart の % は結果が負にならない）
    _play(_playlist[(index + step) % _playlist.length]);
  }

  /// 先に画面を「再生中」にしてから、裏で音を鳴らす（音の準備を待たない）
  void _play(SoundItem item) {
    final isResume = _current?.id == item.id; // 一時停止からの再開か
    _current = item;
    _isPlaying = true;
    _startTicker();
    notifyListeners();

    _enqueue(() async {
      if (!_isStillWanted(item)) return; // 待っている間に別の操作があったら捨てる
      try {
        if (isResume) {
          await _player.resume();
        } else {
          await _player.stop();
          await _player.play(AssetSource(item.assetPath));
        }
      } catch (e) {
        debugPrint('BGM再生エラー: $e');
        if (_isStillWanted(item)) {
          // 鳴らせなかったときだけ、表示を元に戻す
          _isPlaying = false;
          _ticker?.cancel();
          notifyListeners();
        }
      }
    });
  }

  void _pause() {
    _isPlaying = false;
    _ticker?.cancel(); // 残り時間は保持したまま、カウントだけ止める
    notifyListeners();
    _enqueue(_player.pause);
  }

  bool _isStillWanted(SoundItem item) => _isPlaying && _current?.id == item.id;

  /// 再生中だけ、1秒ごとに残り時間を減らす
  void _startTicker() {
    _ticker?.cancel();
    if (!timerActive || remaining.value <= Duration.zero) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      remaining.value -= const Duration(seconds: 1);
      if (remaining.value <= Duration.zero) _stopByTimer();
    });
  }

  /// タイマーが0になったとき: 停止して、プレイヤーも消す
  void _stopByTimer() {
    _ticker?.cancel();
    _isPlaying = false;
    _current = null; // 次回は最初から再生
    _timerSetting = Duration.zero;
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
