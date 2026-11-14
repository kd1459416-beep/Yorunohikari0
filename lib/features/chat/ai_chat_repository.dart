import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'gemini_service.dart';

/// AI相談の1メッセージ
class AiMessage {
  const AiMessage({
    required this.text,
    required this.isAi,
    required this.sentAt,
    this.isError = false,
  });

  final String text;
  final bool isAi;
  final DateTime sentAt;

  /// 回答に失敗したときのお知らせ。次回の質問の履歴には含めない
  final bool isError;

  /// 回答を待っている間の、仮のメッセージ（「…」）か
  bool get isPending => isAi && text == AiChatRepository.placeholder;

  static AiMessage? tryParse(Map<String, dynamic> data) {
    final text = data['text'] as String?;
    if (text == null) return null;
    return AiMessage(
      text: text,
      isAi: data['senderId'] == AiChatRepository.aiSenderId,
      sentAt: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isError: data['error'] == true,
    );
  }
}

/// 回答用のメッセージ1件への書き込み口。書き込みの完了は待たない。
class AiReply {
  const AiReply._(this._ref);

  final DocumentReference<Map<String, dynamic>> _ref;

  void writeText(String text) =>
      AiChatRepository._save(_ref.update({'text': text}));

  void writeError(String message) =>
      AiChatRepository._save(_ref.update({'text': message, 'error': true}));
}

/// AI相談の保存・読み込みだけを担当する（ユーザーごとに分離: users/{uid}/ai_chats）。
class AiChatRepository {
  AiChatRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static const aiSenderId = 'ai';

  /// 回答を待っている間に出す仮の文字
  static const placeholder = '…';

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _auth.currentUser?.uid;
    return uid == null
        ? null
        : _db.collection('users').doc(uid).collection('ai_chats');
  }

  /// 書き込みの完了は待たない（電波が弱くても、画面はすぐ動く）。失敗はログに残す
  static void _save(Future<void> write) {
    write.catchError((Object e) => debugPrint('AI相談の保存エラー: $e'));
  }

  Stream<List<AiMessage>> watch() =>
      _col
          ?.orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .map(
            (s) => s.docs
                .map((d) => AiMessage.tryParse(d.data()))
                .nonNulls
                .toList(),
          ) ??
      const Stream.empty();

  /// 直近の会話を、Gemini に渡す履歴として取り出す（古い順）。
  /// 仮の文字と、失敗のお知らせは含めない。
  /// 画面がすでに読み込んだ分（端末内）から取るので、通信を待たない。
  Future<List<AiTurn>> loadRecentTurns({int limit = 12}) async {
    try {
      final snapshot = await _col
          ?.orderBy('timestamp', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.cache));
      if (snapshot == null) return const [];
      return snapshot.docs.reversed
          .map((d) => AiMessage.tryParse(d.data()))
          .nonNulls
          .where((m) => !m.isError && m.text != placeholder)
          .map((m) => AiTurn(isUser: !m.isAi, text: m.text))
          .toList();
    } catch (e) {
      debugPrint('履歴の読み込みエラー（履歴なしで続けます）: $e');
      return const [];
    }
  }

  /// 質問を保存する。保存の完了は待たず、すぐ画面に出す
  void addUserMessage(String text) {
    final ref = _col?.doc();
    if (ref == null) return;
    _save(
      ref.set({
        'text': text,
        'senderId': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      }),
    );
  }

  /// 回答用の仮のメッセージ（「…」）を作る。回答は、返ってきた [AiReply] に書く
  AiReply? addAiPlaceholder() {
    final ref = _col?.doc();
    if (ref == null) return null;
    _save(
      ref.set({
        'text': placeholder,
        'senderId': aiSenderId,
        'timestamp': FieldValue.serverTimestamp(),
      }),
    );
    return AiReply._(ref);
  }
}
