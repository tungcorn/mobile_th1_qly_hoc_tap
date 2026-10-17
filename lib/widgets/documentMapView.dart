import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../colors.dart';

const LatLng kHanoiCenter = LatLng(21.0285, 105.8542);
const String kOsmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String kMapUserAgent = 'com.studydoc.study_doc_manager';

class MapMarkerData {
  final String id;
  final String title;
  final String subtitle;
  final LatLng point;

  const MapMarkerData({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.point,
  });
}

/// Bản đồ hiển thị mọi tài liệu có vị trí; tự fit bounds khi > 1 marker.
class DocumentMapView extends StatefulWidget {
  final List<MapMarkerData> markers;
  final ValueChanged<MapMarkerData>? onTap;

  const DocumentMapView({super.key, required this.markers, this.onTap});

  @override
  State<DocumentMapView> createState() => _DocumentMapViewState();
}

class _DocumentMapViewState extends State<DocumentMapView> {
  final _controller = MapController();
  bool _ready = false;

  MapOptions _options() {
    final m = widget.markers;
    return MapOptions(
      initialCenter: m.length == 1 ? m.first.point : kHanoiCenter,
      initialZoom: m.length == 1 ? 15 : 12,
      initialCameraFit: m.length > 1 ? _fit() : null,
      minZoom: 2,
      maxZoom: 19,
      onMapReady: () => _ready = true,
    );
  }

  CameraFit _fit() => CameraFit.coordinates(
        coordinates: widget.markers.map((e) => e.point).toList(),
        padding: const EdgeInsets.fromLTRB(56, 72, 56, 56),
        maxZoom: 17,
      );

  @override
  void didUpdateWidget(covariant DocumentMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready || _sameMarkers(oldWidget.markers, widget.markers)) return;
    final m = widget.markers;
    if (m.length > 1) {
      _controller.fitCamera(_fit());
    } else if (m.length == 1) {
      _controller.move(m.first.point, 15);
    } else {
      _controller.move(kHanoiCenter, 12);
    }
  }

  bool _sameMarkers(List<MapMarkerData> a, List<MapMarkerData> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].point != b[i].point) return false;
    }
    return true;
  }

  void _zoom(double delta) {
    final cam = _controller.camera;
    _controller.move(cam.center, (cam.zoom + delta).clamp(2.0, 19.0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: _options(),
          children: [
            TileLayer(
              urlTemplate: kOsmTileUrl,
              userAgentPackageName: kMapUserAgent,
            ),
            MarkerLayer(
              markers: [
                for (final m in widget.markers)
                  Marker(
                    point: m.point,
                    width: 140,
                    height: 76,
                    alignment: Alignment.topCenter,
                    child: _Pin(data: m, onTap: widget.onTap),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text('© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10)),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Material(
            color: scheme.surface,
            elevation: 3,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Phóng to',
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _zoom(1),
                ),
                const SizedBox(width: 24, child: Divider(height: 1)),
                IconButton(
                  tooltip: 'Thu nhỏ',
                  icon: const Icon(Icons.remove_rounded),
                  onPressed: () => _zoom(-1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  final MapMarkerData data;
  final ValueChanged<MapMarkerData>? onTap;

  const _Pin({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: data.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null ? null : () => onTap!(data),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 40,
              color: AppColors.tertiary,
              shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
