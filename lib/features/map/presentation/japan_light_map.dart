import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_palette.dart';

class JapanLightMap extends StatefulWidget {
  const JapanLightMap({
    super.key,
    required this.markers,
    this.overlayMarkers = const [],
    this.onMapTap,
  });

  final List<Marker> markers;

  /// 吹き出しなど、灯りより手前に出すもの
  final List<Marker> overlayMarkers;

  /// 地図の何もない場所をタップしたとき
  final VoidCallback? onMapTap;

  @override
  State<JapanLightMap> createState() => _JapanLightMapState();
}

class _JapanLightMapState extends State<JapanLightMap> {
  late final _options = MapOptions(
    initialCenter: const LatLng(36.2048, 138.2529),
    initialZoom: 5.2,
    minZoom: 3.5,
    maxZoom: 12,
    onTap: (_, _) => widget.onMapTap?.call(), // 最新の callback を呼ぶ
  );

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: AppPalette.of(context).background,
      child: FlutterMap(
        options: _options,
        children: [
          TileLayer(
            urlTemplate: dark
                ? 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}'
                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.yorunohikari',
          ),
          MarkerLayer(markers: widget.markers),
          MarkerLayer(markers: widget.overlayMarkers), // 吹き出しは最前面
        ],
      ),
    );
  }
}
