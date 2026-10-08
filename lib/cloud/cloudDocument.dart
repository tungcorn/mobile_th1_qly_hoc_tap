import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as p;

class CloudFilePolicy {
  static const maxBytes = 10 * 1024 * 1024;
  static const mimeTypes = {
    'pdf': 'application/pdf',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'txt': 'text/plain',
    'zip': 'application/zip',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
  };

  static String contentTypeFor(String fileName) {
    final extension = p.extension(fileName).replaceFirst('.', '').toLowerCase();
    final mime = mimeTypes[extension];
    if (mime == null) {
      throw ArgumentError(
        'Chỉ hỗ trợ PDF, DOCX, PPTX, XLSX, TXT, ZIP, PNG, JPG.',
      );
    }
    return mime;
  }

  static void validate(CloudUpload upload) {
    if (upload.title.trim().isEmpty || upload.title.trim().length > 250) {
      throw ArgumentError('Tiêu đề cần từ 1 đến 250 ký tự.');
    }
    if (upload.subject.trim().isEmpty || upload.subject.trim().length > 120) {
      throw ArgumentError('Tên môn học cần từ 1 đến 120 ký tự.');
    }
    if (upload.note.length > 4000) {
      throw ArgumentError('Ghi chú không được vượt quá 4000 ký tự.');
    }
    if (upload.fileName.isEmpty ||
        upload.fileName.length > 255 ||
        p.basename(upload.fileName) != upload.fileName ||
        upload.fileName.contains('\\')) {
      throw ArgumentError('Tên tệp không hợp lệ.');
    }
    if (upload.bytes.isEmpty || upload.bytes.length > maxBytes) {
      throw ArgumentError('Tệp phải có dữ liệu và không vượt quá 10 MiB.');
    }
    contentTypeFor(upload.fileName);
  }
}

class CloudUpload {
  final String title;
  final String subject;
  final String note;
  final String fileName;
  final Uint8List bytes;

  const CloudUpload({
    required this.title,
    required this.subject,
    this.note = '',
    required this.fileName,
    required this.bytes,
  });
}

class CloudDocument {
  final String id;
  final String ownerId;
  final String title;
  final String subject;
  final String note;
  final String fileName;
  final String contentType;
  final int size;
  final String storagePath;
  final DateTime? createdAt;

  const CloudDocument({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.subject,
    required this.note,
    required this.fileName,
    required this.contentType,
    required this.size,
    required this.storagePath,
    required this.createdAt,
  });

  factory CloudDocument.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return CloudDocument(
      id: snapshot.id,
      ownerId: data['ownerId'] as String,
      title: data['title'] as String,
      subject: data['subject'] as String,
      note: data['note'] as String,
      fileName: data['fileName'] as String,
      contentType: data['contentType'] as String,
      size: data['size'] as int,
      storagePath: data['storagePath'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
