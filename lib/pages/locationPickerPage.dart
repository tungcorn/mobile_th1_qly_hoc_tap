import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../colors.dart';
import '../widgets/cloudUi.dart';
import '../widgets/documentMapView.dart'
    show kHanoiCenter, kMapUserAgent, kOsmTileUrl;

/// Kết quả chọn vị trí. [cleared] = true nghĩa là người dùng muốn xóa vị trí.
class PickedLocation {
  final LatLng point;
  final String name;
  final bool cleared;

  const PickedLocation(this.point, this.name, {this.cleared = false});
}

class LocationPickerPage extends StatefulWidget {
  final LatLng? initial;
  final String? initialName;

  const LocationPickerPage({super.key, this.initial, this.initialName});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const _presets = [
    'Tủ tài liệu phòng 301',
    'Thư viện trường',
    'Nhà riêng',
    'Phòng học nhóm',
  ];

  final _map = MapController();
  late final TextEditingController _name;
  LatLng? _point;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _point = widget.initial;
    _name = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _map.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('Dịch vụ vị trí đang tắt. Hãy bật GPS rồi thử lại.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        _snack('Bạn đã từ chối quyền truy cập vị trí.');
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        _snack('Quyền vị trí bị chặn. Hãy cấp quyền trong cài đặt thiết bị.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final p = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _point = p);
      _map.move(p, 16);
    } catch (_) {
      _snack('Không lấy được vị trí hiện tại. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    final p = _point;
    if (p == null) {
      _snack('Chạm vào bản đồ để chọn vị trí trước.');
      return;
    }
    Navigator.of(context).pop(PickedLocation(p, _name.text.trim()));
  }

  void _clear() {
    Navigator.of(context).pop(PickedLocation(kHanoiCenter, '', cleared: true));
  }

  Widget _buildMap() {
    final scheme = Theme.of(context).colorScheme;
    final p = _point;
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: p ?? kHanoiCenter,
            initialZoom: p == null ? 12 : 16,
            minZoom: 2,
            maxZoom: 19,
            onTap: (_, latLng) => setState(() => _point = latLng),
          ),
          children: [
            TileLayer(
              urlTemplate: kOsmTileUrl,
              userAgentPackageName: kMapUserAgent,
            ),
            if (p != null)
              MarkerLayer(markers: [
                Marker(
                  point: p,
                  width: 48,
                  height: 48,
                  alignment: Alignment.topCenter,
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 48,
                    color: AppColors.tertiary,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
                  ),
                ),
              ]),
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
      ],
    );
  }

  Widget _buildForm() {
    final theme = Theme.of(context);
    final p = _point;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CloudUi.standard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.place_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: CloudUi.small),
              Expanded(
                child: Text(
                  p == null
                      ? 'Chưa chọn vị trí. Chạm vào bản đồ để đặt ghim.'
                      : '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: CloudUi.medium),
          OutlinedButton.icon(
            onPressed: _locating ? null : _locate,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: const Text('Vị trí hiện tại'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(CloudUi.controlHeight),
            ),
          ),
          const SizedBox(height: CloudUi.standard),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Tên nơi cất giữ',
              hintText: 'Ví dụ: Thư viện tầng 2 - Kệ B3',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
          ),
          const SizedBox(height: CloudUi.small),
          Wrap(
            spacing: CloudUi.small,
            runSpacing: CloudUi.tight,
            children: [
              for (final s in _presets)
                ActionChip(
                  label: Text(s),
                  onPressed: () => setState(() {
                    _name.text = s;
                    _name.selection = TextSelection.collapsed(offset: s.length);
                  }),
                ),
            ],
          ),
          const SizedBox(height: CloudUi.section),
          FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Xác nhận vị trí'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(CloudUi.controlHeight),
            ),
          ),
          const SizedBox(height: CloudUi.small),
          TextButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.location_off_outlined),
            label: const Text('Xóa vị trí'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              minimumSize: const Size.fromHeight(CloudUi.controlHeight),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn vị trí')),
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  Expanded(child: _buildMap()),
                  const VerticalDivider(width: 1),
                  SizedBox(width: 380, child: _buildForm()),
                ],
              )
            : Column(
                children: [
                  Expanded(flex: 5, child: _buildMap()),
                  const Divider(height: 1),
                  Expanded(flex: 6, child: _buildForm()),
                ],
              ),
      ),
    );
  }
}
