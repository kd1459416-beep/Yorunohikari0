import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Future<List<AiTurn>> loadRecentTurns({int limit = 12}) async {
    final snapshot = await _col
        ?.orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    if (snapshot == null) return const [];
    return snapshot.docs.reversed
        .map((d) => AiMessage.tryParse(d.data()))
        .nonNulls
        .where((m) => !m.isError && m.text != placeholder)
        .map((m) => AiTurn(isUser: !m.isAi, text: m.text))
        .toList();
  }

  Future<void> addUserMessage(String text) async {
    await _col?.add({
      'text': text,
      'senderId': _auth.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// 回答用の空のメッセージを作り、あとで書き換えるための参照を返す
  Future<DocumentReference<Map<String, dynamic>>?> addAiPlaceholder() async {
    return _col?.add({
      'text': placeholder,
      'senderId': aiSenderId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> writeAiText(
    DocumentReference<Map<String, dynamic>>? ref,
    String text,
  ) async {
    await ref?.update({'text': text});
  }

  Future<void> writeAiError(
    DocumentReference<Map<String, dynamic>>? ref,
    String message,
  ) async {
    await ref?.update({'text': message, 'error': true});
  }
}
