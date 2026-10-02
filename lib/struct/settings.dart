import 'package:flutter/material.dart';

/// [AppSettings]: Quản lý cấu hình toàn cục của người dùng (Theme, Chế độ xem)
/// theo mô hình `struct/settings.dart` trong kiến trúc Cashew.
class AppSettings {
  AppSettings._();

  // Quản lý chế độ sáng/tối (System / Light / Dark)
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  // Quản lý chế độ hiển thị danh sách (Card chi tiết hoặc Dòng thu gọn)
  static final ValueNotifier<bool> isCompactViewNotifier = ValueNotifier<bool>(false);

  /// Đổi theme nhanh giữa sáng và tối
  static void toggleTheme() {
    if (themeModeNotifier.value == ThemeMode.light) {
      themeModeNotifier.value = ThemeMode.dark;
    } else {
      themeModeNotifier.value = ThemeMode.light;
    }
  }

  /// Đổi chế độ hiển thị (Card chi tiết / Compact)
  static void toggleViewMode() {
    isCompactViewNotifier.value = !isCompactViewNotifier.value;
  }
}
