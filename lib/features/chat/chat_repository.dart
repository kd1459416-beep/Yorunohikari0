import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.senderId,
    required this.sentAt,
  });

  static const aiSenderId = 'ai';

  final String text;
  final String senderId;
  final DateTime sentAt;

  bool get isAi => senderId == aiSenderId;

  static ChatMessage? tryParse(Map<String, dynamic> m) {
    final text = m['text'] as String?;
    if (text == null) return null;
    return ChatMessage(
      text: text,
      senderId: m['senderId'] as String? ?? '',
      // サーバー時刻が確定する前は null になるので現在時刻で代用
      sentAt: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get uid => _auth.currentUser?.uid;

  /// 現在時刻から24時間前（投稿から24時間経過でタイムラインから非表示）
  static DateTime lastResetAt([DateTime? now]) {
    final n = now ?? DateTime.now();
    return n.subtract(const Duration(hours: 24));
  }

  List<ChatMessage> _parse(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => ChatMessage.tryParse(d.data())).nonNulls.toList();

  // ---------- 広場（全員共通） ----------

  /// roomId 一致 + timestamp の範囲指定 + 並び替え → 複合インデックスが必要
  Stream<List<ChatMessage>> watchRoom(String roomId) => _db
      .collection('chats')
      .where('roomId', isEqualTo: roomId)
      .where(
        'timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(lastResetAt()),
      )
      .orderBy('timestamp', descending: true)
      .limit(200)
      .snapshots()
      .map(_parse);

  Future<void> sendToRoom(String roomId, String text) async {
    final id = uid;
    if (id == null) return;
    await _db.collection('chats').add({
      'text': text,
      'senderId': id,
      'roomId': roomId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ---------- AI相談（ユーザーごとに分離） ----------

  CollectionReference<Map<String, dynamic>>? get _aiCol {
    final id = uid;
    return id == null
        ? null
        : _db.collection('users').doc(id).collection('ai_chats');
  }

  Stream<List<ChatMessage>> watchAi() =>
      _aiCol
          ?.orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .map(_parse) ??
      const Stream.empty();

  Future<DocumentReference<Map<String, dynamic>>?> addAiMessage(
    String text, {
    required bool fromAi,
  }) async {
    final id = uid;
    return _aiCol?.add({
      'text': text,
      'senderId': fromAi ? ChatMessage.aiSenderId : id,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
