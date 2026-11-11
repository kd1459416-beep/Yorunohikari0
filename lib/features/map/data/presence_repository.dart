import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/cheer.dart';
import '../domain/presence.dart';

class PresenceRepository {
  PresenceRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('presence');
  String? get uid => _auth.currentUser?.uid;

  Stream<List<Presence>> watch() => _col.snapshots().map(
    (s) =>
        s.docs.map((d) => Presence.tryParse(d.id, d.data())).nonNulls.toList(),
  );

  /// 自分の灯り（状態・座標）だけを書き込む
  Future<void> update(Map<String, dynamic> data) async {
    final id = uid;
    if (id == null) return;
    await _col.doc(id).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// エールを送る。自分宛ては送らない。
  Future<void> sendCheer({
    required String toUid,
    required CheerKind kind,
  }) async {
    final from = uid;
    if (from == null || from == toUid) return;
    await _col.doc(toUid).collection('cheers').doc(from).set({
      'kind': kind.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 自分宛てに届いたエールを流す。
  /// 起動前に届いていた分は通知せず、削除だけする（アプリを閉じている間は知らせない）。
  Stream<CheerKind> watchReceivedCheers() async* {
    final id = uid;
    if (id == null) return;

    var ready = false;
    await for (final snap in _col.doc(id).collection('cheers').snapshots()) {
      if (!ready) {
        // キャッシュ由来の最初のスナップショットは飛ばし、サーバー分で片付ける
        if (snap.metadata.isFromCache) continue;
        ready = true;
        for (final d in snap.docs) {
          d.reference.delete().ignore();
        }
        continue;
      }
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.removed) continue;
        final kind = CheerKind.values.asNameMap()[change.doc.data()?['kind']];
        change.doc.reference.delete().ignore(); // 読んだら消す
        if (kind != null) yield kind;
      }
    }
  }
}
