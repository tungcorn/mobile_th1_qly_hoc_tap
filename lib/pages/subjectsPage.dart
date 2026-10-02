import 'package:flutter/material.dart';
import '../colors.dart';
import '../functions.dart';
import '../struct/databaseGlobal.dart';
import '../struct/documentModels.dart';
import '../struct/documentService.dart';
import '../widgets/emptyStateView.dart';

/// [SubjectsManagementPage]: Màn hình Quản lý Danh mục Môn học (Thêm, Sửa, Xóa, Chọn màu)
class SubjectsManagementPage extends StatefulWidget {
  const SubjectsManagementPage({super.key});

  @override
  State<SubjectsManagementPage> createState() => _SubjectsManagementPageState();
}

class _SubjectsManagementPageState extends State<SubjectsManagementPage> {
  // Bảng màu chuẩn Material để chọn cho môn học
  static const List<int> _palette = [
    0xFF2563EB, // Xanh dương
    0xFF0D9488, // Xanh ngọc
    0xFFD97706, // Cam hổ phách
    0xFF7C3AED, // Tím
    0xFFDC2626, // Đỏ
    0xFF059669, // Lục bảo
    0xFF4F46E5, // Chàm
    0xFFE11D48, // Hồng đậm
    0xFF0284C7, // Xanh da trời
    0xFF475569, // Xám thép
  ];

  void _showAddEditSubjectDialog([SubjectItem? existingSubject]) {
    final isEditing = existingSubject != null;
    final nameCtrl = TextEditingController(text: existingSubject?.name ?? '');
    final codeCtrl = TextEditingController(text: existingSubject?.code ?? '');
    int selectedColor = existingSubject?.colorValue ?? _palette.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Chỉnh sửa Môn học' : 'Thêm Môn học Mới',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tên môn học
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên môn học *',
                      hintText: 'Ví dụ: Lập trình Di động',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mã môn học
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mã học phần',
                      hintText: 'Ví dụ: IT4040',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chọn màu sắc đại diện
                  const Text(
                    'Màu sắc đại diện',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _palette.map((c) {
                      final isSelected = selectedColor == c;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: Color(c).withOpacity(0.5), blurRadius: 6)]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Nút Lưu
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          AppFunctions.showCustomSnackbar(context, 'Tên môn học không được để trống.', isError: true);
                          return;
                        }

                        Navigator.of(ctx).pop();

                        if (isEditing) {
                          await DocumentService.updateSubject(
                            existingSubject.copyWith(
                              name: nameCtrl.text.trim(),
                              code: codeCtrl.text.trim().toUpperCase(),
                              colorValue: selectedColor,
                            ),
                          );
                          if (mounted) {
                            AppFunctions.showCustomSnackbar(context, 'Đã cập nhật môn học.');
                          }
                        } else {
                          await DocumentService.createSubject(
                            name: nameCtrl.text.trim(),
                            code: codeCtrl.text.trim().toUpperCase(),
                            colorValue: selectedColor,
                          );
                          if (mounted) {
                            AppFunctions.showCustomSnackbar(context, 'Đã thêm môn học mới.');
                          }
                        }
                      },
                      child: Text(isEditing ? 'Cập nhật' : 'Tạo mới'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSubject(SubjectItem subject) async {
    final confirmed = await AppFunctions.showConfirmDialog(
      context,
      title: 'Xóa môn học',
      message: 'Bạn có chắc muốn xóa môn "${subject.name}"? Tất cả tài liệu thuộc môn học này cũng sẽ bị xóa.',
      confirmText: 'Xóa môn học',
      confirmColor: AppColors.error,
    );

    if (confirmed == true && mounted) {
      await DocumentService.deleteSubject(subject.id);
      if (mounted) {
        AppFunctions.showCustomSnackbar(context, 'Đã xóa môn học thành công.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Môn học'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSubjectDialog(),
        tooltip: 'Thêm môn học',
        child: const Icon(Icons.add_rounded),
      ),
      body: StreamBuilder<List<SubjectItem>>(
        stream: database.watchAllSubjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjects = snapshot.data ?? [];

          if (subjects.isEmpty) {
            return EmptyStateView(
              icon: Icons.school_outlined,
              title: 'Chưa có môn học nào',
              description: 'Nhấn nút "+" bên dưới để thêm môn học đầu tiên của bạn.',
              actionText: 'Thêm môn học',
              onAction: () => _showAddEditSubjectDialog(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final sub = subjects[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: sub.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(sub.icon, color: sub.color, size: 22),
                  ),
                  title: Text(
                    sub.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    sub.code.isNotEmpty ? 'Mã HP: ${sub.code}' : 'Chưa có mã học phần',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 19),
                        tooltip: 'Sửa',
                        onPressed: () => _showAddEditSubjectDialog(sub),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.error),
                        tooltip: 'Xóa',
                        onPressed: () => _deleteSubject(sub),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
