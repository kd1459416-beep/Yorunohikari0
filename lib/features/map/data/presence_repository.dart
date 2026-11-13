import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/prefectures.dart';
import '../../settings/data/region_service.dart';
import '../domain/cheer.dart';
import '../domain/presence.dart';

class PresenceRepository {
  PresenceRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static const _tokyo = LatLng(35.6895, 139.6917);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('presence');
  String? get uid => _auth.currentUser?.uid;

  /// 灯りの一覧。接続エラーで止まっても、5秒後に自動でつなぎ直す。
  Stream<List<Presence>> watch() async* {
    while (true) {
      try {
        await for (final snapshot in _col.snapshots()) {
          yield snapshot.docs
              .map((d) => Presence.tryParse(d.id, d.data()))
              .nonNulls
              .toList();
        }
        return; // 正常に終わった（画面が閉じられた）
      } catch (e) {
        debugPrint('灯りの取得エラー（再接続します）: $e');
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
  }

  /// 自分の灯り（状態・座標）だけを書き込む
  Future<void> update(Map<String, dynamic> data) async {
    final id = uid;
    if (id == null) return;
    await _col.doc(id).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 状態（nursing / sleeping / none）を書き込む。
  /// 灯りを点けるとき、位置が未登録なら補って、地図に必ず現れるようにする。
  Future<void> setStatus(String status) async {
    final id = uid;
    if (id == null) return;

    final data = <String, dynamic>{
      'status': status,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    };

    if (status != 'none') {
      try {
        final current = (await _col.doc(id).get()).data();
        final hasPosition =
            current?['latitude'] != null && current?['longitude'] != null;
        if (!hasPosition) {
          final position = await _fallbackPosition(id);
          data['latitude'] = position.latitude;
          data['longitude'] = position.longitude;
        }
      } catch (e) {
        debugPrint('位置の補完に失敗（状態だけ書き込みます）: $e');
      }
    }
    await update(data);
  }

  /// 位置が未登録のときの代わりの座標（少しずらす）。
  /// 以前保存した座標 → 都道府県の代表座標 → 東京 の順に使う。
  Future<LatLng> _fallbackPosition(String uid) async {
    final regions = RegionService();
    try {
      final user = (await _db.collection('users').doc(uid).get()).data();
      final lat = (user?['latitude'] as num?)?.toDouble();
      final lng = (user?['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) return regions.blur(LatLng(lat, lng));

      final prefecture = user?['prefecture'] as String?;
      return regions.blur(prefectureCoordinates[prefecture] ?? _tokyo);
    } catch (_) {
      return regions.blur(_tokyo);
    }
  }

  // ---------- エール ----------

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
        change.doc.reference.delete().ignore();
        if (kind != null) yield kind;
      }
    }
  }
}
