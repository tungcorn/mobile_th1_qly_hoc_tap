import 'package:flutter/material.dart';
import '../colors.dart';
import '../functions.dart';
import '../struct/databaseGlobal.dart';
import '../struct/documentModels.dart';
import '../struct/documentService.dart';
import 'subjectsPage.dart';

/// [AddEditDocumentPage]: Màn hình Thêm mới hoặc Chỉnh sửa thông tin Tài liệu học tập
class AddEditDocumentPage extends StatefulWidget {
  final DocumentItem? documentToEdit;

  const AddEditDocumentPage({super.key, this.documentToEdit});

  @override
  State<AddEditDocumentPage> createState() => _AddEditDocumentPageState();
}

class _AddEditDocumentPageState extends State<AddEditDocumentPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _fileUrlController;
  late TextEditingController _fileSizeController;
  late TextEditingController _noteController;

  String? _selectedSubjectId;
  DocumentType _selectedType = DocumentType.lecture;
  String _selectedFileType = 'PDF';
  bool _isFavorite = false;
  bool _isCompleted = false;
  DateTime? _selectedDeadline;

  List<SubjectItem> _availableSubjects = [];
  bool _isLoadingSubjects = true;
  bool _isSaving = false;

  bool get _isEditing => widget.documentToEdit != null;

  @override
  void initState() {
    super.initState();
    final doc = widget.documentToEdit;

    _titleController = TextEditingController(text: doc?.title ?? '');
    _fileUrlController = TextEditingController(text: doc?.fileUrl ?? '');
    _fileSizeController = TextEditingController(
      text: doc != null && doc.fileSize > 0 ? (doc.fileSize / 1024).toStringAsFixed(0) : '',
    );
    _noteController = TextEditingController(text: doc?.note ?? '');

    if (doc != null) {
      _selectedSubjectId = doc.subjectId;
      _selectedType = doc.type;
      _selectedFileType = doc.fileType;
      _isFavorite = doc.isFavorite;
      _isCompleted = doc.isCompleted;
      _selectedDeadline = doc.deadline;
    }

    _loadSubjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fileUrlController.dispose();
    _fileSizeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final subjects = await database.getAllSubjects();
    if (mounted) {
      setState(() {
        _availableSubjects = subjects;
        _isLoadingSubjects = false;
        if (_selectedSubjectId == null && subjects.isNotEmpty) {
          _selectedSubjectId = subjects.first.id;
        }
      });
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now.add(const Duration(days: 3)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDeadline != null
            ? TimeOfDay(hour: _selectedDeadline!.hour, minute: _selectedDeadline!.minute)
            : const TimeOfDay(hour: 23, minute: 59),
      );

      final hour = pickedTime?.hour ?? 23;
      final minute = pickedTime?.minute ?? 59;

      setState(() {
        _selectedDeadline = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          hour,
          minute,
        );
      });
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectId == null) {
      AppFunctions.showCustomSnackbar(context, 'Vui lòng chọn môn học.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final sizeInKb = int.tryParse(_fileSizeController.text.trim()) ?? 0;
      final sizeInBytes = sizeInKb * 1024;

      if (_isEditing) {
        await DocumentService.updateDocument(
          id: widget.documentToEdit!.id,
          title: _titleController.text,
          subjectId: _selectedSubjectId!,
          type: _selectedType,
          fileUrl: _fileUrlController.text,
          fileType: _selectedFileType,
          fileSize: sizeInBytes,
          note: _noteController.text,
          isFavorite: _isFavorite,
          isCompleted: _isCompleted,
          deadline: _selectedDeadline,
          dateCreated: widget.documentToEdit!.dateCreated,
        );
        if (mounted) {
          AppFunctions.showCustomSnackbar(context, 'Đã cập nhật tài liệu thành công.');
          Navigator.of(context).pop(true);
        }
      } else {
        await DocumentService.createDocument(
          title: _titleController.text,
          subjectId: _selectedSubjectId!,
          type: _selectedType,
          fileUrl: _fileUrlController.text,
          fileType: _selectedFileType,
          fileSize: sizeInBytes,
          note: _noteController.text,
          isFavorite: _isFavorite,
          isCompleted: _isCompleted,
          deadline: _selectedDeadline,
        );
        if (mounted) {
          AppFunctions.showCustomSnackbar(context, 'Đã thêm tài liệu mới thành công.');
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppFunctions.showCustomSnackbar(context, 'Lỗi: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa Tài liệu' : 'Thêm Tài liệu Mới'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveDocument,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_isEditing ? 'Lưu' : 'Tạo mới'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoadingSubjects
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Tiêu đề tài liệu
                  Text(
                    'Tiêu đề tài liệu *',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Ví dụ: Slide Bài giảng Chương 2, Bài tập TH1...',
                      prefixIcon: Icon(Icons.title_rounded, size: 20),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Tiêu đề không được để trống.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Chọn Môn học
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Môn học *',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Thêm môn mới', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SubjectsManagementPage()),
                          );
                          _loadSubjects();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.school_outlined, size: 20),
                    ),
                    items: _availableSubjects.map((sub) {
                      return DropdownMenuItem(
                        value: sub.id,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: sub.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              sub.code.isNotEmpty ? '${sub.code} - ${sub.name}' : sub.name,
                              style: const TextStyle(fontSize: 13.5),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedSubjectId = val);
                    },
                    validator: (val) => val == null ? 'Vui lòng chọn môn học' : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. Phân loại tài liệu
                  Text(
                    'Phân loại tài liệu',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DocumentType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type.icon,
                              size: 15,
                              color: isSelected ? theme.colorScheme.onPrimary : type.color,
                            ),
                            const SizedBox(width: 6),
                            Text(type.displayName),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: theme.colorScheme.primary,
                        backgroundColor: theme.colorScheme.surface,
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedType = type);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 4. Nếu là Bài tập: Thiết lập Hạn chót & Trạng thái hoàn thành
                  if (_selectedType == DocumentType.assignment) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.assignmentContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.assignmentColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.schedule_rounded, size: 18, color: AppColors.assignmentColor),
                                  SizedBox(width: 6),
                                  Text(
                                    'Hạn nộp bài (Deadline)',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                  ),
                                ],
                              ),
                              if (_selectedDeadline != null)
                                TextButton(
                                  onPressed: () => setState(() => _selectedDeadline = null),
                                  child: const Text('Xóa hạn', style: TextStyle(fontSize: 12, color: AppColors.error)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickDeadline,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.colorScheme.outline),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDeadline != null
                                        ? AppFunctions.formatDateTime(_selectedDeadline)
                                        : 'Chưa đặt hạn chót (Nhấn để chọn)',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: _selectedDeadline != null
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurface.withOpacity(0.4),
                                    ),
                                  ),
                                  const Icon(Icons.calendar_month_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Đã nộp bài / Đã hoàn thành',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                            ),
                            value: _isCompleted,
                            activeColor: AppColors.success,
                            onChanged: (val) => setState(() => _isCompleted = val ?? false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 5. Đường dẫn / Tệp đính kèm
                  Text(
                    'Đường dẫn tệp / Liên kết tài liệu',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _fileUrlController,
                    decoration: const InputDecoration(
                      hintText: 'https://drive.google.com/..., C:\\Docs\\..., github...',
                      prefixIcon: Icon(Icons.link_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Định dạng tệp & Dung lượng
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Định dạng', style: theme.textTheme.labelSmall),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _selectedFileType,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: ['PDF', 'DOCX', 'PPTX', 'ZIP', 'XLSX', 'LINK', 'VIDEO']
                                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedFileType = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dung lượng (KB)', style: theme.textTheme.labelSmall),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _fileSizeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Ví dụ: 2500',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 6. Ghi chú mô tả
                  Text(
                    'Ghi chú nội dung',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Tóm tắt nội dung chính, hướng dẫn nộp bài, lưu ý ôn thi...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 7. Đánh dấu Yêu thích / Quan trọng
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Đánh dấu tài liệu quan trọng',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      'Ghim lên đầu danh sách và xuất hiện trong mục Quan trọng',
                      style: TextStyle(fontSize: 12),
                    ),
                    secondary: Icon(
                      _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: _isFavorite ? AppColors.tertiary : null,
                    ),
                    value: _isFavorite,
                    activeColor: AppColors.tertiary,
                    onChanged: (val) => setState(() => _isFavorite = val),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
