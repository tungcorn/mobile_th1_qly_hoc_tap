/// [Tables]: Định nghĩa cấu trúc các bảng dữ liệu trong SQLite cho ứng dụng,
/// tương tự như `database/tables.dart` trong kiến trúc Cashew.
class AppTables {
  AppTables._();

  // Tên các bảng
  static const String tableSubjects = 'subjects';
  static const String tableDocuments = 'documents';

  // Câu lệnh tạo bảng Môn học (Subjects)
  static const String createSubjectsTable = '''
    CREATE TABLE IF NOT EXISTS $tableSubjects (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL,
      code TEXT NOT NULL,
      colorValue INTEGER NOT NULL,
      iconName TEXT NOT NULL,
      dateCreated TEXT NOT NULL
    );
  ''';

  // Câu lệnh tạo bảng Tài liệu học tập (Documents)
  static const String createDocumentsTable = '''
    CREATE TABLE IF NOT EXISTS $tableDocuments (
      id TEXT PRIMARY KEY NOT NULL,
      title TEXT NOT NULL,
      subjectId TEXT NOT NULL,
      type TEXT NOT NULL,
      fileUrl TEXT NOT NULL DEFAULT '',
      fileType TEXT NOT NULL DEFAULT 'PDF',
      fileSize INTEGER NOT NULL DEFAULT 0,
      note TEXT NOT NULL DEFAULT '',
      isFavorite INTEGER NOT NULL DEFAULT 0,
      isCompleted INTEGER NOT NULL DEFAULT 0,
      deadline TEXT,
      dateCreated TEXT NOT NULL,
      dateModified TEXT NOT NULL,
      FOREIGN KEY (subjectId) REFERENCES $tableSubjects (id) ON DELETE CASCADE
    );
  ''';

  // Chỉ mục tăng tốc tìm kiếm
  static const String createDocSearchIndex = '''
    CREATE INDEX IF NOT EXISTS idx_doc_search 
    ON $tableDocuments (title, subjectId, type, isFavorite, isCompleted);
  ''';
}
