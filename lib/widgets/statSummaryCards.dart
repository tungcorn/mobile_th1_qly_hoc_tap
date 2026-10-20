import 'package:flutter/material.dart';
import '../colors.dart';
import '../struct/documentService.dart';

/// [StatSummaryCards]: Thanh tóm tắt số liệu tối giản, thanh lịch theo chuẩn Material Design 3.
/// Thiết kế dạng Segmented Bar gọn gàng, icon + nhãn chữ + số đếm nằm trên cùng một hàng ngang,
/// giúp giao diện trực quan, khoa học và không bị lệch chữ hay kéo dãn bất hợp lý trên màn hình lớn.
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.55),
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
                    activeIcon: Icons.folder_rounded,
                    isActive: isAllActive,
                    activeColor: theme.colorScheme.primary,
                    onTap: onTotalTap,
                  ),
                ),
                if (!isAllActive && !isPendingActive)
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    indent: 8,
                    endIndent: 8,
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  )
                else
                  const SizedBox(width: 3),

                // 2. Phân đoạn: Bài tập chờ
                Expanded(
                  child: _MetricSegment(
                    label: 'Bài tập chờ',
                    count: stats.pendingAssignmentCount,
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment_rounded,
                    isActive: isPendingActive,
                    activeColor: stats.overdueAssignmentCount > 0 ? AppColors.error : AppColors.secondary,
                    badgeCount: stats.overdueAssignmentCount > 0 ? stats.overdueAssignmentCount : null,
                    onTap: onPendingTap,
                  ),
                ),
                if (!isPendingActive && !isFavoriteActive)
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    indent: 8,
                    endIndent: 8,
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  )
                else
                  const SizedBox(width: 3),

                // 3. Phân đoạn: Quan trọng
                Expanded(
                  child: _MetricSegment(
                    label: 'Quan trọng',
                    count: stats.favoriteCount,
                    icon: Icons.star_border_rounded,
                    activeIcon: Icons.star_rounded,
                    isActive: isFavoriteActive,
                    activeColor: AppColors.tertiary,
                    onTap: onFavoriteTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricSegment extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final IconData? activeIcon;
  final bool isActive;
  final Color activeColor;
  final int? badgeCount;
  final VoidCallback? onTap;

  const _MetricSegment({
    required this.label,
    required this.count,
    required this.icon,
    this.activeIcon,
    required this.isActive,
    required this.activeColor,
    this.badgeCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedIcon = isActive ? (activeIcon ?? icon) : icon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? activeColor.withOpacity(0.35) : Colors.transparent,
              width: 1.2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                displayedIcon,
                size: 15,
                color: isActive ? activeColor : theme.colorScheme.onSurface.withOpacity(0.65),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? activeColor : theme.colorScheme.onSurface.withOpacity(0.85),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Huy hiệu số lượng tài liệu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? activeColor.withOpacity(0.14)
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isActive ? activeColor : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              // Huy hiệu cảnh báo quá hạn (nếu có bài tập quá hạn)
              if (badgeCount != null && badgeCount! > 0) ...[
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$badgeCount!',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
