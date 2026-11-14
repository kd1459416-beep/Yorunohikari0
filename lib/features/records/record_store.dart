import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'record_models.dart';

// ============================================================
//  1. Firestore の読み書き
// ============================================================

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

  /// 直近の記録（新しい順）。「前回の〇〇」と、授乳のお知らせに使う
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

  /// 時刻と所要時間だけを書き換える（押し忘れの修正用）
  Future<void> updateTiming(
    String id, {
    required DateTime endedAt,
    required Duration duration,
  }) async {
    await _col?.doc(id).update({
      'timestamp': Timestamp.fromDate(endedAt),
      'duration': CareRecord.encodeDuration(duration),
    });
  }

  Future<void> delete(String id) async {
    await _col?.doc(id).delete();
  }
}

// ============================================================
//  2. ワンタップ記録の状態
// ============================================================

/// ワンタップ記録の状態を持つ。
/// 直前に保存した記録を一定時間だけ覚えておき、「詳細を足す」「取り消す」を可能にする。
class QuickRecordController extends ChangeNotifier {
  QuickRecordController(this._repository);

  static const _bannerDuration = Duration(seconds: 8);

  final RecordRepository _repository;
  CareRecord? _last;
  Timer? _hideTimer;

  /// 直前に保存した記録（なければ null）。この間だけお知らせを出す
  CareRecord? get last => _last;

  /// 「いま」の記録を1回で保存する
  Future<void> record(RecordType type) async {
    final now = DateTime.now();
    final id = await _repository.add(CareRecord(type: type, endedAt: now));
    if (id == null) return;

    _last = CareRecord(id: id, type: type, endedAt: now);
    _hideTimer?.cancel();
    _hideTimer = Timer(_bannerDuration, dismiss);
    notifyListeners();
  }

  /// 直前の記録を取り消す
  Future<void> undo() async {
    final id = _last?.id;
    dismiss();
    if (id == null) return;
    try {
      await _repository.delete(id);
    } catch (e) {
      debugPrint('記録の取り消しエラー: $e');
    }
  }

  /// お知らせだけを閉じる（記録は残す）
  void dismiss() {
    _hideTimer?.cancel();
    if (_last == null) return;
    _last = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}
