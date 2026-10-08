import 'package:file_saver/file_saver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../cloud/cloudDocument.dart';
import '../cloud/cloudDocumentService.dart';
import '../cloud/firebaseBootstrap.dart';
import '../functions.dart';
import '../widgets/cloudUi.dart';
import '../widgets/emptyStateView.dart';
import 'cloudDocumentFormPage.dart';

class CloudDocumentsPage extends StatefulWidget {
  final CloudDocumentService? service;

  const CloudDocumentsPage({super.key, this.service});

  @override
  State<CloudDocumentsPage> createState() => _CloudDocumentsPageState();
}

class _CloudDocumentsPageState extends State<CloudDocumentsPage> {
  CloudDocumentService? _service;
  Stream<User?>? _authStream;
  int _authVersion = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    if (_service == null && FirebaseBootstrap.isReady) {
      _service = CloudDocumentService();
    }
    _authStream = _service?.authChanges;
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    if (service == null) {
      final error = FirebaseBootstrap.initializationError;
      final reason = !FirebaseBootstrap.platformSupported
          ? 'Kho Cloud chỉ hỗ trợ web và Android. Trên nền tảng này, bạn vẫn có thể quản lý tài liệu cục bộ bằng SQLite.'
          : !FirebaseBootstrap.hasConfiguration
          ? 'Chưa có cấu hình Firebase. Hãy cung cấp cấu hình dự án trước khi chạy ứng dụng. Tài liệu cục bộ vẫn hoạt động bình thường.'
          : 'Firebase chưa sẵn sàng. Kiểm tra cấu hình và kết nối, sau đó khởi động lại ứng dụng.';
      return CloudScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CloudMessage(
              title: error == null ? 'Kho Cloud chưa khả dụng' : 'Không thể khởi tạo Firebase',
              message: '$reason\n\nXem HUONG_DAN_FIREBASE_VA_DEMO.md để cấu hình Firebase thật hoặc chạy bản demo Emulator.',
              isError: error != null,
            ),
            if (error != null) ...[
              const SizedBox(height: CloudUi.standard),
              CloudMessage(title: 'Chi tiết khởi tạo', message: error, isError: true),
            ],
          ],
        ),
      );
    }

    return StreamBuilder<User?>(
      key: ValueKey(_authVersion),
      stream: _authStream,
      initialData: service.currentUser,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return CloudScaffold(
            child: CloudMessage(
              title: 'Không thể theo dõi phiên đăng nhập',
              message: cloudErrorMessage(snapshot.error!),
              isError: true,
              action: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _authVersion++;
                  _authStream = service.authChanges;
                }),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const CloudScaffold(
            child: CloudPanel(
              title: 'Đang kiểm tra phiên đăng nhập',
              child: LinearProgressIndicator(),
            ),
          );
        }
        final user = snapshot.data;
        if (user == null || service.currentUser?.uid != user.uid) {
          return _CloudSignInView(key: const ValueKey('signed-out'), service: service);
        }
        return _CloudAccountView(
          key: ValueKey(user.uid),
          service: service,
          user: user,
        );
      },
    );
  }
}

class _CloudSignInView extends StatefulWidget {
  final CloudDocumentService service;

  const _CloudSignInView({super.key, required this.service});

  @override
  State<_CloudSignInView> createState() => _CloudSignInViewState();
}

class _CloudSignInViewState extends State<_CloudSignInView> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn([String? email]) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (FirebaseBootstrap.useEmulator) {
        await widget.service.signInEmulator(email!);
      } else {
        await widget.service.signInWithGoogle();
      }
    } catch (error) {
      if (mounted) setState(() => _error = cloudErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CloudScaffold(
      busy: _busy,
      maxWidth: CloudUi.formWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (FirebaseBootstrap.useEmulator) ...[
            const CloudMessage(
              title: 'Emulator - không phải Google/Cloud thật',
              message: 'Chỉ dùng tài khoản thử nghiệm. Dữ liệu nằm trong Firebase Emulator, không phải dự án Cloud thật.',
              isWarning: true,
            ),
            const SizedBox(height: CloudUi.standard),
          ],
          CloudPanel(
            title: 'Tài liệu riêng theo tài khoản',
            icon: Icons.cloud_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Đăng nhập để tải tệp thật lên kho riêng, chỉnh sửa và tải xuống sau khi xác thực. Kho Cloud không tự đồng bộ tài liệu SQLite.'),
                const SizedBox(height: CloudUi.standard),
                SelectableText('Project ID: ${FirebaseBootstrap.activeProjectId}'),
                const SizedBox(height: CloudUi.standard),
                if (FirebaseBootstrap.useEmulator)
                  Wrap(
                    spacing: CloudUi.small,
                    runSpacing: CloudUi.small,
                    children: [
                      for (final email in ['alice@example.test', 'bob@example.test'])
                        OutlinedButton.icon(
                          onPressed: _busy ? null : () => _signIn(email),
                          icon: const Icon(Icons.person_outline_rounded),
                          label: Text(email),
                        ),
                    ],
                  )
                else
                  FilledButton.icon(
                    onPressed: _busy ? null : _signIn,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Đăng nhập bằng Google'),
                  ),
                if (_busy) ...[
                  const SizedBox(height: CloudUi.standard),
                  const LinearProgressIndicator(),
                  const SizedBox(height: CloudUi.small),
                  const Text('Đang đăng nhập...'),
                ],
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: CloudUi.standard),
            CloudMessage(title: 'Đăng nhập chưa thành công', message: _error!, isError: true),
          ],
          const SizedBox(height: CloudUi.standard),
          const Text('Cấu hình Google, nền tảng web/Android và cách demo: HUONG_DAN_FIREBASE_VA_DEMO.md.'),
        ],
      ),
    );
  }
}

