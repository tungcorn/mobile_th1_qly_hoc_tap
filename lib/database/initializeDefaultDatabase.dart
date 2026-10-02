import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../struct/documentModels.dart';
import 'tables.dart';

/// [initializeDefaultDatabase]: Khởi tạo dữ liệu mẫu ban đầu cho ứng dụng,
/// tương tự như `database/initializeDefaultDatabase.dart` trong Cashew.
Future<void> initializeDefaultDatabase(Database db) async {
  const uuid = Uuid();
  final now = DateTime.now();

  // Danh mục môn học mặc định
  final defaultSubjects = [
    SubjectItem(
      id: 'sub_mobile',
      name: 'Lập trình Thiết bị Di động',
      code: 'IT4040',
      colorValue: 0xFF2563EB, // Xanh dương
      iconName: 'phone_android',
      dateCreated: now.subtract(const Duration(days: 30)),
    ),
    SubjectItem(
      id: 'sub_dsa',
      name: 'Cấu trúc Dữ liệu & Giải thuật',
      code: 'IT3011',
      colorValue: 0xFF0D9488, // Xanh ngọc
      iconName: 'hub',
      dateCreated: now.subtract(const Duration(days: 28)),
    ),
    SubjectItem(
      id: 'sub_network',
      name: 'Mạng Máy tính',
      code: 'IT3080',
      colorValue: 0xFFD97706, // Cam hổ phách
      iconName: 'lan',
      dateCreated: now.subtract(const Duration(days: 25)),
    ),
    SubjectItem(
      id: 'sub_db',
      name: 'Hệ Quản trị Cơ sở Dữ liệu',
      code: 'IT3090',
      colorValue: 0xFF7C3AED, // Tím
      iconName: 'storage',
      dateCreated: now.subtract(const Duration(days: 20)),
    ),
  ];

  final batch = db.batch();

  for (final sub in defaultSubjects) {
    batch.insert(
      AppTables.tableSubjects,
      sub.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Danh mục tài liệu mẫu ban đầu
  final sampleDocs = [
    DocumentItem(
      id: uuid.v4(),
      title: 'Slide Bài giảng Chương 1: Kiến trúc Ứng dụng Di động & Mẫu Cashew',
      subjectId: 'sub_mobile',
      type: DocumentType.lecture,
      fileUrl: 'https://github.com/jameskokoska/Cashew',
      fileType: 'PDF',
      fileSize: 3500000, // ~3.5 MB
      note: 'Nội dung cốt lõi về phân tách các lớp (Database, Struct, Pages, Widgets) theo chuẩn Cashew.',
      isFavorite: true,
      isCompleted: false,
      deadline: null,
      dateCreated: now.subtract(const Duration(days: 5)),
      dateModified: now.subtract(const Duration(days: 5)),
    ),
    DocumentItem(
      id: uuid.v4(),
      title: 'TH1: Xây dựng Ứng dụng Quản lý Tài liệu Học tập theo Kiến trúc Cashew',
      subjectId: 'sub_mobile',
      type: DocumentType.assignment,
      fileUrl: 'https://classroom.google.com',
      fileType: 'DOCX',
      fileSize: 1200000,
      note: 'Yêu cầu: Phân tách 4 lớp, hoàn thành 4 chức năng CRUD, kiểm thử tự động và viết báo cáo giải trình.',
      isFavorite: true,
      isCompleted: false,
      deadline: now.add(const Duration(days: 4)),
      dateCreated: now.subtract(const Duration(days: 2)),
      dateModified: now.subtract(const Duration(days: 2)),
    ),
    DocumentItem(
      id: uuid.v4(),
      title: 'Giáo trình Giải thuật Nâng cao & Cấu trúc Dữ liệu Cây (AVL, Red-Black)',
      subjectId: 'sub_dsa',
      type: DocumentType.reference,
      fileUrl: 'https://example.com/books/dsa-advanced.pdf',
      fileType: 'PDF',
      fileSize: 8400000,
      note: 'Tài liệu tham khảo chính phục vụ làm bài tập lớn và ôn thi cuối kỳ.',
      isFavorite: false,
      isCompleted: false,
      deadline: null,
      dateCreated: now.subtract(const Duration(days: 10)),
      dateModified: now.subtract(const Duration(days: 10)),
    ),
    DocumentItem(
      id: uuid.v4(),
      title: 'Bài tập Tuần 3: Phân tích Gói tin TCP/IP với Wireshark',
      subjectId: 'sub_network',
      type: DocumentType.assignment,
      fileUrl: '',
      fileType: 'ZIP',
      fileSize: 450000,
      note: 'Bắt gói tin bắt tay 3 bước TCP và nộp file pcap trước buổi học tuần sau.',
      isFavorite: false,
      isCompleted: true,
      deadline: now.subtract(const Duration(days: 1)),
      dateCreated: now.subtract(const Duration(days: 8)),
      dateModified: now.subtract(const Duration(days: 1)),
    ),
    DocumentItem(
      id: uuid.v4(),
      title: 'Tổng hợp Bộ Đề thi Cuối kỳ Cơ sở Dữ liệu (2023 - 2025)',
      subjectId: 'sub_db',
      type: DocumentType.exam,
      fileUrl: 'https://drive.google.com/sample_exam',
      fileType: 'PDF',
      fileSize: 2100000,
      note: 'Đề có đáp án chi tiết phần Chuẩn hóa CSDL (3NF, BCNF) và tối ưu hóa câu lệnh SQL.',
      isFavorite: true,
      isCompleted: false,
      deadline: null,
      dateCreated: now.subtract(const Duration(days: 12)),
      dateModified: now.subtract(const Duration(days: 3)),
    ),
  ];

  for (final doc in sampleDocs) {
    batch.insert(
      AppTables.tableDocuments,
      doc.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  await batch.commit(noResult: true);
}
