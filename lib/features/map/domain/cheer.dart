enum CheerKind {
  otsukare('☕️', 'お疲れ様'),
  mimamoru('🫂', '見守ってるよ'),
  daijoubu('❤️', 'だいじょうぶ');

  const CheerKind(this.emoji, this.label);
  final String emoji;
  final String label;
}
