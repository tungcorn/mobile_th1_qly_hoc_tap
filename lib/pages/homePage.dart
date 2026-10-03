import 'package:flutter/material.dart';
import '../colors.dart';
import '../functions.dart';
import '../struct/databaseGlobal.dart';
import '../struct/documentModels.dart';
import '../struct/documentService.dart';
import '../struct/settings.dart';
import '../widgets/documentCard.dart';
import '../widgets/emptyStateView.dart';
import '../widgets/searchFilterBar.dart';
import '../widgets/statSummaryCards.dart';
import 'addEditDocumentPage.dart';
import 'documentDetailPage.dart';
import 'subjectsPage.dart';

/// [HomePage]: Màn hình chính của ứng dụng Quản lý Tài liệu Học tập theo kiến trúc Cashew.
/// Giao diện Material 3 trang nhã, phân tách lớp hoàn chỉnh, cập nhật dữ liệu Reactive tức thời.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  String? _selectedSubjectId; // null hoặc 'all' nghĩa là Tất cả môn
  DocumentType? _selectedType;
  String _searchQuery = '';
  bool _onlyFavorites = false;
  bool _onlyPending = false;

  late Stream<List<SubjectItem>> _subjectsStream;
  late Stream<List<DocumentWithSubject>> _statsStream;
  late Stream<List<DocumentWithSubject>> _documentsStream;

  @override
  void initState() {
    super.initState();
    _subjectsStream = database.watchAllSubjects();
    _statsStream = database.watchFilteredDocuments();
    _updateDocumentsStream();
  }

  void _updateDocumentsStream() {
    _documentsStream = database.watchFilteredDocuments(
      subjectId: _selectedSubjectId,
      type: _selectedType,
      searchQuery: _searchQuery,
      onlyFavorites: _onlyFavorites ? true : null,
      onlyPending: _onlyPending ? true : null,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedSubjectId = null;
      _selectedType = null;
      _searchQuery = '';
      _onlyFavorites = false;
      _onlyPending = false;
      _searchController.clear();
      _updateDocumentsStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quản lý Tài liệu Học tập',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            Text(
              'Kiến trúc Cashew • Material Design 3',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
        ),
        actions: [
          // Nút chuyển chế độ xem (Card / Compact)
          ValueListenableBuilder<bool>(
            valueListenable: AppSettings.isCompactViewNotifier,
            builder: (context, isCompact, _) {
              return IconButton(
                icon: Icon(
                  isCompact ? Icons.view_agenda_outlined : Icons.view_headline_rounded,
                  size: 21,
                ),
                tooltip: isCompact ? 'Chế độ thẻ chi tiết' : 'Chế độ dòng thu gọn',
                onPressed: AppSettings.toggleViewMode,
              );
            },
          ),
          // Nút chuyển chế độ Sáng / Tối
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppSettings.themeModeNotifier,
            builder: (context, themeMode, _) {
              final isDark = themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 21),
                tooltip: isDark ? 'Chuyển sang giao diện Sáng' : 'Chuyển sang giao diện Tối',
                onPressed: AppSettings.toggleTheme,
              );
            },
          ),
          // Nút Quản lý Môn học
          IconButton(
            icon: const Icon(Icons.school_outlined, size: 21),
            tooltip: 'Quản lý Môn học',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubjectsManagementPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditDocumentPage()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm tài liệu', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // 1. Thanh tóm tắt số liệu tối giản (Segmented Metric Bar)
            SliverToBoxAdapter(
              child: StreamBuilder<List<DocumentWithSubject>>(
                stream: _statsStream,
                builder: (context, snapshot) {
                  final allDocs = snapshot.data ?? [];
                  final stats = DocumentStats.fromDocuments(allDocs);
                  return StatSummaryCards(
                    stats: stats,
                    isPendingActive: _onlyPending,
                    isFavoriteActive: _onlyFavorites,
                    onTotalTap: _resetFilters,
                    onPendingTap: () {
                      setState(() {
                        _onlyPending = !_onlyPending;
                        _onlyFavorites = false;
                        _selectedType = _onlyPending ? DocumentType.assignment : null;
                        _updateDocumentsStream();
                      });
                    },
                    onFavoriteTap: () {
                      setState(() {
                        _onlyFavorites = !_onlyFavorites;
                        _onlyPending = false;
                        _updateDocumentsStream();
                      });
                    },
                  );
                },
              ),
            ),

            // 2. Thanh Tìm kiếm kết hợp Dải lọc Môn học & Loại tài liệu thống nhất
            SliverToBoxAdapter(
              child: StreamBuilder<List<SubjectItem>>(
                stream: _subjectsStream,
                builder: (context, snapshot) {
                  final subjects = snapshot.data ?? [];
                  return SearchFilterBar(
                    searchController: _searchController,
                    onSearchChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _updateDocumentsStream();
                      });
                    },
                    onClearSearch: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _updateDocumentsStream();
                      });
                    },
                    selectedType: _selectedType,
                    onTypeSelected: (type) {
                      setState(() {
                        _selectedType = type;
                        _updateDocumentsStream();
                      });
                    },
                    subjects: subjects,
                    selectedSubjectId: _selectedSubjectId,
                    onSubjectSelected: (subId) {
                      setState(() {
                        _selectedSubjectId = subId;
                        _updateDocumentsStream();
                      });
                    },
                  );
                },
              ),
            ),

            // 3. Chỉ báo bộ lọc đang kích hoạt tinh gọn (nếu có)
            if (_onlyFavorites || _onlyPending)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _onlyFavorites ? Icons.star_rounded : Icons.schedule_rounded,
                              size: 13,
                              color: _onlyFavorites ? AppColors.tertiary : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _onlyFavorites ? 'Chỉ xem tài liệu Quan trọng' : 'Chỉ xem Bài tập chưa hoàn thành',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _onlyFavorites = false;
                                  _onlyPending = false;
                                  _updateDocumentsStream();
                                });
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ];
        },
        body: StreamBuilder<List<DocumentWithSubject>>(
          stream: _documentsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              final isSearching = _searchQuery.isNotEmpty ||
                  _selectedSubjectId != null ||
                  _selectedType != null ||
                  _onlyFavorites ||
                  _onlyPending;

              return EmptyStateView(
                icon: isSearching ? Icons.search_off_rounded : Icons.library_books_outlined,
                title: isSearching ? 'Không tìm thấy tài liệu phù hợp' : 'Chưa có tài liệu nào',
                description: isSearching
                    ? 'Thử thay đổi từ khóa tìm kiếm hoặc đặt lại các bộ lọc đang chọn.'
                    : 'Bắt đầu thêm tài liệu học tập đầu tiên của bạn bằng nút bên dưới.',
                actionText: isSearching ? 'Đặt lại bộ lọc' : 'Thêm tài liệu ngay',
                onAction: isSearching
                    ? _resetFilters
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AddEditDocumentPage()),
                        );
                      },
              );
            }

            return ValueListenableBuilder<bool>(
              valueListenable: AppSettings.isCompactViewNotifier,
              builder: (context, isCompact, _) {
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return DocumentCard(
                      item: item,
                      isCompact: isCompact,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DocumentDetailPage(documentId: item.id),
                          ),
                        );
                      },
                      onFavoriteToggle: () {
                        DocumentService.toggleFavorite(item.id, item.isFavorite);
                      },
                      onToggleCompleted: item.type == DocumentType.assignment
                          ? () {
                              DocumentService.toggleCompleted(item.id, item.isCompleted);
                            }
                          : null,
                      onEdit: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddEditDocumentPage(documentToEdit: item.document),
                          ),
                        );
                      },
                      onDelete: () async {
                        final confirmed = await AppFunctions.showConfirmDialog(
                          context,
                          title: 'Xóa tài liệu',
                          message: 'Bạn có chắc chắn muốn xóa "${item.title}"?',
                          confirmText: 'Xóa',
                          confirmColor: AppColors.error,
                        );
                        if (confirmed == true) {
                          await DocumentService.deleteDocument(item.id);
                          if (context.mounted) {
                            AppFunctions.showCustomSnackbar(context, 'Đã xóa tài liệu.');
                          }
                        }
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
