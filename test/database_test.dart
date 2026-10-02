import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_doc_manager/database/appDatabase.dart';
import 'package:study_doc_manager/struct/documentModels.dart';

void main() {
  // Khởi tạo FFI cho môi trường test trên Desktop / Dart VM
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase appDb;

  setUp(() async {
    appDb = AppDatabase();
    // Sử dụng in-memory database để các test độc lập và tốc độ cực nhanh
    await appDb.initDatabase(inMemoryPath: inMemoryDatabasePath);
  });

  tearDown(() async {
    await appDb.close();
  });

  group('Kiểm thử Tầng Database (Database Layer - CRUD & Queries)', () {
    test('Khởi tạo database và nạp dữ liệu mẫu ban đầu (Seed Data)', () async {
      final subjects = await appDb.getAllSubjects();
      expect(subjects.length, greaterThanOrEqualTo(4));

      final docs = await appDb.getFilteredDocuments();
      expect(docs.length, greaterThanOrEqualTo(5));
    });

    test('Thêm tài liệu mới vào cơ sở dữ liệu thành công', () async {
      final newDoc = DocumentItem(
        id: 'test_doc_01',
        title: 'Tài liệu Ôn tập Kiểm thử Tự động',
        subjectId: 'sub_mobile',
        type: DocumentType.lecture,
        fileUrl: 'https://test.com/file.pdf',
        fileType: 'PDF',
        fileSize: 1024000,
        note: 'Ghi chú kiểm thử',
        isFavorite: true,
        isCompleted: false,
        deadline: null,
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
      );

      final rowId = await appDb.insertDocument(newDoc);
      expect(rowId, isPositive);

      final fetched = await appDb.getDocumentWithSubject('test_doc_01');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Tài liệu Ôn tập Kiểm thử Tự động'));
      expect(fetched.subjectName, equals('Lập trình Thiết bị Di động'));
      expect(fetched.isFavorite, isTrue);
    });

    test('Cập nhật tài liệu và kiểm tra tính toàn vẹn', () async {
      final doc = DocumentItem(
        id: 'test_doc_update',
        title: 'Tiêu đề cũ',
        subjectId: 'sub_mobile',
        type: DocumentType.assignment,
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
      );
      await appDb.insertDocument(doc);

      final updatedDoc = doc.copyWith(
        title: 'Tiêu đề đã được cập nhật',
        isCompleted: true,
        note: 'Đã hoàn thành xuất sắc',
      );
      await appDb.updateDocument(updatedDoc);

      final fetched = await appDb.getDocumentWithSubject('test_doc_update');
      expect(fetched!.title, equals('Tiêu đề đã được cập nhật'));
      expect(fetched.isCompleted, isTrue);
      expect(fetched.note, equals('Đã hoàn thành xuất sắc'));
    });

    test('Chuyển đổi trạng thái Yêu thích và Hoàn thành', () async {
      final doc = DocumentItem(
        id: 'test_doc_toggle',
        title: 'Tài liệu toggle',
        subjectId: 'sub_dsa',
        type: DocumentType.assignment,
        isFavorite: false,
        isCompleted: false,
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
      );
      await appDb.insertDocument(doc);

      // Đánh dấu yêu thích
      await appDb.toggleFavorite('test_doc_toggle', true);
      var fetched = await appDb.getDocumentWithSubject('test_doc_toggle');
      expect(fetched!.isFavorite, isTrue);

      // Đánh dấu hoàn thành
      await appDb.toggleCompleted('test_doc_toggle', true);
      fetched = await appDb.getDocumentWithSubject('test_doc_toggle');
      expect(fetched!.isCompleted, isTrue);
    });

    test('Xóa tài liệu và xác nhận bản ghi không còn tồn tại', () async {
      final doc = DocumentItem(
        id: 'test_doc_delete',
        title: 'Tài liệu chuẩn bị xóa',
        subjectId: 'sub_network',
        type: DocumentType.reference,
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
      );
      await appDb.insertDocument(doc);

      final deleteCount = await appDb.deleteDocument('test_doc_delete');
      expect(deleteCount, equals(1));

      final fetched = await appDb.getDocumentWithSubject('test_doc_delete');
      expect(fetched, isNull);
    });

    test('Tìm kiếm tài liệu theo từ khóa và lọc theo phân loại', () async {
      final searchResult = await appDb.getFilteredDocuments(
        searchQuery: 'Kiến trúc',
      );
      expect(searchResult.isNotEmpty, isTrue);
      expect(searchResult.first.title.contains('Kiến trúc'), isTrue);

      final assignmentFilter = await appDb.getFilteredDocuments(
        type: DocumentType.assignment,
      );
      for (final item in assignmentFilter) {
        expect(item.type, equals(DocumentType.assignment));
      }
    });

    test('Quản lý Môn học (Thêm, Sửa, Xóa cascading)', () async {
      final newSubject = SubjectItem(
        id: 'sub_test_ai',
        name: 'Trí tuệ Nhân tạo',
        code: 'IT4010',
        colorValue: 0xFF2563EB,
        iconName: 'school',
        dateCreated: DateTime.now(),
      );
      await appDb.insertSubject(newSubject);

      var sub = await appDb.getSubjectById('sub_test_ai');
      expect(sub, isNotNull);
      expect(sub!.name, equals('Trí tuệ Nhân tạo'));

      // Thêm tài liệu thuộc môn học này
      await appDb.insertDocument(
        DocumentItem(
          id: 'doc_ai_01',
          title: 'Slide AI Bài 1',
          subjectId: 'sub_test_ai',
          type: DocumentType.lecture,
          dateCreated: DateTime.now(),
          dateModified: DateTime.now(),
        ),
      );

      // Xóa môn học -> Tài liệu thuộc môn học cũng bị xóa
      await appDb.deleteSubject('sub_test_ai');
      sub = await appDb.getSubjectById('sub_test_ai');
      expect(sub, isNull);

      final docAfterSubjectDelete = await appDb.getDocumentWithSubject('doc_ai_01');
      expect(docAfterSubjectDelete, isNull);
    });
  });
}
