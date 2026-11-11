import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../care_session_controller.dart';

class Presence {
  const Presence({
    required this.uid,
    required this.position,
    required this.status,
    required this.updatedAt,
  });

  final String uid;
  final LatLng position;
  final CareStatus status;
  final DateTime updatedAt; // 状態が変わった時刻（灯りの経過時間の基準）

  /// 端末の時計のずれで負にならないよう 0 に丸める
  Duration ageAt(DateTime now) {
    final d = now.difference(updatedAt);
    return d.isNegative ? Duration.zero : d;
  }

  /// 位置と状態が揃っていれば、時間が経っていても対象にする（自動消灯なし）
  static Presence? tryParse(String uid, Map<String, dynamic> m) {
    final status = CareStatus.values.asNameMap()[m['status']];
    final lat = (m['latitude'] as num?)?.toDouble();
    final lng = (m['longitude'] as num?)?.toDouble();
    if (status == null || status == CareStatus.none) return null;
    if (lat == null || lng == null) return null;

    // 書き込み直後は serverTimestamp が未確定（null）。その場合は「今」とみなす
    final at = (m['statusUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Presence(
      uid: uid,
      position: LatLng(lat, lng),
      status: status,
      updatedAt: at,
    );
  }
}
