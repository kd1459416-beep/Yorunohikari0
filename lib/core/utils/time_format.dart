String two(int n) => n.toString().padLeft(2, '0');
String hm(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

String timeAgo(DateTime t, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return 'たった今';
  if (d.inMinutes < 60) return '${d.inMinutes}分前';
  if (d.inHours < 24) return '${d.inHours}時間前';
  return '${d.inDays}日前';
}
