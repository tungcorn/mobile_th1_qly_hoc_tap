import 'package:flutter/material.dart';
import '../colors.dart';
import '../struct/documentService.dart';

/// [StatSummaryCards]: Khối thẻ tóm tắt nhanh số liệu học tập ở đầu trang chủ,
/// giúp sinh viên nắm bắt ngay tài liệu và bài tập cần làm.
class StatSummaryCards extends StatelessWidget {
  final DocumentStats stats;
  final VoidCallback? onTotalTap;
  final VoidCallback? onPendingTap;
  final VoidCallback? onFavoriteTap;

  const StatSummaryCards({
    super.key,
    required this.stats,
    this.onTotalTap,
    this.onPendingTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Thẻ 1: Tổng tài liệu
          Expanded(
            child: _StatCard(
              title: 'Tài liệu',
              count: stats.totalCount,
              icon: Icons.folder_open_rounded,
              iconColor: AppColors.primary,
              containerColor: AppColors.primaryContainer.withOpacity(0.4),
              onTap: onTotalTap,
            ),
          ),
          const SizedBox(width: 10),
          // Thẻ 2: Bài tập cần làm
          Expanded(
            child: _StatCard(
              title: 'Bài tập chờ',
              count: stats.pendingAssignmentCount,
              icon: Icons.assignment_late_outlined,
              iconColor: stats.overdueAssignmentCount > 0 ? AppColors.error : AppColors.tertiary,
              containerColor: stats.overdueAssignmentCount > 0
                  ? AppColors.errorContainer.withOpacity(0.4)
                  : AppColors.tertiaryContainer.withOpacity(0.4),
              subtitle: stats.overdueAssignmentCount > 0 ? '${stats.overdueAssignmentCount} quá hạn' : null,
              onTap: onPendingTap,
            ),
          ),
          const SizedBox(width: 10),
          // Thẻ 3: Đã lưu quan trọng
          Expanded(
            child: _StatCard(
              title: 'Quan trọng',
              count: stats.favoriteCount,
              icon: Icons.star_rounded,
              iconColor: AppColors.tertiary,
              containerColor: AppColors.tertiaryContainer.withOpacity(0.4),
              onTap: onFavoriteTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color iconColor;
  final Color containerColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.containerColor,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: containerColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                Text(
                  '$count',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
