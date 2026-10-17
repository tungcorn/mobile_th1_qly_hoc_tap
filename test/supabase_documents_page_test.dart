import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_doc_manager/cloud/firebaseBootstrap.dart';
import 'package:study_doc_manager/cloud/supabaseBootstrap.dart';
import 'package:study_doc_manager/pages/supabaseDocumentsPage.dart';

/// Hồi quy: khi Firebase chưa cấu hình (không có firebase_config.json),
/// mở trang Thư viện Cloud không được gọi FirebaseAuth.instance (gây
/// "Null check operator used on a null value" trên bản web release) mà phải
/// rơi về tài khoản demo Sinh viên A.
void main() {
  setUp(() {
    FirebaseBootstrap.isReady = false;
    // Supabase "sẵn sàng" để trang tạo client; mọi request HTTP trong
    // flutter_test đều trả lỗi -> trang phải tự hạ cấp, không crash.
    SupabaseBootstrap.isReady = true;
  });

  tearDown(() {
    SupabaseBootstrap.isReady = false;
  });

  for (final size in const [Size(1300, 800), Size(400, 800)]) {
    testWidgets('mở trang khi Firebase chưa sẵn sàng (${size.width.toInt()}px)',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // runAsync: SupabaseClient (GoTrue) tạo Timer định kỳ thật; để ngoài
      // FakeAsync sẽ bị báo "Timer still pending" dù trang không lỗi.
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(home: SupabaseDocumentsPage()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('sinhvien_a@studydoc.edu.vn'), findsWidgets);
      expect(find.byIcon(Icons.login_rounded), findsOneWidget);
    });
  }
}
