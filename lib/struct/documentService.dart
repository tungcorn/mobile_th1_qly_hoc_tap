import 'package:uuid/uuid.dart';
import 'databaseGlobal.dart';
import 'documentModels.dart';

/// Thống kê tổng quan tài liệu học tập
class DocumentStats {
  final int totalCount;
  final int lectureCount;
  final int assignmentCount;
  final int pendingAssignmentCount;
  final int overdueAssignmentCount;
  final int referenceCount;
  final int examCount;
  final int favoriteCount;

  const DocumentStats({
    required this.totalCount,
    required this.lectureCount,
    required this.assignmentCount,
    required this.pendingAssignmentCount,
    required this.overdueAssignmentCount,
    required this.referenceCount,
    required this.examCount,
    required this.favoriteCount,
  });

  factory DocumentStats.fromDocuments(List<DocumentWithSubject> list) {
    int total = list.length;
    int lectures = 0;
    int assignments = 0;
    int pending = 0;
    int overdue = 0;
    int refs = 0;
    int exams = 0;
    int favorites = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final item in list) {
      final doc = item.document;
      if (doc.isFavorite) favorites++;

      switch (doc.type) {
        case DocumentType.lecture:
          lectures++;
          break;
        case DocumentType.assignment:
          assignments++;
          if (!doc.isCompleted) {
            pending++;
            if (doc.deadline != null) {
              final deadlineDay = DateTime(doc.deadline!.year, doc.deadline!.month, doc.deadline!.day);
              if (deadlineDay.isBefore(today)) {
                overdue++;
              }
            }
          }
          break;
        case DocumentType.reference:
          refs++;
          break;
        case DocumentType.exam:
          exams++;
          break;
      }
    }

    return DocumentStats(
      totalCount: total,
      lectureCount: lectures,
      assignmentCount: assignments,
      pendingAssignmentCount: pending,
      overdueAssignmentCount: overdue,
      referenceCount: refs,
      examCount: exams,
      favoriteCount: favorites,
    );
  }
}

/// [DocumentService]: Tầng nghiệp vụ xử lý logic và quy tắc hệ thống,
/// phân tách độc lập giữa Tầng Dữ liệu (Database) và Tầng Giao diện (Pages/Widgets).
class DocumentService {
  static const _uuid = Uuid();

  /// Kiểm tra tính hợp lệ của dữ liệu trước khi lưu
  static String? validateDocumentData({
    required String title,
    required String? subjectId,
  }) {
    if (title.trim().isEmpty) {
      return 'Tiêu đề tài liệu không được để trống.';
    }
    if (title.trim().length > 250) {
      return 'Tiêu đề tài liệu không được vượt quá 250 ký tự.';
    }
    if (subjectId == null || subjectId.trim().isEmpty) {
      return 'Vui lòng chọn môn học cho tài liệu.';
    }
    return null;
  }

  /// Tạo mới tài liệu học tập
  static Future<DocumentItem> createDocument({
    required String title,
    required String subjectId,
    required DocumentType type,
    String fileUrl = '',
    String fileType = 'PDF',
    int fileSize = 0,
    String note = '',
    bool isFavorite = false,
    bool isCompleted = false,
    DateTime? deadline,
  }) async {
    final validationError = validateDocumentData(title: title, subjectId: subjectId);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final now = DateTime.now();
    final document = DocumentItem(
      id: _uuid.v4(),
      title: title.trim(),
      subjectId: subjectId,
      type: type,
      fileUrl: fileUrl.trim(),
      fileType: fileType.toUpperCase(),
      fileSize: fileSize,
      note: note.trim(),
      isFavorite: isFavorite,
      isCompleted: isCompleted,
      deadline: deadline,
      dateCreated: now,
      dateModified: now,
    );

    await database.insertDocument(document);
    return document;
  }

  /// Cập nhật thông tin tài liệu
  static Future<DocumentItem> updateDocument({
    required String id,
    required String title,
    required String subjectId,
    required DocumentType type,
    String fileUrl = '',
    String fileType = 'PDF',
    int fileSize = 0,
    String note = '',
    bool isFavorite = false,
    bool isCompleted = false,
    DateTime? deadline,
    required DateTime dateCreated,
  }) async {
    final validationError = validateDocumentData(title: title, subjectId: subjectId);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final updated = DocumentItem(
      id: id,
      title: title.trim(),
      subjectId: subjectId,
      type: type,
      fileUrl: fileUrl.trim(),
      fileType: fileType.toUpperCase(),
      fileSize: fileSize,
      note: note.trim(),
      isFavorite: isFavorite,
      isCompleted: isCompleted,
      deadline: deadline,
      dateCreated: dateCreated,
      dateModified: DateTime.now(),
    );

    await database.updateDocument(updated);
    return updated;
  }

  /// Xóa tài liệu
  static Future<void> deleteDocument(String id) async {
    await database.deleteDocument(id);
  }

  /// Đánh dấu / Bỏ đánh dấu Yêu thích
  static Future<void> toggleFavorite(String id, bool currentStatus) async {
    await database.toggleFavorite(id, !currentStatus);
  }

  /// Đánh dấu hoàn thành bài tập
  static Future<void> toggleCompleted(String id, bool currentStatus) async {
    await database.toggleCompleted(id, !currentStatus);
  }

  /// Thêm môn học mới
  static Future<SubjectItem> createSubject({
    required String name,
    required String code,
    required int colorValue,
    String iconName = 'school',
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Tên môn học không được để trống.');
    }

    final subject = SubjectItem(
      id: _uuid.v4(),
      name: name.trim(),
      code: code.trim().toUpperCase(),
      colorValue: colorValue,
      iconName: iconName,
      dateCreated: DateTime.now(),
    );

    await database.insertSubject(subject);
    return subject;
  }

  /// Cập nhật môn học
  static Future<void> updateSubject(SubjectItem subject) async {
    if (subject.name.trim().isEmpty) {
      throw ArgumentError('Tên môn học không được để trống.');
    }
    await database.updateSubject(subject);
  }

  /// Xóa môn học
  static Future<void> deleteSubject(String id) async {
    await database.deleteSubject(id);
  }
}
