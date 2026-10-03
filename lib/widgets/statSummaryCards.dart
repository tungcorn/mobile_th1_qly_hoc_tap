import 'package:flutter/material.dart';
import '../colors.dart';
import '../struct/documentService.dart';

/// [StatSummaryCards]: Thanh tóm tắt số liệu tối giản, thanh lịch theo chuẩn Material Design 3.
/// Thiết kế dạng Segmented Bar gọn gàng, giảm thiểu diện tích chiếm dụng và không gây rối mắt.
class StatSummaryCards extends StatelessWidget {
  final DocumentStats stats;
  final bool isPendingActive;
  final bool isFavoriteActive;
  final VoidCallback? onTotalTap;
  final VoidCallback? onPendingTap;
  final VoidCallback? onFavoriteTap;

  const StatSummaryCards({
    super.key,
    required this.stats,
    this.isPendingActive = false,
    this.isFavoriteActive = false,
    this.onTotalTap,
    this.onPendingTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAllActive = !isPendingActive && !isFavoriteActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.7),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 1. Phân đoạn: Tổng tài liệu
            Expanded(
              child: _MetricSegment(
                label: 'Tài liệu',
                count: stats.totalCount,
                icon: Icons.folder_outlined,
                isActive: isAllActive,
                activeColor: theme.colorScheme.primary,
                onTap: onTotalTap,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 8,
              endIndent: 8,
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),

            // 2. Phân đoạn: Bài tập chờ
            Expanded(
              child: _MetricSegment(
                label: 'Bài tập chờ',
                count: stats.pendingAssignmentCount,
                icon: Icons.assignment_outlined,
                isActive: isPendingActive,
                activeColor: stats.overdueAssignmentCount > 0 ? AppColors.error : AppColors.tertiary,
                badgeCount: stats.overdueAssignmentCount > 0 ? stats.overdueAssignmentCount : null,
                onTap: onPendingTap,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 8,
              endIndent: 8,
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),

            // 3. Phân đoạn: Quan trọng
            Expanded(
              child: _MetricSegment(
                label: 'Quan trọng',
                count: stats.favoriteCount,
                icon: Icons.star_border_rounded,
                isActive: isFavoriteActive,
                activeColor: AppColors.tertiary,
                onTap: onFavoriteTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricSegment extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final int? badgeCount;
  final VoidCallback? onTap;

  const _MetricSegment({
    required this.label,
    required this.count,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    this.badgeCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? activeColor : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isActive ? activeColor : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (badgeCount != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$badgeCount!',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? activeColor : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
