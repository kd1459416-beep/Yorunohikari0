import 'dart:math';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/prefectures.dart';

class RegionService {
  static const _tokyo = LatLng(35.6895, 139.6917);

  /// 住所から座標を引く。失敗したら都道府県の代表座標を使う。
  Future<LatLng> resolve(String prefecture, String city) async {
    try {
      final results = await locationFromAddress('$prefecture $city'.trim());
      if (results.isNotEmpty) {
        return LatLng(results.first.latitude, results.first.longitude);
      }
    } catch (_) {}
    return prefectureCoordinates[prefecture] ?? _tokyo;
  }

  /// 居場所が特定されないよう、±約2.5kmずらす。
  LatLng blur(LatLng base, {double range = 0.05, Random? random}) {
    final r = random ?? Random();
    return LatLng(
      base.latitude + (r.nextDouble() - 0.5) * range,
      base.longitude + (r.nextDouble() - 0.5) * range,
    );
  }
}
