import '../database/appDatabase.dart';

/// [database]: Thể hiện Singleton duy nhất của AppDatabase trên toàn ứng dụng.
/// Được thiết kế và sử dụng chính xác theo nguyên mẫu `databaseGlobal.dart` trong Cashew:
///
/// ```dart
/// import 'package:study_doc_manager/struct/databaseGlobal.dart';
///
/// // Sử dụng trực tiếp tại các service hoặc màn hình
/// await database.insertDocument(doc);
/// ```
late AppDatabase database;

/// Khởi tạo Singleton Database toàn cục
Future<void> initGlobalDatabase({String? inMemoryPath}) async {
  database = AppDatabase();
  await database.initDatabase(inMemoryPath: inMemoryPath);
}
