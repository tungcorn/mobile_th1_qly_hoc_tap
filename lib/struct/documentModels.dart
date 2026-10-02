import 'package:flutter/material.dart';
import '../colors.dart';

/// Các loại tài liệu học tập được quản lý trong hệ thống
enum DocumentType {
  lecture, // Bài giảng
  assignment, // Bài tập
  reference, // Tài liệu tham khảo
  exam; // Đề thi / Ôn tập

  String get displayName {
    switch (this) {
      case DocumentType.lecture:
        return 'Bài giảng';
      case DocumentType.assignment:
        return 'Bài tập';
      case DocumentType.reference:
        return 'Tham khảo';
      case DocumentType.exam:
        return 'Đề thi';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentType.lecture:
        return Icons.menu_book_rounded;
      case DocumentType.assignment:
        return Icons.assignment_outlined;
      case DocumentType.reference:
        return Icons.bookmark_border_rounded;
      case DocumentType.exam:
        return Icons.quiz_outlined;
    }
  }

  Color get color {
    switch (this) {
      case DocumentType.lecture:
        return AppColors.lectureColor;
      case DocumentType.assignment:
        return AppColors.assignmentColor;
      case DocumentType.reference:
        return AppColors.referenceColor;
      case DocumentType.exam:
        return AppColors.examColor;
    }
  }

  Color get containerColor {
    switch (this) {
      case DocumentType.lecture:
        return AppColors.lectureContainer;
      case DocumentType.assignment:
        return AppColors.assignmentContainer;
      case DocumentType.reference:
        return AppColors.referenceContainer;
      case DocumentType.exam:
        return AppColors.examContainer;
    }
  }

  Color get onContainerColor {
    switch (this) {
      case DocumentType.lecture:
        return AppColors.onLectureContainer;
      case DocumentType.assignment:
        return AppColors.onAssignmentContainer;
      case DocumentType.reference:
        return AppColors.onReferenceContainer;
      case DocumentType.exam:
        return AppColors.onExamContainer;
    }
  }

  static DocumentType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'assignment':
        return DocumentType.assignment;
      case 'reference':
        return DocumentType.reference;
      case 'exam':
        return DocumentType.exam;
      case 'lecture':
      default:
        return DocumentType.lecture;
    }
  }
}

/// [SubjectItem]: Mô hình thực thể Môn học
class SubjectItem {
  final String id;
  final String name;
  final String code;
  final int colorValue;
  final String iconName;
  final DateTime dateCreated;

  const SubjectItem({
    required this.id,
    required this.name,
    required this.code,
    required this.colorValue,
    required this.iconName,
    required this.dateCreated,
  });

  Color get color => Color(colorValue);

  IconData get icon {
    switch (iconName) {
      case 'phone_android':
        return Icons.phone_android_rounded;
      case 'hub':
        return Icons.hub_outlined;
      case 'lan':
        return Icons.lan_outlined;
      case 'storage':
        return Icons.storage_rounded;
      case 'terminal':
        return Icons.terminal_rounded;
      case 'calculate':
        return Icons.calculate_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'colorValue': colorValue,
      'iconName': iconName,
      'dateCreated': dateCreated.toIso8601String(),
    };
  }

  factory SubjectItem.fromMap(Map<String, dynamic> map) {
    return SubjectItem(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String? ?? '',
      colorValue: map['colorValue'] as int? ?? 0xFF1E3A8A,
      iconName: map['iconName'] as String? ?? 'school',
      dateCreated: DateTime.tryParse(map['dateCreated'] as String? ?? '') ?? DateTime.now(),
    );
  }

  SubjectItem copyWith({
    String? id,
    String? name,
    String? code,
    int? colorValue,
    String? iconName,
    DateTime? dateCreated,
  }) {
    return SubjectItem(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      dateCreated: dateCreated ?? this.dateCreated,
    );
  }
}

/// [DocumentItem]: Mô hình thực thể Tài liệu học tập
class DocumentItem {
  final String id;
  final String title;
  final String subjectId;
  final DocumentType type;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final String note;
  final bool isFavorite;
  final bool isCompleted;
  final DateTime? deadline;
  final DateTime dateCreated;
  final DateTime dateModified;

  const DocumentItem({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.type,
    this.fileUrl = '',
    this.fileType = 'PDF',
    this.fileSize = 0,
    this.note = '',
    this.isFavorite = false,
    this.isCompleted = false,
    this.deadline,
    required this.dateCreated,
    required this.dateModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subjectId': subjectId,
      'type': type.name,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'note': note,
      'isFavorite': isFavorite ? 1 : 0,
      'isCompleted': isCompleted ? 1 : 0,
      'deadline': deadline?.toIso8601String(),
      'dateCreated': dateCreated.toIso8601String(),
      'dateModified': dateModified.toIso8601String(),
    };
  }

  factory DocumentItem.fromMap(Map<String, dynamic> map) {
    return DocumentItem(
      id: map['id'] as String,
      title: map['title'] as String,
      subjectId: map['subjectId'] as String,
      type: DocumentType.fromString(map['type'] as String?),
      fileUrl: map['fileUrl'] as String? ?? '',
      fileType: map['fileType'] as String? ?? 'PDF',
      fileSize: map['fileSize'] as int? ?? 0,
      note: map['note'] as String? ?? '',
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      deadline: map['deadline'] != null ? DateTime.tryParse(map['deadline'] as String) : null,
      dateCreated: DateTime.tryParse(map['dateCreated'] as String? ?? '') ?? DateTime.now(),
      dateModified: DateTime.tryParse(map['dateModified'] as String? ?? '') ?? DateTime.now(),
    );
  }

  DocumentItem copyWith({
    String? id,
    String? title,
    String? subjectId,
    DocumentType? type,
    String? fileUrl,
    String? fileType,
    int? fileSize,
    String? note,
    bool? isFavorite,
    bool? isCompleted,
    DateTime? deadline,
    DateTime? dateCreated,
    DateTime? dateModified,
  }) {
    return DocumentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      note: note ?? this.note,
      isFavorite: isFavorite ?? this.isFavorite,
      isCompleted: isCompleted ?? this.isCompleted,
      deadline: deadline ?? this.deadline,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
    );
  }
}

/// [DocumentWithSubject]: Thực thể DTO liên kết giữa Tài liệu và Môn học (tương tự ViewModel)
class DocumentWithSubject {
  final DocumentItem document;
  final SubjectItem? subject;

  const DocumentWithSubject({
    required this.document,
    this.subject,
  });

  String get id => document.id;
  String get title => document.title;
  DocumentType get type => document.type;
  String get subjectName => subject?.name ?? 'Chưa phân loại';
  String get subjectCode => subject?.code ?? '';
  Color get subjectColor => subject?.color ?? AppColors.secondary;
  bool get isFavorite => document.isFavorite;
  bool get isCompleted => document.isCompleted;
  DateTime? get deadline => document.deadline;
  String get note => document.note;
  String get fileUrl => document.fileUrl;
  String get fileType => document.fileType;
  int get fileSize => document.fileSize;
  DateTime get dateModified => document.dateModified;
}
