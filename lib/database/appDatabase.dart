import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../struct/documentModels.dart';
import 'initializeDefaultDatabase.dart';
import 'tables.dart';

/// [AppDatabase]: Tầng thao tác cơ sở dữ liệu SQLite trong ứng dụng.
/// Thực hiện lưu trữ, truy vấn, và cung cấp các luồng dữ liệu Reactive Stream
/// tương tự như `FinanceDatabase` trong kiến trúc Cashew.
class AppDatabase {
  Database? _db;
  final StreamController<void> _changeNotifier = StreamController<void>.broadcast();

  AppDatabase([Database? existingDb]) {
    if (existingDb != null) {
      _db = existingDb;
    }
  }

  /// Trả về instance Database hiện tại
  Database get db {
    if (_db == null) {
      throw StateError('Database chưa được khởi tạo. Hãy gọi initDatabase() trước.');
    }
    return _db!;
  }

  /// Khởi tạo kết nối SQLite đa nền tảng (Android, Windows, Unit Tests)
  Future<void> initDatabase({String? inMemoryPath}) async {
    if (_db != null && _db!.isOpen) return;

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (inMemoryPath != null) {
      path = inMemoryPath;
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      path = p.join(docDir.path, 'study_doc_database.db');
    }

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(AppTables.createSubjectsTable);
        await db.execute(AppTables.createDocumentsTable);
        await db.execute(AppTables.createDocSearchIndex);
        await initializeDefaultDatabase(db);
      },
    );
  }

  /// Phát tín hiệu thông báo cho các luồng StreamBuilder cập nhật UI tức thì
  void _notifyChange() {
    if (!_changeNotifier.isClosed) {
      _changeNotifier.add(null);
    }
  }

  // ==========================================
  // THAO TÁC VỚI BẢNG MÔN HỌC (SUBJECTS)
  // ==========================================

  /// Lấy toàn bộ danh sách Môn học
  Future<List<SubjectItem>> getAllSubjects() async {
    final results = await db.query(
      AppTables.tableSubjects,
      orderBy: 'dateCreated ASC',
    );
    return results.map((map) => SubjectItem.fromMap(map)).toList();
  }

  /// Luồng Reactive theo dõi thay đổi danh sách Môn học
  Stream<List<SubjectItem>> watchAllSubjects() async* {
    yield await getAllSubjects();
    await for (final _ in _changeNotifier.stream) {
      yield await getAllSubjects();
    }
  }

  /// Lấy chi tiết Môn học theo ID
  Future<SubjectItem?> getSubjectById(String id) async {
    final results = await db.query(
      AppTables.tableSubjects,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SubjectItem.fromMap(results.first);
  }

  /// Thêm Môn học mới
  Future<int> insertSubject(SubjectItem subject) async {
    final rowId = await db.insert(
      AppTables.tableSubjects,
      subject.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyChange();
    return rowId;
  }

  /// Cập nhật Môn học
  Future<int> updateSubject(SubjectItem subject) async {
    final count = await db.update(
      AppTables.tableSubjects,
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
    _notifyChange();
    return count;
  }

  /// Xóa Môn học (và xóa luôn tài liệu thuộc môn đó nhờ ON DELETE CASCADE)
  Future<int> deleteSubject(String id) async {
    // Xóa thủ công tài liệu nếu foreign key cascade chưa kích hoạt
    await db.delete(
      AppTables.tableDocuments,
      where: 'subjectId = ?',
      whereArgs: [id],
    );
    final count = await db.delete(
      AppTables.tableSubjects,
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyChange();
    return count;
  }

  // ==========================================
  // THAO TÁC VỚI BẢNG TÀI LIỆU (DOCUMENTS)
  // ==========================================

  /// Thêm mới một tài liệu học tập
  Future<int> insertDocument(DocumentItem document) async {
    final rowId = await db.insert(
      AppTables.tableDocuments,
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyChange();
    return rowId;
  }

  /// Cập nhật thông tin tài liệu học tập
  Future<int> updateDocument(DocumentItem document) async {
    final count = await db.update(
      AppTables.tableDocuments,
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
    _notifyChange();
    return count;
  }

  /// Xóa một tài liệu học tập
  Future<int> deleteDocument(String id) async {
    final count = await db.delete(
      AppTables.tableDocuments,
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyChange();
    return count;
  }

  /// Chuyển đổi trạng thái Yêu thích / Quan trọng
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await db.update(
      AppTables.tableDocuments,
      {
        'isFavorite': isFavorite ? 1 : 0,
        'dateModified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyChange();
  }

  /// Chuyển đổi trạng thái Hoàn thành bài tập
  Future<void> toggleCompleted(String id, bool isCompleted) async {
    await db.update(
      AppTables.tableDocuments,
      {
        'isCompleted': isCompleted ? 1 : 0,
        'dateModified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyChange();
  }

  /// Lấy chi tiết tài liệu kèm thông tin Môn học
  Future<DocumentWithSubject?> getDocumentWithSubject(String id) async {
    const query = '''
      SELECT 
        d.*,
        s.name AS s_name,
        s.code AS s_code,
        s.colorValue AS s_colorValue,
        s.iconName AS s_iconName,
        s.dateCreated AS s_dateCreated
      FROM ${AppTables.tableDocuments} d
      LEFT JOIN ${AppTables.tableSubjects} s ON d.subjectId = s.id
      WHERE d.id = ?
      LIMIT 1
    ''';

    final results = await db.rawQuery(query, [id]);
    if (results.isEmpty) return null;

    final row = results.first;
    final doc = DocumentItem.fromMap(row);
    SubjectItem? subject;
    if (row['s_name'] != null) {
      subject = SubjectItem(
        id: doc.subjectId,
        name: row['s_name'] as String,
        code: row['s_code'] as String? ?? '',
        colorValue: row['s_colorValue'] as int? ?? 0xFF1E3A8A,
        iconName: row['s_iconName'] as String? ?? 'school',
        dateCreated: DateTime.tryParse(row['s_dateCreated'] as String? ?? '') ?? DateTime.now(),
      );
    }
    return DocumentWithSubject(document: doc, subject: subject);
  }

  /// Lấy danh sách tài liệu với bộ lọc đa tiêu chí
  Future<List<DocumentWithSubject>> getFilteredDocuments({
    String? subjectId,
    DocumentType? type,
    String? searchQuery,
    bool? onlyFavorites,
    bool? onlyCompleted,
    bool? onlyPending,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (subjectId != null && subjectId.isNotEmpty && subjectId != 'all') {
      whereClauses.add('d.subjectId = ?');
      whereArgs.add(subjectId);
    }

    if (type != null) {
      whereClauses.add('d.type = ?');
      whereArgs.add(type.name);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(d.title LIKE ? OR d.note LIKE ?)');
      final term = '%${searchQuery.trim()}%';
      whereArgs.add(term);
      whereArgs.add(term);
    }

    if (onlyFavorites == true) {
      whereClauses.add('d.isFavorite = 1');
    }

    if (onlyCompleted == true) {
      whereClauses.add('d.isCompleted = 1');
    } else if (onlyPending == true) {
      whereClauses.add('d.isCompleted = 0');
    }

    final whereString = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final query = '''
      SELECT 
        d.*,
        s.name AS s_name,
        s.code AS s_code,
        s.colorValue AS s_colorValue,
        s.iconName AS s_iconName,
        s.dateCreated AS s_dateCreated
      FROM ${AppTables.tableDocuments} d
      LEFT JOIN ${AppTables.tableSubjects} s ON d.subjectId = s.id
      $whereString
      ORDER BY d.isFavorite DESC, d.dateModified DESC
    ''';

    final results = await db.rawQuery(query, whereArgs);

    return results.map((row) {
      final doc = DocumentItem.fromMap(row);
      SubjectItem? subject;
      if (row['s_name'] != null) {
        subject = SubjectItem(
          id: doc.subjectId,
          name: row['s_name'] as String,
          code: row['s_code'] as String? ?? '',
          colorValue: row['s_colorValue'] as int? ?? 0xFF1E3A8A,
          iconName: row['s_iconName'] as String? ?? 'school',
          dateCreated: DateTime.tryParse(row['s_dateCreated'] as String? ?? '') ?? DateTime.now(),
        );
      }
      return DocumentWithSubject(document: doc, subject: subject);
    }).toList();
  }

  /// Luồng Reactive theo dõi danh sách tài liệu phản ứng tự động theo bộ lọc
  Stream<List<DocumentWithSubject>> watchFilteredDocuments({
    String? subjectId,
    DocumentType? type,
    String? searchQuery,
    bool? onlyFavorites,
    bool? onlyCompleted,
    bool? onlyPending,
  }) async* {
    yield await getFilteredDocuments(
      subjectId: subjectId,
      type: type,
      searchQuery: searchQuery,
      onlyFavorites: onlyFavorites,
      onlyCompleted: onlyCompleted,
      onlyPending: onlyPending,
    );
    await for (final _ in _changeNotifier.stream) {
      yield await getFilteredDocuments(
        subjectId: subjectId,
        type: type,
        searchQuery: searchQuery,
        onlyFavorites: onlyFavorites,
        onlyCompleted: onlyCompleted,
        onlyPending: onlyPending,
      );
    }
  }

  /// Đóng kết nối cơ sở dữ liệu
  Future<void> close() async {
    await _changeNotifier.close();
    await _db?.close();
    _db = null;
  }
}
