/// 広場への投稿に含めてほしくない内容を、ざっくり検出する簡易フィルタ。
/// 完璧な検知はできないので、明らかなものだけを弾く。
library;

/// 暴言・攻撃的な言葉。必要に応じて追加していく想定のたたき台。
const _ngWords = ['死ね', 'きえろ', 'クソ親', 'ガイジ'];

/// 電話番号らしき並び（070-1234-5678 / 09012345678 など）
final _phoneNumberPattern = RegExp(r'0\d{1,4}[-\s]?\d{1,4}[-\s]?\d{3,4}');

/// LINE/SNSでの連絡先交換を誘う文言
final _contactExchangePattern = RegExp(
  r'line\s*id|ライン\s*id|ラインid|インスタ(グラム)?|instagram|@[a-zA-Z0-9_.]{3,}',
  caseSensitive: false,
);

/// 暴言・連絡先交換のいずれかを含むか
bool containsNgContent(String text) {
  final lower = text.toLowerCase();
  if (_ngWords.any(lower.contains)) return true;
  if (_phoneNumberPattern.hasMatch(text)) return true;
  if (_contactExchangePattern.hasMatch(text)) return true;
  return false;
}
