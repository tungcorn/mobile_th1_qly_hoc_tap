import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../cloud/supabaseDocumentService.dart';
import '../widgets/cloudDocumentDetailSheet.dart';
import '../widgets/cloudUi.dart';
import '../widgets/documentMapView.dart';
import '../widgets/tagInput.dart';

enum _MapFilter { all, mine, shared, public }

extension on _MapFilter {
  String get label => switch (this) {
        _MapFilter.all => 'Tất cả',
        _MapFilter.mine => 'Của tôi',
        _MapFilter.shared => 'Được chia sẻ',
        _MapFilter.public => 'Công khai',
      };
}

/// Thân trang "Bản đồ": mọi tài liệu có vị trí (của tôi, được chia sẻ, công khai).
/// Không có Scaffold riêng — được nhúng vào khung điều hướng của trang Supabase.
class DocumentMapPage extends StatefulWidget {
  final SupabaseDocumentService service;

  const DocumentMapPage({super.key, required this.service});

  @override
  State<DocumentMapPage> createState() => _DocumentMapPageState();
}

class _DocumentMapPageState extends State<DocumentMapPage> {
  static const double _wideBreakpoint = 840;

  bool _loading = true;
  String? _error;
  List<SupabaseDocument> _docs = [];
  _MapFilter _filter = _MapFilter.all;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.service.getDocuments(),
        widget.service.getPublicDocuments(),
      ]);
      if (!mounted) return;
      setState(() {
        _docs = mergeAccessibleAndPublic(results[0], results[1])
            .where((d) => d.hasLocation)
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = cloudErrorText(e);
      });
    }
  }

  List<SupabaseDocument> get _visible => _docs.where((d) {
        switch (_filter) {
          case _MapFilter.all:
            return true;
          case _MapFilter.mine:
            return d.isOwner;
          case _MapFilter.shared:
            return !d.isOwner &&
                (d.permissionLevel == 'viewer' ||
                    d.permissionLevel == 'editor');
          case _MapFilter.public:
            return d.isPublic;
        }
      }).toList();

  void _open(SupabaseDocument doc) {
    setState(() => _selectedId = doc.id);
    showCloudDocumentDetail(
      context,
      service: widget.service,
      doc: doc,
      onChanged: _load,
    );
  }

  Widget _filterBar(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          CloudUi.standard, CloudUi.small, CloudUi.small, CloudUi.small),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in _MapFilter.values) ...[
                    ChoiceChip(
                      label: Text(f.label),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                    const SizedBox(width: CloudUi.small),
                  ],
                ],
              ),
            ),
          ),
          Text('$count tài liệu',
              style: Theme.of(context).textTheme.labelMedium),
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
    );
  }

  List<Widget> _docTiles(List<SupabaseDocument> docs) {
    if (docs.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(CloudUi.standard),
          child: CloudMessage(
            title: 'Chưa có tài liệu có vị trí',
            message:
                'Thêm vị trí khi tạo hoặc sửa tài liệu để hiển thị trên bản đồ.',
          ),
        ),
      ];
    }
    return [
      for (final d in docs)
        ListTile(
          selected: d.id == _selectedId,
          leading: Icon(d.isOwner
              ? Icons.person_pin_circle_outlined
              : d.isPublic
                  ? Icons.public_rounded
                  : Icons.share_location_rounded),
          title: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.locationName ??
                    '${d.latitude!.toStringAsFixed(4)}, ${d.longitude!.toStringAsFixed(4)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (d.tags.isNotEmpty) ...[
                const SizedBox(height: CloudUi.tight),
                TagChips(tags: d.tags.take(4).toList()),
              ],
            ],
          ),
          onTap: () => _open(d),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      final needsMigration = _error!.contains('th2_migration.sql');
      return ListView(
        padding: const EdgeInsets.all(CloudUi.standard),
        children: [
          CloudMessage(
            title: needsMigration
                ? 'Cơ sở dữ liệu chưa được nâng cấp'
                : 'Không tải được bản đồ tài liệu',
            message: needsMigration
                ? 'Chạy tệp supabase/th2_migration.sql trong Supabase Dashboard → SQL Editor để thêm cột vị trí.\n\nChi tiết: $_error'
                : _error!,
            isError: !needsMigration,
            isWarning: needsMigration,
            action: FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }

    final docs = _visible;
    final markers = [
      for (final d in docs)
        MapMarkerData(
          id: d.id,
          title: d.title,
          subtitle: d.locationName ?? '',
          point: LatLng(d.latitude!, d.longitude!),
        ),
    ];
    final byId = {for (final d in docs) d.id: d};
    final map = DocumentMapView(
      markers: markers,
      onTap: (m) {
        final d = byId[m.id];
        if (d != null) _open(d);
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideBreakpoint;
        return Column(
          children: [
            _filterBar(docs.length),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: wide
                  ? Row(
                      children: [
                        SizedBox(
                          width: 340,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                                vertical: CloudUi.small),
                            children: _docTiles(docs),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: map),
                      ],
                    )
                  : Stack(
                      children: [
                        Positioned.fill(child: map),
                        DraggableScrollableSheet(
                          initialChildSize: 0.3,
                          minChildSize: 0.12,
                          maxChildSize: 0.85,
                          builder: (context, controller) => Material(
                            elevation: 3,
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            clipBehavior: Clip.antiAlias,
                            child: ListView(
                              controller: controller,
                              padding: EdgeInsets.zero,
                              children: [
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: CloudUi.small),
                                    width: 32,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                ..._docTiles(docs),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
