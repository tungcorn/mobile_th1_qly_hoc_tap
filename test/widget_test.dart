import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_doc_manager/database/appDatabase.dart';
import 'package:study_doc_manager/main.dart';
import 'package:study_doc_manager/struct/databaseGlobal.dart';
import 'package:study_doc_manager/struct/settings.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    database = AppDatabase();
    await database.initDatabase(inMemoryPath: inMemoryDatabasePath);
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('Kiểm thử Giao diện chính (HomePage) và tương tác người dùng', (WidgetTester tester) async {
    // 1. Dựng ứng dụng StudyDocApp
    await tester.pumpWidget(const StudyDocApp());
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    // 2. Kiểm tra Tiêu đề AppBar và Thông tin kiến trúc
    expect(find.text('Quản lý Tài liệu Học tập'), findsOneWidget);
    expect(find.text('Kiến trúc Cashew • Material Design 3'), findsOneWidget);

    // 3. Kiểm tra các thành phần giao diện cốt lõi
    // - Nút thêm tài liệu (FAB)
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Thêm tài liệu'), findsOneWidget);

    // - Ô tìm kiếm
    expect(find.byType(TextField), findsOneWidget);

    // - Thẻ thống kê
    expect(find.text('Tài liệu'), findsOneWidget);
    expect(find.text('Bài tập chờ'), findsOneWidget);
    expect(find.text('Quan trọng'), findsOneWidget);

    // 4. Kiểm tra tương tác: Chuyển đổi Theme Sáng / Tối
    expect(AppSettings.themeModeNotifier.value, equals(ThemeMode.light));
    AppSettings.toggleTheme();
    expect(AppSettings.themeModeNotifier.value, equals(ThemeMode.dark));
    AppSettings.toggleTheme();
    expect(AppSettings.themeModeNotifier.value, equals(ThemeMode.light));

    // 5. Kiểm tra tương tác: Nhấn nút FAB để mở màn hình Thêm tài liệu
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.text('Thêm Tài liệu Mới'), findsOneWidget);
    expect(find.text('Tiêu đề tài liệu *'), findsOneWidget);
    expect(find.text('Tạo mới'), findsOneWidget);
  });
}
