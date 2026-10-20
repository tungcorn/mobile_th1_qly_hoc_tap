import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../cloud/notificationService.dart';
import '../cloud/supabaseDocumentService.dart';
import 'cloudUi.dart';
import 'documentMapView.dart';
import 'tagInput.dart';

/// Bỏ tiền tố "Exception: " của thông báo lỗi từ service.
String cloudErrorText(Object e) {
  final s = e.toString();
  return s.startsWith('Exception: ') ? s.substring(11) : s;
}

String _formatSize(int bytes) {
  if (bytes <= 0) return 'Không rõ';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _permissionLabel(SupabaseDocument doc) {
  switch (doc.permissionLevel) {
    case 'owner':
      return 'Chủ sở hữu';
    case 'editor':
      return 'Được chỉnh sửa';
    case 'viewer':
      return 'Chỉ xem';
    default:
      return 'Chưa có quyền';
  }
}

/// Bản sao tài liệu với quyền khác. Dùng 'none' cho tài liệu chỉ thấy do công khai
/// (fromMap mặc định gán 'viewer' cho tài liệu người khác).
SupabaseDocument documentWithPermission(SupabaseDocument d, String level) =>
    SupabaseDocument(
      id: d.id,
      ownerId: d.ownerId,
      title: d.title,
      description: d.description,
      fileUrl: d.fileUrl,
      fileName: d.fileName,
      fileSize: d.fileSize,
      mimeType: d.mimeType,
      createdAt: d.createdAt,
      updatedAt: d.updatedAt,
      ownerEmail: d.ownerEmail,
      permissionLevel: level,
      tags: d.tags,
      locationName: d.locationName,
      latitude: d.latitude,
      longitude: d.longitude,
      isPublic: d.isPublic,
      viewCount: d.viewCount,
    );

/// Gộp tài liệu của tôi/được chia sẻ với tài liệu công khai (khử trùng theo id).
/// Tài liệu công khai không nằm trong [accessible] được gán quyền 'none'.
List<SupabaseDocument> mergeAccessibleAndPublic(
  List<SupabaseDocument> accessible,
  List<SupabaseDocument> public,
) {
  final ids = accessible.map((d) => d.id).toSet();
  return [
    ...accessible,
    for (final d in public)
      if (!ids.contains(d.id)) documentWithPermission(d, 'none'),
  ];
}

bool _hasAccess(SupabaseDocument doc) =>
    doc.isOwner ||
    doc.permissionLevel == 'viewer' ||
    doc.permissionLevel == 'editor';

/// Hiển thị chi tiết tài liệu Supabase: bottom sheet (hẹp) hoặc dialog (rộng).
/// Ghi nhận lượt xem khi mở; [onChanged] được gọi khi đóng (lượt xem/yêu cầu mượn thay đổi).
Future<void> showCloudDocumentDetail(
  BuildContext context, {
  required SupabaseDocumentService service,
  required SupabaseDocument doc,
  VoidCallback? onChanged,
}) async {
  // Không chờ: lỗi chỉ được log trong service
  service.recordView(doc.id);

  final wide = MediaQuery.sizeOf(context).width >= CloudUi.compactBreakpoint;
  final content = _CloudDocumentDetail(service: service, doc: doc);

  if (wide) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: CloudUi.formWidth,
            maxHeight: 720,
          ),
          child: content,
        ),
      ),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.9,
        ),
        child: content,
      ),
    );
  }
  onChanged?.call();
}

class _CloudDocumentDetail extends StatefulWidget {
  final SupabaseDocumentService service;
  final SupabaseDocument doc;

  const _CloudDocumentDetail({required this.service, required this.doc});

  @override
  State<_CloudDocumentDetail> createState() => _CloudDocumentDetailState();
}

class _CloudDocumentDetailState extends State<_CloudDocumentDetail> {
  bool _busy = false;
  bool _requested = false;

  SupabaseDocument get doc => widget.doc;

