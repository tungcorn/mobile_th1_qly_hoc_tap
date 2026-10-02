import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../colors.dart';
import '../functions.dart';
import '../struct/databaseGlobal.dart';
import '../struct/documentModels.dart';
import '../struct/documentService.dart';
import '../widgets/subjectBadge.dart';
import '../widgets/typeBadge.dart';
import 'addEditDocumentPage.dart';

/// [DocumentDetailPage]: Màn hình xem chi tiết tài liệu học tập
class DocumentDetailPage extends StatefulWidget {
  final String documentId;

  const DocumentDetailPage({super.key, required this.documentId});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  DocumentWithSubject? _item;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() => _isLoading = true);
    final item = await database.getDocumentWithSubject(widget.documentId);
    if (mounted) {
      setState(() {
        _item = item;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await AppFunctions.showConfirmDialog(
      context,
      title: 'Xóa tài liệu',
      message: 'Bạn có chắc chắn muốn xóa tài liệu "${_item?.title}"? Hành động này không thể hoàn tác.',
      confirmText: 'Xóa',
      confirmColor: AppColors.error,
    );

    if (confirmed == true && mounted) {
      await DocumentService.deleteDocument(widget.documentId);
      if (mounted) {
        AppFunctions.showCustomSnackbar(context, 'Đã xóa tài liệu thành công.');
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_item == null) return;
    await DocumentService.toggleFavorite(_item!.id, _item!.isFavorite);
    _loadDocument();
  }

  Future<void> _toggleCompleted() async {
    if (_item == null) return;
    await DocumentService.toggleCompleted(_item!.id, _item!.isCompleted);
    _loadDocument();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết tài liệu')),
        body: const Center(child: Text('Không tìm thấy tài liệu này.')),
      );
    }

    final doc = _item!.document;
    final deadlineStatus = doc.deadline != null
        ? AppFunctions.getDeadlineStatus(doc.deadline, isCompleted: doc.isCompleted)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Tài liệu'),
        actions: [
          IconButton(
            icon: Icon(
              doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: doc.isFavorite ? AppColors.tertiary : null,
            ),
            tooltip: doc.isFavorite ? 'Bỏ đánh dấu' : 'Đánh dấu quan trọng',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Chỉnh sửa',
            onPressed: () async {
              final updated = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditDocumentPage(documentToEdit: doc),
                ),
              );
              if (updated == true) {
                _loadDocument();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Xóa',
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Phân loại & Môn học
          Row(
            children: [
              SubjectBadge(
                name: _item!.subjectName,
                code: _item!.subjectCode,
                color: _item!.subjectColor,
              ),
              const SizedBox(width: 8),
              TypeBadge(type: _item!.type),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Tiêu đề tài liệu
          Text(
            doc.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              decoration: doc.isCompleted ? TextDecoration.lineThrough : null,
              color: doc.isCompleted
                  ? theme.colorScheme.onSurface.withOpacity(0.5)
                  : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // 3. Khối Deadline nếu là Bài tập
          if (doc.type == DocumentType.assignment && deadlineStatus != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: deadlineStatus['containerColor'] as Color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (deadlineStatus['color'] as Color).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    doc.isCompleted ? Icons.check_circle_rounded : Icons.alarm_rounded,
                    color: deadlineStatus['color'] as Color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deadlineStatus['label'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: deadlineStatus['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hạn chót: ${AppFunctions.formatDateTime(doc.deadline)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: _toggleCompleted,
                    child: Text(
                      doc.isCompleted ? 'Chưa nộp' : 'Đã nộp bài',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: doc.isCompleted ? AppColors.secondary : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Khối Thông tin Tệp & Đường dẫn
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insert_drive_file_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Tệp & Liên kết đính kèm',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        doc.fileType.isNotEmpty ? doc.fileType : 'LINK',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppFunctions.formatFileSize(doc.fileSize),
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                if (doc.fileUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            doc.fileUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          tooltip: 'Sao chép liên kết',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: doc.fileUrl));
                            AppFunctions.showCustomSnackbar(context, 'Đã sao chép liên kết vào bộ nhớ tạm.');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Ghi chú nội dung
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notes_rounded, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Ghi chú & Tóm tắt',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  doc.note.isNotEmpty ? doc.note : 'Chưa có ghi chú nào cho tài liệu này.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: doc.note.isNotEmpty
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. Siêu dữ liệu ngày tạo & cập nhật
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ngày tạo: ${AppFunctions.formatDateTime(doc.dateCreated)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cập nhật lần cuối: ${AppFunctions.formatDateTime(doc.dateModified)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
