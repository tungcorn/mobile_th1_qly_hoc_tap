import 'package:flutter/material.dart';
import '../colors.dart';
import '../functions.dart';
import '../struct/documentModels.dart';

/// [DocumentCard]: Thẻ hiển thị tài liệu học tập theo chuẩn Material Design 3 tối giản,
/// tập trung vào khả năng đọc (Readability), loại bỏ các nút thừa gây rối mắt.
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

  /// 1. Giao diện Thẻ Chuẩn Tinh Gọn (Standard Card View)
  Widget _buildStandardCard(BuildContext context) {
    final theme = Theme.of(context);
    final doc = item.document;
    final deadlineStatus = doc.deadline != null
        ? AppFunctions.getDeadlineStatus(doc.deadline, isCompleted: doc.isCompleted)
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6.5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.65),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng 1: Môn học • Phân loại  +  Nút Yêu thích & Menu (...)
              Row(
                children: [
                  // Dấu chấm màu môn học
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: item.subjectColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Tên / Mã môn học
                  Flexible(
                    child: Text(
                      item.subjectCode.isNotEmpty ? item.subjectCode : item.subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '•',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Huy hiệu loại tài liệu dạng tonal tinh tế
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: item.type.containerColor.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.type.displayName,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: item.type.color,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Nút Đánh dấu quan trọng (Sao)
                  IconButton(
                    icon: Icon(
                      doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 20,
                      color: doc.isFavorite
                          ? AppColors.tertiary
                          : theme.colorScheme.onSurface.withOpacity(0.35),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: doc.isFavorite ? 'Bỏ quan trọng' : 'Đánh dấu quan trọng',
                    onPressed: onFavoriteToggle,
                  ),

                  // Menu tùy chọn tác vụ (3 chấm)
                  _buildPopupMenu(context),
                ],
              ),
              const SizedBox(height: 6),

              // Hàng 2: Tiêu đề tài liệu
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  doc.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    height: 1.3,
                    decoration: doc.isCompleted ? TextDecoration.lineThrough : null,
                    color: doc.isCompleted
                        ? theme.colorScheme.onSurface.withOpacity(0.45)
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),

              // Hàng 3: Ghi chú vắn tắt (nếu có)
              if (doc.note.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  doc.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],

              // Hàng 4: Metadata chân thẻ (Deadline, Định dạng tệp, Thời gian cập nhật)
              const SizedBox(height: 8),
              Row(
                children: [
                  // Nhãn Deadline (nếu có)
                  if (deadlineStatus != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (deadlineStatus['containerColor'] as Color).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            doc.isCompleted
                                ? Icons.check_circle_outline_rounded
                                : Icons.schedule_rounded,
                            size: 12,
                            color: deadlineStatus['color'] as Color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            doc.isCompleted
                                ? 'Đã hoàn thành'
                                : '${deadlineStatus['label']} (${AppFunctions.formatDate(doc.deadline)})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: deadlineStatus['color'] as Color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Nhãn Định dạng & Dung lượng tệp
                  if (doc.fileType.isNotEmpty || doc.fileSize > 0) ...[
                    Text(
                      doc.fileType.isNotEmpty
                          ? (doc.fileSize > 0
                              ? '${doc.fileType} • ${AppFunctions.formatFileSize(doc.fileSize)}'
                              : doc.fileType)
                          : AppFunctions.formatFileSize(doc.fileSize),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Thời gian cập nhật tương đối
                  Text(
                    AppFunctions.formatRelativeTime(doc.dateModified),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2. Giao diện Dòng Thu Gọn Tối Giản (Compact View)
  Widget _buildCompactItem(BuildContext context) {
    final theme = Theme.of(context);
    final doc = item.document;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2.5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: item.type.containerColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.type.icon, color: item.type.color, size: 16),
        ),
        title: Text(
          doc.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            decoration: doc.isCompleted ? TextDecoration.lineThrough : null,
            color: doc.isCompleted
                ? theme.colorScheme.onSurface.withOpacity(0.45)
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '${item.subjectName} • ${AppFunctions.formatRelativeTime(doc.dateModified)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                size: 18,
                color: doc.isFavorite
                    ? AppColors.tertiary
                    : theme.colorScheme.onSurface.withOpacity(0.35),
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              onPressed: onFavoriteToggle,
            ),
            _buildPopupMenu(context),
          ],
        ),
      ),
    );
  }

  /// Menu tùy chọn 3 chấm gọn gàng, chứa các tác vụ phụ
  Widget _buildPopupMenu(BuildContext context) {
    final theme = Theme.of(context);
    final doc = item.document;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tooltip: 'Tùy chọn tác vụ',
      onSelected: (value) {
        switch (value) {
          case 'toggle_complete':
            if (onToggleCompleted != null) onToggleCompleted!();
            break;
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        if (doc.type == DocumentType.assignment)
          PopupMenuItem<String>(
            value: 'toggle_complete',
            child: Row(
              children: [
                Icon(
                  doc.isCompleted
                      ? Icons.radio_button_unchecked_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: doc.isCompleted ? AppColors.tertiary : AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  doc.isCompleted ? 'Đánh dấu chưa nộp' : 'Đánh dấu đã hoàn thành',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Chỉnh sửa thông tin', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'Xóa tài liệu',
                style: TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
