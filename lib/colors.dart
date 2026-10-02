import 'package:flutter/material.dart';

/// [AppColors] định nghĩa toàn bộ bảng màu của ứng dụng theo chuẩn Material Design 3.
/// Thiết kế tuân theo phong cách tối giản, trang nhã, màu sắc học thuật (Slate Indigo & Warm Slate),
/// tránh phối màu sặc sỡ gây mỏi mắt cho người dùng.
class AppColors {
  AppColors._();

  // Primary Brand Colors (Slate Indigo học thuật)
  static const Color primary = Color(0xFF1E3A8A); // Indigo đậm nhã nhặn
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFDBEAFE); // Xanh nhạt bề mặt
  static const Color onPrimaryContainer = Color(0xFF1E3A8A);

  // Secondary Colors (Steel Slate)
  static const Color secondary = Color(0xFF475569);
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = Color(0xFFF1F5F9);
  static const Color onSecondaryContainer = Color(0xFF1E293B);

  // Tertiary Colors (Muted Amber - Dùng cho Highlight / Yêu thích / Deadline)
  static const Color tertiary = Color(0xFFD97706);
  static const Color onTertiary = Colors.white;
  static const Color tertiaryContainer = Color(0xFFFEF3C7);
  static const Color onTertiaryContainer = Color(0xFF78350F);

  // Backgrounds & Surface (Material 3 Tonal Surfaces)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color outlineLight = Color(0xFFE2E8F0);
  static const Color outlineVariantLight = Color(0xFFCBD5E1);

  // Dark Theme Surfaces
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color outlineDark = Color(0xFF475569);
  static const Color outlineVariantDark = Color(0xFF334155);

  // Semantic Document Type Colors (Tonal Badges - Nhẹ nhàng, dễ phân biệt)
  // 1. Bài giảng (Lecture) - Xanh dương tri thức
  static const Color lectureColor = Color(0xFF2563EB);
  static const Color lectureContainer = Color(0xFFEFF6FF);
  static const Color onLectureContainer = Color(0xFF1D4ED8);

  // 2. Bài tập (Assignment) - Cam hổ phách hành động
  static const Color assignmentColor = Color(0xFFD97706);
  static const Color assignmentContainer = Color(0xFFFFFBEB);
  static const Color onAssignmentContainer = Color(0xFFB45309);

  // 3. Tài liệu tham khảo (Reference) - Xanh ngọc khám phá
  static const Color referenceColor = Color(0xFF0D9488);
  static const Color referenceContainer = Color(0xFFF0FDFA);
  static const Color onReferenceContainer = Color(0xFF0F766E);

  // 4. Đề thi / Ôn tập (Exam) - Tím nhã nhặn
  static const Color examColor = Color(0xFF7C3AED);
  static const Color examContainer = Color(0xFFFAF5FF);
  static const Color onExamContainer = Color(0xFF6D28D9);

  // Error / Warning Colors
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF991B1B);

  // Success Colors
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color onSuccessContainer = Color(0xFF15803D);

  /// Theme Sáng (Light Theme Data)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: Colors.white,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surfaceLight,
        onSurface: Color(0xFF0F172A),
        surfaceContainerHighest: surfaceVariantLight,
        outline: outlineLight,
        outlineVariant: outlineVariantLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outlineLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariantLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineLight,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Theme Tối (Dark Theme Data)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF60A5FA),
        onPrimary: Color(0xFF0F172A),
        primaryContainer: Color(0xFF1E3A8A),
        onPrimaryContainer: Color(0xFFBFDBFE),
        secondary: Color(0xFF94A3B8),
        onSecondary: Color(0xFF0F172A),
        secondaryContainer: Color(0xFF334155),
        onSecondaryContainer: Color(0xFFF1F5F9),
        tertiary: Color(0xFFFBBF24),
        onTertiary: Color(0xFF0F172A),
        tertiaryContainer: Color(0xFF78350F),
        onTertiaryContainer: Color(0xFFFEF3C7),
        error: Color(0xFFF87171),
        onError: Color(0xFF0F172A),
        errorContainer: Color(0xFF7F1D1D),
        onErrorContainer: Color(0xFFFEE2E2),
        surface: surfaceDark,
        onSurface: Color(0xFFF8FAFC),
        surfaceContainerHighest: surfaceVariantDark,
        outline: outlineDark,
        outlineVariant: outlineVariantDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outlineDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariantDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1),
        ),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF60A5FA),
        foregroundColor: Color(0xFF0F172A),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineDark,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
