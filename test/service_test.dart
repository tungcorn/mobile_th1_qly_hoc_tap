import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_doc_manager/database/appDatabase.dart';
import 'package:study_doc_manager/struct/databaseGlobal.dart';
import 'package:study_doc_manager/struct/documentModels.dart';
import 'package:study_doc_manager/struct/documentService.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    // Khởi tạo global database cho service
    database = AppDatabase();
    await database.initDatabase(inMemoryPath: inMemoryDatabasePath);
  });

  tearDown(() async {
    await database.close();
  });

  group('Kiểm thử Tầng Nghiệp vụ (Struct Layer - DocumentService & Logic)', () {
    test('Xác thực dữ liệu đầu vào (Validation Logic)', () {
      // Tiêu đề rỗng
      final errEmpty = DocumentService.validateDocumentData(title: '', subjectId: 'sub_01');
      expect(errEmpty, isNotNull);
      expect(errEmpty!.contains('không được để trống'), isTrue);

      // Chưa chọn môn học
      final errNoSubject = DocumentService.validateDocumentData(title: 'Bài tập 1', subjectId: null);
      expect(errNoSubject, isNotNull);
      expect(errNoSubject!.contains('chọn môn học'), isTrue);

      // Dữ liệu hợp lệ
      final errValid = DocumentService.validateDocumentData(title: 'Bài giảng Tuần 1', subjectId: 'sub_01');
      expect(errValid, isNull);
    });

    test('Tính toán số liệu thống kê học tập (DocumentStats)', () {
      final now = DateTime.now();
      final sampleDocs = [
        DocumentWithSubject(
          document: DocumentItem(
            id: '1',
            title: 'Bài giảng 1',
            subjectId: 'sub_1',
            type: DocumentType.lecture,
            isFavorite: true,
            dateCreated: now,
            dateModified: now,
          ),
        ),
        DocumentWithSubject(
          document: DocumentItem(
            id: '2',
            title: 'Bài tập 1',
            subjectId: 'sub_1',
            type: DocumentType.assignment,
            isCompleted: false,
            deadline: now.subtract(const Duration(days: 2)), // Quá hạn
            dateCreated: now,
            dateModified: now,
          ),
        ),
        DocumentWithSubject(
          document: DocumentItem(
            id: '3',
            title: 'Bài tập 2',
            subjectId: 'sub_1',
            type: DocumentType.assignment,
            isCompleted: true, // Đã làm
            deadline: now.add(const Duration(days: 2)),
            dateCreated: now,
            dateModified: now,
          ),
        ),
        DocumentWithSubject(
          document: DocumentItem(
            id: '4',
            title: 'Tài liệu tham khảo',
            subjectId: 'sub_1',
            type: DocumentType.reference,
            isFavorite: true,
            dateCreated: now,
            dateModified: now,
          ),
        ),
      ];

      final stats = DocumentStats.fromDocuments(sampleDocs);
      expect(stats.totalCount, equals(4));
      expect(stats.lectureCount, equals(1));
      expect(stats.assignmentCount, equals(2));
      expect(stats.pendingAssignmentCount, equals(1)); // Chỉ có bài 1 chưa làm
      expect(stats.overdueAssignmentCount, equals(1)); // Bài 1 quá hạn
      expect(stats.referenceCount, equals(1));
      expect(stats.favoriteCount, equals(2));
    });

    test('Thêm tài liệu thông qua DocumentService và kiểm tra tính toàn vẹn', () async {
      final created = await DocumentService.createDocument(
        title: 'Báo cáo Thực hành Lập trình Android',
        subjectId: 'sub_mobile',
        type: DocumentType.assignment,
        fileUrl: 'https://gitlab.com/report',
        fileType: 'PDF',
        fileSize: 2048000,
        note: 'Báo cáo nộp đúng hạn',
        isFavorite: true,
        deadline: DateTime.now().add(const Duration(days: 5)),
      );

      expect(created.id, isNotEmpty);
      expect(created.title, equals('Báo cáo Thực hành Lập trình Android'));
      expect(created.isFavorite, isTrue);

      final fromDb = await database.getDocumentWithSubject(created.id);
      expect(fromDb, isNotNull);
      expect(fromDb!.document.title, equals('Báo cáo Thực hành Lập trình Android'));
    });

    test('Ném lỗi ArgumentError khi gọi DocumentService với dữ liệu không hợp lệ', () async {
      expect(
        () async => await DocumentService.createDocument(
          title: '   ',
          subjectId: 'sub_mobile',
          type: DocumentType.lecture,
        ),
        throwsArgumentError,
      );
    });
  });
}
