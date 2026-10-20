import 'package:flutter/material.dart';

import '../cloud/recommendationEngine.dart';
import '../cloud/supabaseDocumentService.dart';
import '../widgets/cloudDocumentDetailSheet.dart';
import '../widgets/cloudUi.dart';
import '../widgets/tagInput.dart';

/// Thân trang "Khám phá": gợi ý cá nhân hóa + tài liệu công khai.
/// Không có Scaffold riêng — được nhúng vào khung điều hướng của trang Supabase.
class DiscoverView extends StatefulWidget {
  final SupabaseDocumentService service;

  const DiscoverView({super.key, required this.service});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  /// Sở thích lưu trong bộ nhớ (giữ nguyên khi chuyển tab trong phiên).
  static final Set<String> _favoriteTags = {};

  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;

  List<SupabaseDocument> _accessible = [];
  List<SupabaseDocument> _public = [];
  List<String> _viewedIds = [];
  List<String> _allTags = [];
  final Set<String> _filterTags = {};
  List<Recommendation> _recs = [];
  Map<String, SupabaseDocument> _byId = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.service.getDocuments(),
        widget.service.getPublicDocuments(),
        widget.service.getViewedDocumentIds().catchError((_) => <String>[]),
        widget.service.getAllTags().catchError((_) => <String>[]),
      ]);
      if (!mounted) return;
      _accessible = results[0] as List<SupabaseDocument>;
      // Hiển thị tất cả tài liệu công khai của người khác; nếu đã được cấp quyền thì giữ quyền, chưa có thì gán 'none'
      final accessibleMap = {for (final d in _accessible) d.id: d};
      _public = [
        for (final d in results[1] as List<SupabaseDocument>)
          accessibleMap[d.id] ?? documentWithPermission(d, 'none'),
      ];
      _viewedIds = results[2] as List<String>;
      _allTags = results[3] as List<String>;
      _byId = {for (final d in [..._accessible, ..._public]) d.id: d};
      _filterTags.removeWhere((t) => !_allTags.contains(t));
      _recompute();
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = cloudErrorText(e);
      });
    }
  }

  RecItem _toRec(SupabaseDocument d) => RecItem(
        id: d.id,
        ownerId: d.ownerId,
        title: d.title,
        tags: d.tags,
        viewCount: d.viewCount,
        createdAt: d.createdAt,
      );

  void _recompute() {
    final owned = _accessible.where((d) => d.isOwner).map(_toRec).toList();
    final viewedSet = _viewedIds.toSet();
    final viewed = _byId.values
        .where((d) => viewedSet.contains(d.id))
        .map(_toRec)
        .toList();
    final candidateIds = <String>{};
    final candidates = <RecItem>[];
    for (final d in [..._public, ..._accessible.where((d) => !d.isOwner)]) {
      if (candidateIds.add(d.id)) {
        candidates.add(_toRec(d));
      }
    }
    _recs = RecommendationEngine.recommend(
      userId: widget.service.currentUserId,
      owned: owned,
      viewed: viewed,
      candidates: candidates,
      favoriteTags: _favoriteTags.toList(),
    );
  }

  void _toggleFavorite(String tag) {
    setState(() {
      if (!_favoriteTags.remove(tag)) _favoriteTags.add(tag);
      _recompute();
    });
  }

  void _toggleFilter(String tag) {
    setState(() {
      if (!_filterTags.remove(tag)) _filterTags.add(tag);
    });
  }

  List<SupabaseDocument> get _filteredPublic {
    final q = _searchController.text.trim().toLowerCase();
    final wanted = _filterTags.map((t) => t.toLowerCase()).toSet();
    return _public.where((d) {
      if (wanted.isNotEmpty) {
        final tags = d.tags.map((t) => t.toLowerCase()).toSet();
        if (!tags.containsAll(wanted)) return false;
      }
      if (q.isEmpty) return true;
      return d.title.toLowerCase().contains(q) ||
          d.description.toLowerCase().contains(q) ||
          d.fileName.toLowerCase().contains(q) ||
          d.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  void _open(SupabaseDocument doc) {
    showCloudDocumentDetail(
      context,
      service: widget.service,
      doc: doc,
      onChanged: _load,
    );
  }

  int _columns(double width) => width < 600 ? 1 : (width < 1000 ? 2 : 3);

  Widget _sectionTitle(String text, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          CloudUi.standard, CloudUi.section, CloudUi.standard, CloudUi.small),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _errorBody() {
    final needsMigration = _error!.contains('th2_migration.sql');
    return ListView(
      padding: const EdgeInsets.all(CloudUi.standard),
      children: [
        CloudMessage(
          title: needsMigration
              ? 'Cơ sở dữ liệu chưa được nâng cấp'
              : 'Không tải được dữ liệu khám phá',
          message: needsMigration
              ? 'Tính năng Khám phá cần các cột và bảng mới của TH2. '
                  'Hãy mở Supabase Dashboard → SQL Editor và chạy tệp '
                  'supabase/th2_migration.sql, sau đó bấm Thử lại.\n\nChi tiết: $_error'
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

  @override
  Widget build(BuildContext context) {
    if (_loading && _byId.isEmpty && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) return _errorBody();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final publicDocs = _filteredPublic;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = _columns(constraints.maxWidth);
        return RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_loading)
                const SliverToBoxAdapter(child: LinearProgressIndicator()),
              SliverToBoxAdapter(
                child: _sectionTitle(
                  'Gợi ý cho bạn',
                  trailing: IconButton(
                    tooltip: 'Làm mới',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loading ? null : _load,
                  ),
                ),
              ),
              // Sở thích của tôi
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CloudUi.standard),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sở thích của tôi',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: CloudUi.tight),
                      if (_allTags.isEmpty)
                        Text(
                          'Chưa có tag nào. Thêm tag cho tài liệu để nhận gợi ý chính xác hơn.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        )
                      else
                        TagChips(
                          tags: _allTags,
                          selected: _favoriteTags,
                          onTap: _toggleFavorite,
                        ),
                      const SizedBox(height: CloudUi.medium),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _recs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: CloudUi.standard),
                        child: const CloudMessage(
                          title: 'Chưa có gợi ý',
                          message:
                              'Chưa có tài liệu công khai hoặc được chia sẻ phù hợp. '
                              'Hãy chọn sở thích hoặc quay lại sau.',
                        ),
                      )
                    : SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: CloudUi.standard),
                          itemCount: _recs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: CloudUi.medium),
                          itemBuilder: (_, i) {
                            final r = _recs[i];
                            final doc = _byId[r.item.id];
                            return SizedBox(
                              width: 280,
                              child: _RecommendationCard(
                                rec: r,
                                ownerEmail: doc?.ownerEmail,
                                onTap: doc == null ? null : () => _open(doc),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              SliverToBoxAdapter(
                child: _sectionTitle('Khám phá tài liệu công khai'),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CloudUi.standard),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Tìm tài liệu công khai',
                          hintText: 'Tiêu đề, mô tả, tên tệp hoặc tag',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Xóa tìm kiếm',
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: _searchController.clear,
                                ),
                        ),
                      ),
                      if (_allTags.isNotEmpty) ...[
                        const SizedBox(height: CloudUi.small),
                        Text('Lọc theo tag',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: CloudUi.tight),
                        TagChips(
                          tags: _allTags,
                          selected: _filterTags,
                          onTap: _toggleFilter,
                        ),
                      ],
                      const SizedBox(height: CloudUi.medium),
                    ],
                  ),
                ),
              ),
              if (publicDocs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: CloudUi.standard),
                    child: CloudMessage(
                      title: 'Không có tài liệu',
                      message: _public.isEmpty
                          ? 'Chưa có người dùng nào công khai tài liệu.'
                          : 'Không có tài liệu công khai khớp với bộ lọc.',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CloudUi.standard),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: CloudUi.medium,
                      crossAxisSpacing: CloudUi.medium,
                      mainAxisExtent: 168,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _PublicDocCard(
                        doc: publicDocs[i],
                        onTap: () => _open(publicDocs[i]),
                      ),
                      childCount: publicDocs.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: CloudUi.section)),
            ],
          ),
        );
      },
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Recommendation rec;
  final String? ownerEmail;
  final VoidCallback? onTap;

  const _RecommendationCard({required this.rec, this.ownerEmail, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = (rec.score.clamp(0.0, 1.0) * 100).round();
    final tags = RecommendationEngine.normalizeTags(rec.item.tags);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CloudUi.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      rec.item.title.isEmpty
                          ? '(Không có tiêu đề)'
                          : rec.item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: CloudUi.small),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: CloudUi.small, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$percent%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CloudUi.tight),
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 16, color: scheme.primary),
                  const SizedBox(width: CloudUi.tight),
                  Expanded(
                    child: Text(
                      rec.reason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.primary),
                    ),
                  ),
                ],
              ),
              if (ownerEmail != null) ...[
                const SizedBox(height: CloudUi.tight),
                Text(
                  ownerEmail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              const Spacer(),
              ClipRect(
                child: SizedBox(
                  height: 60,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: TagChips(
                      tags: tags,
                      selected: rec.matchedTags.toSet(),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.visibility_outlined,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: CloudUi.tight),
                  Text('${rec.item.viewCount} lượt xem',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicDocCard extends StatelessWidget {
  final SupabaseDocument doc;
  final VoidCallback onTap;

  const _PublicDocCard({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CloudUi.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      doc.title.isEmpty ? '(Không có tiêu đề)' : doc.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (doc.permissionLevel == 'viewer' || doc.permissionLevel == 'editor') ...[
                    const SizedBox(width: CloudUi.tight),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade300, width: 0.8),
                      ),
                      child: Text(
                        'Đã có quyền',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (doc.description.isNotEmpty)
                Text(
                  doc.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: CloudUi.tight),
              Text(
                doc.ownerEmail ?? (doc.ownerId.isNotEmpty ? doc.ownerId : 'Không rõ chủ sở hữu'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              ClipRect(
                child: SizedBox(
                  height: 32,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: TagChips(tags: doc.tags),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.visibility_outlined,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: CloudUi.tight),
                  Text('${doc.viewCount}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  if (doc.hasLocation) ...[
                    const SizedBox(width: CloudUi.medium),
                    Icon(Icons.place_outlined,
                        size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: CloudUi.tight),
                    Expanded(
                      child: Text(
                        doc.locationName ?? 'Có vị trí',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
