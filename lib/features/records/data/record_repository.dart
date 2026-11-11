import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/care_record.dart';

class RecordRepository {
  RecordRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

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

  Future<void> delete(String id) async {
    await _col?.doc(id).delete();
  }

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

  /// 直近の記録（新しい順）。「前回の授乳／睡眠」用
  Stream<List<CareRecord>> watchRecent({int limit = 50}) =>
      _col
          ?.orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map(_parse) ??
      const Stream.empty();

  Future<void> add(CareRecord record) async {
    await _col?.add(record.toMap());
  }
}
