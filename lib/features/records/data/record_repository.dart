import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../domain/care_record.dart';

class RecordRepository {
  RecordRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// 「前回の〇〇」を探すために読む件数。おしっこ・うんちが増えても、
  /// 授乳の「前回」が埋もれないよう、多めに取る
  static const _recentLimit = 200;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _auth.currentUser?.uid;
    return uid == null
        ? null
        : _db.collection('users').doc(uid).collection('records');
  }

  List<CareRecord> _parse(QuerySnapshot<Map<String, dynamic>> s) => s.docs
      .map((d) => CareRecord.fromMap(d.data(), id: d.id))
      .nonNulls
      .toList();

  /// 指定日の記録（timestamp 単一フィールドなので複合インデックス不要）
  Stream<List<CareRecord>> watchDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return _col
            ?.where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where(
              'timestamp',
              isLessThan: Timestamp.fromDate(
                start.add(const Duration(days: 1)),
              ),
            )
            .orderBy('timestamp')
            .snapshots()
            .map(_parse) ??
        const Stream.empty();
  }

  /// 直近の記録（新しい順）。「前回の授乳／おしっこ…」用
  Stream<List<CareRecord>> watchRecent() =>
      _col
          ?.orderBy('timestamp', descending: true)
          .limit(_recentLimit)
          .snapshots()
          .map(_parse) ??
      const Stream.empty();

  /// 記録を追加して、そのIDを返す。
  /// 電波が弱くても画面が止まらないよう、書き込みの完了は待たない
  /// （端末に保存され、つながったときに送られる）。
  Future<String?> add(CareRecord record) async {
    final col = _col;
    if (col == null) return null;
    final ref = col.doc();
    ref
        .set(record.toMap())
        .catchError((Object e) => debugPrint('記録の保存エラー: $e'));
    return ref.id;
  }

  /// 詳細（要約・数値・状態・メモ）だけを書き換える
  Future<void> updateFields(String id, Map<String, dynamic> fields) async {
    await _col?.doc(id).update(fields);
  }

  Future<void> delete(String id) async {
    await _col?.doc(id).delete();
  }
}
