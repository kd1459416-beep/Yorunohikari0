String two(int n) => n.toString().padLeft(2, '0');
String hm(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

/// カウントダウン表示。1時間以上は「1:05:09」、未満は「12:34」
String formatCountdown(Duration d) {
  final seconds = two(d.inSeconds % 60);
  if (d.inHours > 0) return '${d.inHours}:${two(d.inMinutes % 60)}:$seconds';
  return '${two(d.inMinutes)}:$seconds';
}

/// 前回からの経過時間。表示のしかたはここにまとめる。
///   1分未満 → たった今 / 45分 → 45分前 / 2時間38分 → 2時間38分前
///   ちょうど2時間 → 2時間前 / 1日5時間 → 1日5時間前（日をまたぐと分は省く）
class ElapsedTime {
  const ElapsedTime(this.duration);

  factory ElapsedTime.since(DateTime time, {DateTime? now}) {
    final d = (now ?? DateTime.now()).difference(time);
    return ElapsedTime(d.isNegative ? Duration.zero : d); // 端末の時計のずれ対策
  }

  final Duration duration;

  bool get isJustNow => duration.inMinutes < 1;

  /// 表示用の（数字, 単位）の並び。例: [('2','時間'), ('38','分前')]
  /// 数字と単位で文字の大きさを変えて表示できるように、分けて持つ
  List<(String, String)> get segments {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    final parts = <(String, String)>[];
    if (days > 0) {
      parts.add(('$days', '日'));
      if (hours > 0) parts.add(('$hours', '時間'));
    } else if (duration.inHours > 0) {
      parts.add(('$hours', '時間'));
      if (minutes > 0) parts.add(('$minutes', '分'));
    } else {
      parts.add(('$minutes', '分'));
    }

    // いちばん最後の単位に「前」を付ける
    final last = parts.removeLast();
    parts.add((last.$1, '${last.$2}前'));
    return parts;
  }

  String get text =>
      isJustNow ? 'たった今' : segments.map((s) => '${s.$1}${s.$2}').join();
}

String timeAgo(DateTime time, {DateTime? now}) =>
    ElapsedTime.since(time, now: now).text;