  Future<void> _requestBorrow() async {
    final result = await showDialog<({String message, DateTime dueDate})>(
      context: context,
      builder: (_) => _BorrowRequestDialog(title: doc.title),
    );
    if (result == null || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.service.requestBorrow(
        doc,
        message: result.message,
        dueDate: result.dueDate,
      );
      await NotificationService.sendToUser(
        doc.ownerId,
        title: 'Yêu cầu mượn tài liệu',
        body: '${widget.service.currentUserEmail} muốn mượn "${doc.title}"',
        data: {'type': 'borrow_request', 'documentId': doc.id},
      );
      if (!mounted) return;
      setState(() => _requested = true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu mượn. Vui lòng chờ chủ sở hữu duyệt.'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(cloudErrorText(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyUrl() async {
    await Clipboard.setData(ClipboardData(text: doc.fileUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép đường dẫn tệp.')),
    );
  }

  Widget _info(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CloudUi.tight),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: CloudUi.small),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final access = _hasAccess(doc);
    final isDataUrl = doc.fileUrl.startsWith('data:');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        CloudUi.section,
        CloudUi.small,
        CloudUi.section,
        CloudUi.section,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  doc.title.isEmpty ? '(Không có tiêu đề)' : doc.title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Đóng',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          if (doc.description.isNotEmpty) ...[
            const SizedBox(height: CloudUi.small),
            SelectableText(doc.description, style: theme.textTheme.bodyMedium),
          ],
          if (doc.tags.isNotEmpty) ...[
            const SizedBox(height: CloudUi.medium),
            TagChips(tags: doc.tags),
          ],
          const SizedBox(height: CloudUi.medium),
          _info(Icons.person_outline_rounded, 'Chủ sở hữu',
              doc.isOwner ? 'Bạn' : (doc.ownerEmail ?? (doc.ownerId.isNotEmpty ? doc.ownerId : 'Không rõ'))),
          _info(Icons.insert_drive_file_outlined, 'Tệp',
              doc.fileName.isEmpty ? 'Không rõ' : doc.fileName),
          _info(Icons.straighten_rounded, 'Kích thước', _formatSize(doc.fileSize)),
          _info(Icons.visibility_outlined, 'Lượt xem', '${doc.viewCount}'),
          _info(
            doc.isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
            'Hiển thị',
            doc.isPublic ? 'Công khai' : 'Riêng tư',
          ),
          _info(Icons.verified_user_outlined, 'Quyền của bạn',
              _permissionLabel(doc)),
          _info(Icons.schedule_rounded, 'Cập nhật',
              DateFormat('dd/MM/yyyy HH:mm').format(doc.updatedAt.toLocal())),
          if (doc.hasLocation) ...[
            _info(Icons.place_outlined, 'Vị trí',
                doc.locationName ?? '${doc.latitude}, ${doc.longitude}'),
            const SizedBox(height: CloudUi.small),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                child: IgnorePointer(
                  child: DocumentMapView(
                    markers: [
                      MapMarkerData(
                        id: doc.id,
                        title: doc.title,
                        subtitle: doc.locationName ?? '',
                        point: LatLng(doc.latitude!, doc.longitude!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: CloudUi.section),
          if (access) ...[
            Text('Mở tệp', style: theme.textTheme.titleSmall),
            const SizedBox(height: CloudUi.small),
            Container(
              padding: const EdgeInsets.all(CloudUi.medium),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      doc.fileUrl.isEmpty
                          ? 'Tài liệu chưa có đường dẫn tệp.'
                          : isDataUrl
                              ? 'Tệp được nhúng trực tiếp (data URL, ${doc.fileUrl.length} ký tự)'
                              : doc.fileUrl,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: CloudUi.small),
                  FilledButton.tonalIcon(
                    onPressed: doc.fileUrl.isEmpty ? null : _copyUrl,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Sao chép'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CloudUi.tight),
            Text(
              'Dán đường dẫn vào trình duyệt để mở hoặc tải tệp.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ] else ...[
            CloudMessage(
              title: 'Bạn chưa có quyền mở tệp',
              message: _requested
                  ? 'Yêu cầu mượn đã được gửi. Bạn sẽ nhận thông báo khi chủ sở hữu phản hồi.'
                  : 'Gửi yêu cầu mượn để chủ sở hữu cấp quyền xem có thời hạn.',
            ),
            const SizedBox(height: CloudUi.medium),
            FilledButton.icon(
              onPressed: _busy || _requested ? null : _requestBorrow,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.handshake_outlined),
              label: Text(_requested ? 'Đã gửi yêu cầu' : 'Yêu cầu mượn'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialog nhập lời nhắn + hạn trả (mặc định +7 ngày).
class _BorrowRequestDialog extends StatefulWidget {
  final String title;

  const _BorrowRequestDialog({required this.title});

  @override
  State<_BorrowRequestDialog> createState() => _BorrowRequestDialogState();
}

class _BorrowRequestDialogState extends State<_BorrowRequestDialog> {
  final _message = TextEditingController();
  late DateTime _due = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Chọn hạn trả',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked != null && mounted) {
      // Hạn trả tính đến cuối ngày đã chọn
      setState(() => _due = DateTime(picked.year, picked.month, picked.day, 23, 59));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yêu cầu mượn tài liệu'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('"${widget.title}"',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: CloudUi.standard),
            TextField(
              controller: _message,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Lời nhắn cho chủ sở hữu',
                hintText: 'Ví dụ: Mình cần tài liệu để ôn thi giữa kỳ',
              ),
            ),
            const SizedBox(height: CloudUi.small),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_rounded),
              label: Text('Hạn trả: ${DateFormat('dd/MM/yyyy').format(_due)}'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context)
              .pop((message: _message.text.trim(), dueDate: _due)),
          child: const Text('Gửi yêu cầu'),
        ),
      ],
    );
  }
}
