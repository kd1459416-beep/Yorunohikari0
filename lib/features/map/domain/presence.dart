import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../care_session_controller.dart';

/// 1人分の灯り。位置が未登録でも、人数には数える。
class Presence {
  const Presence({
    required this.uid,
    required this.status,
    required this.updatedAt,
    this.position,
  });

  final String uid;
  final CareStatus status;
  final DateTime updatedAt; // 状態が変わった時刻（灯りの経過時間の基準）

  /// 位置が未登録なら null。地図には描かず、人数にだけ数える
  final LatLng? position;

  /// 端末の時計のずれで負にならないよう 0 に丸める
  Duration ageAt(DateTime now) {
    final d = now.difference(updatedAt);
    return d.isNegative ? Duration.zero : d;
  }

  /// 状態が「授乳中・寝かしつけ中」なら対象にする（時間が経っても消さない）
  static Presence? tryParse(String uid, Map<String, dynamic> m) {
    final status = CareStatus.values.asNameMap()[m['status']];
    if (status == null || status == CareStatus.none) return null;

    final lat = (m['latitude'] as num?)?.toDouble();
    final lng = (m['longitude'] as num?)?.toDouble();

    return Presence(
      uid: uid,
      status: status,
      position: (lat != null && lng != null) ? LatLng(lat, lng) : null,
      // 書き込み直後は serverTimestamp が未確定（null）。その場合は「今」とみなす
      updatedAt:
          (m['statusUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
