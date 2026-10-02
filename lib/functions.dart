import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'colors.dart';

/// [Functions] tập hợp các hàm tiện ích dùng chung trên toàn ứng dụng,
/// tương tự như tập tin `functions.dart` trong mã nguồn Cashew gốc.
class AppFunctions {
  AppFunctions._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('HH:mm - dd/MM/yyyy');

  /// Định dạng ngày tháng năm: dd/MM/yyyy
  static String formatDate(DateTime? date) {
    if (date == null) return '--/--/----';
    return _dateFormat.format(date);
  }

  /// Định dạng ngày giờ: HH:mm - dd/MM/yyyy
  static String formatDateTime(DateTime? date) {
    if (date == null) return '--:--';
    return _dateTimeFormat.format(date);
  }

  /// Tính khoảng thời gian tương đối so với hiện tại
  static String formatRelativeTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return _dateFormat.format(date);
    }
  }

  /// Tính số ngày còn lại đối với hạn nộp bài tập (Deadline)
  static Map<String, dynamic> getDeadlineStatus(DateTime? deadline, {bool isCompleted = false}) {
    if (isCompleted) {
      return {
        'label': 'Đã hoàn thành',
        'color': AppColors.success,
        'containerColor': AppColors.successContainer,
        'isOverdue': false,
      };
    }
    if (deadline == null) {
      return {
        'label': 'Không có hạn',
        'color': AppColors.secondary,
        'containerColor': AppColors.secondaryContainer,
        'isOverdue': false,
      };
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final diffDays = deadlineDay.difference(today).inDays;

    if (diffDays < 0) {
      return {
        'label': 'Quá hạn ${diffDays.abs()} ngày',
        'color': AppColors.error,
        'containerColor': AppColors.errorContainer,
        'isOverdue': true,
      };
    } else if (diffDays == 0) {
      return {
        'label': 'Hạn chót hôm nay',
        'color': AppColors.tertiary,
        'containerColor': AppColors.tertiaryContainer,
        'isOverdue': false,
      };
    } else if (diffDays == 1) {
      return {
        'label': 'Hạn chót ngày mai',
        'color': AppColors.tertiary,
        'containerColor': AppColors.tertiaryContainer,
        'isOverdue': false,
      };
    } else {
      return {
        'label': 'Còn $diffDays ngày',
        'color': AppColors.primary,
        'containerColor': AppColors.primaryContainer,
        'isOverdue': false,
      };
    }
  }

  /// Định dạng kích thước tệp (bytes -> KB, MB)
  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Tài liệu liên kết';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Hiển thị thông báo SnackBar chuẩn Material 3
  static void showCustomSnackbar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? AppColors.onErrorContainer : AppColors.onSecondaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? AppColors.errorContainer : AppColors.secondaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: duration,
        elevation: 1,
      ),
    );
  }

  /// Hiển thị hộp thoại xác nhận (Hủy / Đồng ý)
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy bỏ',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              cancelText,
              style: TextStyle(color: Theme.of(ctx).colorScheme.secondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor ?? Theme.of(ctx).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
