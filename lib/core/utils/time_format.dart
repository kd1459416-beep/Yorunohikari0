String two(int n) => n.toString().padLeft(2, '0');
String hm(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

String timeAgo(DateTime t, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return 'たった今';
  if (d.inMinutes < 60) return '${d.inMinutes}分前';
  if (d.inHours < 24) return '${d.inHours}時間前';
  return '${d.inDays}日前';
}

/// カウントダウン表示。1時間以上は「1:05:09」、未満は「12:34」
String formatCountdown(Duration d) {
  final seconds = two(d.inSeconds % 60);
  if (d.inHours > 0) return '${d.inHours}:${two(d.inMinutes % 60)}:$seconds';
  return '${two(d.inMinutes)}:$seconds';
}
