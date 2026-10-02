import 'package:flutter/material.dart';
import '../colors.dart';
import '../functions.dart';
import '../struct/documentModels.dart';
import 'subjectBadge.dart';
import 'typeBadge.dart';

/// [DocumentCard]: Thẻ hiển thị tài liệu học tập theo chuẩn Material Design 3,
/// hỗ trợ 2 chế độ hiển thị: Thẻ chi tiết (Standard Card) và Dòng thu gọn (Compact Item).
class DocumentCard extends StatelessWidget {
  final DocumentWithSubject item;
  final bool isCompact;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onToggleCompleted;

  const DocumentCard({
    super.key,
    required this.item,
    this.isCompact = false,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onEdit,
    required this.onDelete,
    this.onToggleCompleted,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactItem(context);
    }
    return _buildStandardCard(context);
  }

  /// 1. Giao diện Thẻ Chuẩn (Standard Card View)
  Widget _buildStandardCard(BuildContext context) {
    final theme = Theme.of(context);
    final doc = item.document;
    final deadlineStatus = doc.deadline != null
        ? AppFunctions.getDeadlineStatus(doc.deadline, isCompleted: doc.isCompleted)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng 1: Môn học + Phân loại + Nút Yêu thích
              Row(
                children: [
                  SubjectBadge(
                    name: item.subjectName,
                    code: item.subjectCode,
                    color: item.subjectColor,
                  ),
                  const SizedBox(width: 6),
                  TypeBadge(type: item.type, isSmall: true),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 22,
                      color: doc.isFavorite ? AppColors.tertiary : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: doc.isFavorite ? 'Bỏ đánh dấu quan trọng' : 'Đánh dấu quan trọng',
                    onPressed: onFavoriteToggle,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Hàng 2: Tiêu đề tài liệu
              Text(
                doc.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: -0.1,
                  decoration: doc.isCompleted ? TextDecoration.lineThrough : null,
                  color: doc.isCompleted
                      ? theme.colorScheme.onSurface.withOpacity(0.5)
                      : theme.colorScheme.onSurface,
                ),
              ),

              // Hàng 3: Ghi chú vắn tắt (nếu có)
              if (doc.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  doc.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                    height: 1.35,
                  ),
                ),
              ],

              // Hàng 4: Hạn nộp bài tập (Deadline Banner)
              if (deadlineStatus != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: deadlineStatus['containerColor'] as Color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        doc.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        size: 13,
                        color: deadlineStatus['color'] as Color,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${deadlineStatus['label']} (${AppFunctions.formatDate(doc.deadline)})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: deadlineStatus['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Hàng 5: Thông tin tệp & Thao tác nhanh
              Row(
                children: [
                  // Định dạng tệp
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      doc.fileType.isNotEmpty ? doc.fileType : 'LINK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Dung lượng hoặc loại tệp
                  Text(
                    AppFunctions.formatFileSize(doc.fileSize),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                  const Spacer(),
                  // Thời gian cập nhật
                  Text(
                    AppFunctions.formatRelativeTime(doc.dateModified),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Menu tùy chọn
                  _buildPopupMenu(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2. Giao diện Dòng Thu Gọn (Compact View)
  Widget _buildCompactItem(BuildContext context) {
    final theme = Theme.of(context);
    final doc = item.document;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline, width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: item.type.containerColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.type.icon, color: item.type.color, size: 20),
        ),
        title: Text(
          doc.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            decoration: doc.isCompleted ? TextDecoration.lineThrough : null,
            color: doc.isCompleted
                ? theme.colorScheme.onSurface.withOpacity(0.5)
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '${item.subjectName} • ${AppFunctions.formatRelativeTime(doc.dateModified)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                size: 20,
                color: doc.isFavorite ? AppColors.tertiary : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onFavoriteToggle,
            ),
            _buildPopupMenu(context),
          ],
        ),
      ),
    );
  }

  /// Menu popup thao tác
  Widget _buildPopupMenu(BuildContext context) {
    final doc = item.document;
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'view':
            onTap();
            break;
          case 'toggleCompleted':
            onToggleCompleted?.call();
            break;
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18),
              SizedBox(width: 8),
              Text('Xem chi tiết', style: TextStyle(fontSize: 13.5)),
            ],
          ),
        ),
        if (item.type == DocumentType.assignment)
          PopupMenuItem(
            value: 'toggleCompleted',
            child: Row(
              children: [
                Icon(
                  doc.isCompleted ? Icons.restart_alt_rounded : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: doc.isCompleted ? AppColors.secondary : AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  doc.isCompleted ? 'Đánh dấu chưa nộp' : 'Đánh dấu đã nộp',
                  style: const TextStyle(fontSize: 13.5),
                ),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Chỉnh sửa', style: TextStyle(fontSize: 13.5)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
              SizedBox(width: 8),
              Text('Xóa tài liệu', style: TextStyle(fontSize: 13.5, color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}
