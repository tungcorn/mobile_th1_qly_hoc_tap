import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../cloud/cloudDocument.dart';
import '../cloud/cloudDocumentService.dart';
import '../cloud/firebaseBootstrap.dart';
import '../functions.dart';
import '../struct/documentModels.dart';
import '../widgets/cloudLocalDocumentPicker.dart';
import '../widgets/cloudUi.dart';

class CloudDocumentFormPage extends StatefulWidget {
  final CloudDocumentService service;
  final String ownerId;
  final CloudDocument? document;

  const CloudDocumentFormPage({
    super.key,
    required this.service,
    required this.ownerId,
    this.document,
  });

  @override
  State<CloudDocumentFormPage> createState() => _CloudDocumentFormPageState();
}

class _CloudDocumentFormPageState extends State<CloudDocumentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  late final TextEditingController _noteController;
  late final Stream<User?> _authStream;
  Uint8List? _fileBytes;
  String? _fileName;
  String? _error;
  bool _busy = false;
  bool _uploading = false;
  double _progress = 0;
  String _status = '';

  bool get _editing => widget.document != null;
  bool get _sessionActive => widget.service.currentUser?.uid == widget.ownerId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document?.title);
    _subjectController = TextEditingController(text: widget.document?.subject);
    _noteController = TextEditingController(text: widget.document?.note);
    _authStream = widget.service.authChanges;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _start(String status) {
    setState(() {
      _busy = true;
      _status = status;
      _error = null;
    });
  }

  void _finish() {
    if (mounted) {
      setState(() {
        _busy = false;
        _uploading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    if (_busy || !_sessionActive) return;
    _start('Đang chọn và đọc tệp...');
    try {
      final selected = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: CloudFilePolicy.mimeTypes.keys.toList(),
      );
      if (selected == null || !mounted || !_sessionActive) return;
      CloudFilePolicy.contentTypeFor(selected.name);
      final length = selected.lengthSync() ?? await selected.length();
      if (length != null && (length == 0 || length > CloudFilePolicy.maxBytes)) {
        throw ArgumentError('Tệp phải có dữ liệu và không vượt quá 10 MiB.');
      }
      if (!mounted || !_sessionActive) return;
      final bytes = await selected.readAsBytes();
      if (bytes.isEmpty || bytes.length > CloudFilePolicy.maxBytes) {
        throw ArgumentError('Tệp phải có dữ liệu và không vượt quá 10 MiB.');
      }
      if (!mounted || !_sessionActive) return;
      setState(() {
        _fileName = selected.name;
        _fileBytes = bytes;
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = path.basenameWithoutExtension(selected.name);
        }
      });
    } catch (error) {
      if (mounted && _sessionActive) {
        setState(() {
          _fileName = null;
          _fileBytes = null;
          _error = cloudErrorMessage(error);
        });
      }
    } finally {
      _finish();
    }
  }

  Future<void> _prefillLocal() async {
    if (_busy || !_sessionActive) return;
    _start('Đang chọn thông tin tài liệu cục bộ...');
    try {
      final local = await showModalBottomSheet<DocumentWithSubject>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: CloudUi.formWidth),
        builder: (_) => const FractionallySizedBox(
          heightFactor: 0.85,
          child: CloudLocalDocumentPicker(),
        ),
      );
      if (local == null || !mounted || !_sessionActive) return;
      setState(() {
        _titleController.text = local.title;
        _subjectController.text = local.subjectName;
        _noteController.text = local.note;
        _fileName = null;
        _fileBytes = null;
      });
    } catch (error) {
      if (mounted && _sessionActive) {
        setState(() => _error = cloudErrorMessage(error));
      }
    } finally {
      _finish();
    }
  }

  String? _requiredText(String? value, int maxLength, String label) {
    final text = value?.trim() ?? '';
    return text.isEmpty || text.length > maxLength
        ? '$label cần từ 1 đến $maxLength ký tự.'
        : null;
  }

  Future<void> _save() async {
    if (_busy || !_sessionActive || !_formKey.currentState!.validate()) return;
    if (!_editing && _fileBytes == null) {
      setState(() => _error = 'Vui lòng chọn tệp thật từ thiết bị. Thông tin cục bộ hoặc đường dẫn không thay thế dữ liệu tệp.');
      return;
    }
    _start(_editing ? 'Đang lưu thay đổi...' : 'Đang tải tệp lên Cloud...');
    setState(() {
      _uploading = !_editing;
      _progress = 0;
    });
    try {
      final document = widget.document;
      if (document != null) {
        await widget.service.updateDocument(document, _titleController.text, _noteController.text);
      } else {
        final upload = CloudUpload(
          title: _titleController.text,
          subject: _subjectController.text,
          note: _noteController.text,
          fileName: _fileName!,
          bytes: _fileBytes!,
        );
        await widget.service.uploadDocument(
          upload,
          onProgress: (progress) {
            if (mounted && _sessionActive) {
              setState(() => _progress = progress.clamp(0.0, 1.0));
            }
          },
        );
      }
      if (mounted && _sessionActive) {
        _finish();
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted && _sessionActive) {
        setState(() => _error = cloudErrorMessage(error));
      }
    } finally {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      initialData: widget.service.currentUser,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return CloudScaffold(
            busy: _busy,
            child: CloudMessage(title: 'Không xác minh được phiên đăng nhập', message: cloudErrorMessage(snapshot.error!), isError: true),
          );
        }
        if (snapshot.data?.uid != widget.ownerId || !_sessionActive) {
          return CloudScaffold(
            busy: _busy,
            child: const CloudMessage(
              title: 'Phiên đăng nhập đã thay đổi',
              message: 'Thông tin tài khoản trước đã được ẩn. Quay lại Kho Cloud và đăng nhập trước khi tiếp tục.',
              isError: true,
            ),
          );
        }
        final theme = Theme.of(context);
        return CloudScaffold(
          title: _editing ? 'Chỉnh sửa tài liệu Cloud' : 'Tải tệp lên Cloud',
          busy: _busy,
          maxWidth: CloudUi.formWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (FirebaseBootstrap.useEmulator) ...[
                const CloudMessage(
                  title: 'Emulator - không phải Google/Cloud thật',
                  message: 'Tệp này chỉ được gửi tới Firebase Emulator để thử nghiệm.',
                  isWarning: true,
                ),
                const SizedBox(height: CloudUi.standard),
              ],
              CloudPanel(
                title: _editing ? 'Thông tin tài liệu' : 'Chọn thông tin và tệp thật',
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_editing) ...[
                        const Text('Có thể điền sẵn từ tài liệu cục bộ, nhưng bạn vẫn phải chọn tệp thật. Không tự đồng bộ hoặc đọc liên kết đã lưu trong SQLite.'),
                        const SizedBox(height: CloudUi.small),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _prefillLocal,
                            icon: const Icon(Icons.library_books_outlined),
                            label: const Text('Điền từ tài liệu cục bộ'),
                          ),
                        ),
                        const SizedBox(height: CloudUi.standard),
                      ],
                      TextFormField(
                        controller: _titleController,
                        enabled: !_busy,
                        maxLength: 250,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Tiêu đề tài liệu', hintText: 'Ví dụ: Bài giảng Chương 2'),
                        validator: (value) => _requiredText(value, 250, 'Tiêu đề'),
                      ),
                      const SizedBox(height: CloudUi.standard),
                      if (!_editing)
                        TextFormField(
                          controller: _subjectController,
                          enabled: !_busy,
                          maxLength: 120,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Môn học', hintText: 'Ví dụ: Lập trình di động'),
                          validator: (value) => _requiredText(value, 120, 'Tên môn học'),
                        )
                      else
                        SelectableText('Môn học: ${widget.document!.subject}'),
                      const SizedBox(height: CloudUi.standard),
                      TextFormField(
                        controller: _noteController,
                        enabled: !_busy,
                        maxLength: 4000,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(labelText: 'Ghi chú', hintText: 'Tóm tắt nội dung hoặc lưu ý ôn tập', alignLabelWithHint: true),
                        validator: (value) => (value?.length ?? 0) > 4000 ? 'Ghi chú tối đa 4000 ký tự.' : null,
                      ),
                      const SizedBox(height: CloudUi.standard),
                      if (!_editing) ...[
                        Text('Tệp đính kèm', style: theme.textTheme.titleSmall),
                        const SizedBox(height: CloudUi.small),
                        Text('Tối đa 10 MiB. Định dạng: ${CloudFilePolicy.mimeTypes.keys.map((extension) => extension.toUpperCase()).join(', ')}.'),
                        const SizedBox(height: CloudUi.medium),
                        if (_fileName != null) ...[
                          SelectableText('$_fileName\n${AppFunctions.formatFileSize(_fileBytes!.length)}'),
                          const SizedBox(height: CloudUi.small),
                        ] else ...[
                          const Text('Chưa chọn tệp thật.'),
                          const SizedBox(height: CloudUi.small),
                        ],
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _pickFile,
                            icon: const Icon(Icons.attach_file_rounded),
                            label: Text(_fileName == null ? 'Chọn tệp từ thiết bị' : 'Chọn tệp khác'),
                          ),
                        ),
                        const SizedBox(height: CloudUi.standard),
                      ] else ...[
                        SelectableText('Tệp giữ nguyên: ${widget.document!.fileName}'),
                        const SizedBox(height: CloudUi.standard),
                      ],
                      FilledButton.icon(
                        onPressed: _busy ? null : _save,
                        icon: Icon(_editing ? Icons.check_rounded : Icons.cloud_upload_outlined),
                        label: Text(_editing ? 'Lưu thay đổi' : 'Tải tệp lên Cloud'),
                      ),
                    ],
                  ),
                ),
              ),
              if (_busy) ...[
                const SizedBox(height: CloudUi.standard),
                LinearProgressIndicator(value: _uploading ? _progress : null),
                const SizedBox(height: CloudUi.small),
                Text(_uploading
                    ? _progress < 1
                    ? 'Đang truyền tệp: ${(_progress * 100).round()}%. Vui lòng giữ trang này mở.'
                    : 'Đã truyền tệp. Đang lưu thông tin tài liệu, chưa hoàn tất.'
                    : _status),
              ],
              if (_error != null) ...[
                const SizedBox(height: CloudUi.standard),
                CloudMessage(title: 'Chưa hoàn tất thao tác', message: _error!, isError: true),
              ],
              const SizedBox(height: CloudUi.standard),
              const Text('Tệp được lưu trong kho riêng theo UID. Tài liệu cục bộ không thay đổi.'),
            ],
          ),
        );
      },
    );
  }
}