class _CloudAccountView extends StatefulWidget {
  final CloudDocumentService service;
  final User user;

  const _CloudAccountView({super.key, required this.service, required this.user});

  @override
  State<_CloudAccountView> createState() => _CloudAccountViewState();
}

class _CloudAccountViewState extends State<_CloudAccountView> {
  static const _demoDocumentLimit = 100;
  final _searchController = TextEditingController();
  late Stream<List<CloudDocument>> _documentsStream;
  int _streamVersion = 0;
  bool _busy = false;
  String? _status;
  String? _error;

  bool get _sessionActive => widget.service.currentUser?.uid == widget.user.uid;

  @override
  void initState() {
    super.initState();
    _documentsStream = widget.service.watchDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (_busy || !_sessionActive) return;
    setState(() {
      _streamVersion++;
      _documentsStream = widget.service.watchDocuments();
    });
  }

  Future<void> _perform(String status, Future<void> Function() operation) async {
    if (_busy || !_sessionActive) return;
    setState(() {
      _busy = true;
      _status = status;
      _error = null;
    });
    try {
      await operation();
    } catch (error) {
      if (mounted && _sessionActive) {
        setState(() => _error = cloudErrorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = null;
        });
      }
    }
  }

  Future<void> _openForm([CloudDocument? document]) async {
    await _perform('Đang mở biểu mẫu tài liệu...', () async {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CloudDocumentFormPage(
            service: widget.service,
            ownerId: widget.user.uid,
            document: document,
          ),
        ),
      );
      if (saved == true && mounted && _sessionActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu tài liệu. Danh sách cập nhật theo thời gian thực.')),
        );
      }
    });
  }

  Future<void> _download(CloudDocument document) async {
    await _perform('Đang tải tệp đã xác thực...', () async {
      final bytes = await widget.service.downloadDocument(document);
      if (!mounted || !_sessionActive) return;
      final fileName = path.basename(document.fileName);
      final extension = path.extension(fileName);
      final saved = await FileSaver.instance.saveAs(
        name: path.basenameWithoutExtension(fileName),
        bytes: bytes,
        fileExtension: extension.isEmpty ? '' : extension.substring(1),
        mimeType: MimeType.custom,
        customMimeType: document.contentType,
      );
      if (mounted && _sessionActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(saved == null
              ? 'Đã hủy lưu tệp.'
              : kIsWeb
              ? 'Đã gửi "$fileName" tới trình duyệt để tải xuống.'
              : 'Đã lưu "$fileName" vào vị trí bạn chọn.')),
        );
      }
    });
  }

  Future<void> _delete(CloudDocument document) async {
    await _perform('Đang xử lý yêu cầu xóa...', () async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Xóa tài liệu Cloud?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(document.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: CloudUi.small),
              const Text('Tệp và thông tin trên Cloud sẽ bị xóa. Tài liệu cục bộ không thay đổi.'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Hủy bỏ')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa tài liệu'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted && _sessionActive) {
        await widget.service.deleteDocument(document);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CloudScaffold(
      busy: _busy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (FirebaseBootstrap.useEmulator) ...[
            const CloudMessage(
              title: 'Emulator - không phải Google/Cloud thật',
              message: 'Dữ liệu thử nghiệm được tách theo UID. Đăng xuất rồi dùng tài khoản còn lại để kiểm tra cách ly dữ liệu.',
              isWarning: true,
            ),
            const SizedBox(height: CloudUi.standard),
          ],
          CloudPanel(
            title: 'Tài khoản hiện tại',
            icon: Icons.verified_user_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText('Email: ${widget.user.email ?? 'Không có email'}'),
                const SizedBox(height: CloudUi.tight),
                SelectableText('UID: ${widget.user.uid}'),
                const SizedBox(height: CloudUi.tight),
                SelectableText('Project ID: ${FirebaseBootstrap.activeProjectId}'),
                const SizedBox(height: CloudUi.medium),
                Wrap(
                  spacing: CloudUi.small,
                  runSpacing: CloudUi.small,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : _openForm,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Tải tệp lên Cloud'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Làm mới'),
                    ),
                    TextButton.icon(
                      onPressed: _busy ? null : () => _perform('Đang đăng xuất...', widget.service.signOut),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: CloudUi.standard),
            const LinearProgressIndicator(),
            const SizedBox(height: CloudUi.small),
            Text(_status!),
          ],
          if (_error != null) ...[
            const SizedBox(height: CloudUi.standard),
            CloudMessage(title: 'Thao tác chưa thành công', message: _error!, isError: true),
          ],
          const SizedBox(height: CloudUi.section),
          Text('Tài liệu của bạn', style: theme.textTheme.titleLarge),
          const SizedBox(height: CloudUi.medium),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Tìm trong kho của bạn',
              hintText: 'Tiêu đề, môn học, ghi chú hoặc tên tệp',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: CloudUi.small),
          const Text('Bản demo lọc trên thiết bị trong tối đa 100 tài liệu mới nhất của luồng đã tải. Đây không phải tìm kiếm full-text trên máy chủ. Danh sách tự cập nhật khi dữ liệu thay đổi.'),
          const SizedBox(height: CloudUi.standard),
          StreamBuilder<List<CloudDocument>>(
            key: ValueKey('${widget.user.uid}:$_streamVersion'),
            stream: _documentsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return CloudMessage(
                  title: 'Không tải được danh sách Cloud',
                  message: '${cloudErrorMessage(snapshot.error!)}\nKho Cloud cần kết nối mạng; tài liệu SQLite vẫn có thể dùng ngoại tuyến.',
                  isError: true,
                  action: OutlinedButton(onPressed: _busy ? null : _refresh, child: const Text('Thử lại')),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CloudPanel(title: 'Đang tải tài liệu...', child: LinearProgressIndicator());
              }
              final query = _searchController.text.trim().toLowerCase();
              final recent = (snapshot.data ?? []).take(_demoDocumentLimit).toList();
              final documents = recent.where((document) =>
                '${document.title} ${document.subject} ${document.note} ${document.fileName}'.toLowerCase().contains(query)).toList();
              if (documents.isEmpty) {
                return EmptyStateView(
                  icon: query.isEmpty ? Icons.cloud_outlined : Icons.search_off_rounded,
                  title: query.isEmpty ? 'Kho Cloud chưa có tài liệu' : 'Không tìm thấy tài liệu Cloud',
                  description: query.isEmpty
                      ? 'Chọn tệp thật từ thiết bị để tải lên kho riêng của tài khoản này.'
                      : 'Thử từ khóa khác trong phạm vi tài liệu demo đã tải.',
                  actionText: query.isEmpty ? 'Tải tệp đầu tiên' : 'Xóa từ khóa',
                  onAction: _busy ? null : () {
                    if (query.isEmpty) {
                      _openForm();
                    } else {
                      setState(_searchController.clear);
                    }
                  },
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${documents.length}/${recent.length} tài liệu trong phạm vi demo', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: CloudUi.small),
                  for (final document in documents) ...[
                    CloudPanel(
                      key: ValueKey(document.id),
                      title: document.title,
                      icon: Icons.description_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(document.subject, style: theme.textTheme.titleSmall),
                          const SizedBox(height: CloudUi.small),
                          SelectableText('${document.fileName}\n${AppFunctions.formatFileSize(document.size)} · ${AppFunctions.formatRelativeTime(document.createdAt)}'),
                          if (document.note.isNotEmpty) ...[
                            const SizedBox(height: CloudUi.small),
                            SelectableText(document.note),
                          ],
                          const SizedBox(height: CloudUi.medium),
                          Wrap(
                            spacing: CloudUi.small,
                            runSpacing: CloudUi.small,
                            children: [
                              OutlinedButton.icon(onPressed: _busy ? null : () => _download(document), icon: const Icon(Icons.download_rounded), label: const Text('Tải xuống')),
                              TextButton.icon(onPressed: _busy ? null : () => _openForm(document), icon: const Icon(Icons.edit_outlined), label: const Text('Sửa tiêu đề / ghi chú')),
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                                onPressed: _busy ? null : () => _delete(document),
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Xóa'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: CloudUi.medium),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
