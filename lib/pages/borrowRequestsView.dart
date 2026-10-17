import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../cloud/notificationService.dart';
import '../cloud/supabaseDocumentService.dart';
import '../widgets/cloudDocumentDetailSheet.dart';
import '../widgets/cloudUi.dart';

final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

/// Thân trang "Mượn tài liệu": yêu cầu đến (tôi là chủ) và yêu cầu tôi đã gửi.
/// Không có Scaffold riêng — được nhúng vào khung điều hướng của trang Supabase.
class BorrowRequestsView extends StatefulWidget {
  final SupabaseDocumentService service;

  const BorrowRequestsView({super.key, required this.service});

  @override
  State<BorrowRequestsView> createState() => _BorrowRequestsViewState();
}

class _BorrowRequestsViewState extends State<BorrowRequestsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  StreamSubscription<AppNotification>? _sub;

  bool _loading = true;
  String? _error;
  List<BorrowRequest> _incoming = [];
  List<BorrowRequest> _outgoing = [];
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _sub = NotificationService.stream.listen((n) {
      final type = n.data['type']?.toString() ?? '';
      if (type.startsWith('borrow')) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.service.getIncomingBorrowRequests(),
        widget.service.getOutgoingBorrowRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _incoming = results[0];
        _outgoing = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = cloudErrorText(e);
      });
    }
  }

  String _docTitle(BorrowRequest r) =>
      r.documentTitle.isEmpty ? 'tài liệu' : r.documentTitle;

  Future<bool> _confirm(String title, String message, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// Thực hiện thao tác, gửi thông báo cho bên còn lại rồi tải lại.
  Future<void> _run(
    BorrowRequest r, {
    required Future<void> Function(BorrowRequest) action,
    required String notifyUserId,
    required String type,
    required String title,
    required String body,
    required String success,
  }) async {
    setState(() => _busyIds.add(r.id));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action(r);
      await NotificationService.sendToUser(
        notifyUserId,
        title: title,
        body: body,
        data: {'type': type, 'requestId': r.id, 'documentId': r.documentId},
      );
      messenger.showSnackBar(SnackBar(content: Text(success)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(cloudErrorText(e))));
    } finally {
      if (mounted) setState(() => _busyIds.remove(r.id));
    }
    if (mounted) await _load();
  }

  Future<void> _approve(BorrowRequest r) async {
    final due = r.dueDate == null ? '' : ' đến ${_dateFmt.format(r.dueDate!)}';
    if (!await _confirm(
      'Duyệt yêu cầu mượn?',
      '${r.requesterEmail} sẽ được quyền xem "${_docTitle(r)}"$due.',
      'Duyệt',
    )) {
      return;
    }
    await _run(
      r,
      action: widget.service.approveBorrow,
      notifyUserId: r.requesterId,
      type: 'borrow_approved',
      title: 'Yêu cầu mượn đã được duyệt',
      body: 'Bạn đã được mượn "${_docTitle(r)}"$due.',
      success: 'Đã duyệt yêu cầu mượn.',
    );
  }

  Future<void> _reject(BorrowRequest r) async {
    if (!await _confirm(
      'Từ chối yêu cầu?',
      'Từ chối yêu cầu mượn "${_docTitle(r)}" của ${r.requesterEmail}.',
      'Từ chối',
    )) {
      return;
    }
    await _run(
      r,
      action: widget.service.rejectBorrow,
      notifyUserId: r.requesterId,
      type: 'borrow_rejected',
      title: 'Yêu cầu mượn bị từ chối',
      body: 'Chủ sở hữu đã từ chối yêu cầu mượn "${_docTitle(r)}".',
      success: 'Đã từ chối yêu cầu.',
    );
  }

  Future<void> _markReturned(BorrowRequest r) async {
    if (!await _confirm(
      'Đánh dấu đã trả?',
      'Quyền xem "${_docTitle(r)}" của ${r.requesterEmail} sẽ bị thu hồi.',
      'Xác nhận',
    )) {
      return;
    }
    await _run(
      r,
      action: widget.service.returnBorrow,
      notifyUserId: r.requesterId,
      type: 'borrow_returned',
      title: 'Tài liệu đã được thu hồi',
      body: 'Chủ sở hữu đã đánh dấu "${_docTitle(r)}" là đã trả.',
      success: 'Đã đánh dấu tài liệu đã trả.',
    );
  }

  Future<void> _cancel(BorrowRequest r) async {
    if (!await _confirm(
      'Hủy yêu cầu?',
      'Hủy yêu cầu mượn "${_docTitle(r)}".',
      'Hủy yêu cầu',
    )) {
      return;
    }
    await _run(
      r,
      action: widget.service.cancelBorrow,
      notifyUserId: r.ownerId,
      type: 'borrow_cancelled',
      title: 'Yêu cầu mượn đã bị hủy',
      body: '${widget.service.currentUserEmail} đã hủy yêu cầu mượn "${_docTitle(r)}".',
      success: 'Đã hủy yêu cầu.',
    );
  }

  Future<void> _return(BorrowRequest r) async {
    if (!await _confirm(
      'Trả tài liệu?',
      'Bạn sẽ không còn quyền xem "${_docTitle(r)}" sau khi trả.',
      'Trả tài liệu',
    )) {
      return;
    }
    await _run(
      r,
      action: widget.service.returnBorrow,
      notifyUserId: r.ownerId,
      type: 'borrow_returned',
      title: 'Tài liệu đã được trả',
      body: '${widget.service.currentUserEmail} đã trả "${_docTitle(r)}".',
      success: 'Đã trả tài liệu.',
    );
  }

  Widget _list(List<BorrowRequest> items, {required bool incoming}) {
    if (_error != null) {
      final needsMigration = _error!.contains('th2_migration.sql');
      return ListView(
        padding: const EdgeInsets.all(CloudUi.standard),
        children: [
          CloudMessage(
            title: needsMigration
                ? 'Cơ sở dữ liệu chưa được nâng cấp'
                : 'Không tải được yêu cầu mượn',
            message: needsMigration
                ? 'Chạy tệp supabase/th2_migration.sql trong Supabase Dashboard → SQL Editor để tạo bảng borrow_requests.\n\nChi tiết: $_error'
                : _error!,
            isError: !needsMigration,
            isWarning: needsMigration,
            action: FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }
    if (_loading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(CloudUi.standard),
              children: [
                CloudMessage(
                  title: incoming ? 'Chưa có yêu cầu đến' : 'Chưa gửi yêu cầu nào',
                  message: incoming
                      ? 'Khi có người muốn mượn tài liệu của bạn, yêu cầu sẽ xuất hiện ở đây.'
                      : 'Mở một tài liệu công khai trong mục Khám phá và chọn "Yêu cầu mượn".',
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(CloudUi.standard),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: CloudUi.small),
              itemBuilder: (_, i) => Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: CloudUi.contentWidth),
                  child: _requestCard(items[i], incoming: incoming),
                ),
              ),
            ),
    );
  }

  Widget _requestCard(BorrowRequest r, {required bool incoming}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy = _busyIds.contains(r.id);
    final muted =
        theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    final actions = <Widget>[
      if (incoming && r.status == BorrowStatus.pending) ...[
        OutlinedButton.icon(
          onPressed: busy ? null : () => _reject(r),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Từ chối'),
        ),
        FilledButton.icon(
          onPressed: busy ? null : () => _approve(r),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Duyệt'),
        ),
      ],
      if (incoming && r.status == BorrowStatus.approved)
        FilledButton.tonalIcon(
          onPressed: busy ? null : () => _markReturned(r),
          icon: const Icon(Icons.assignment_return_outlined),
          label: const Text('Đánh dấu đã trả'),
        ),
      if (!incoming && r.status == BorrowStatus.pending)
        OutlinedButton.icon(
          onPressed: busy ? null : () => _cancel(r),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Hủy yêu cầu'),
        ),
      if (!incoming && r.status == BorrowStatus.approved)
        FilledButton.tonalIcon(
          onPressed: busy ? null : () => _return(r),
          icon: const Icon(Icons.assignment_return_outlined),
          label: const Text('Trả tài liệu'),
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CloudUi.standard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    r.documentTitle.isEmpty
                        ? '(Tài liệu không còn tồn tại)'
                        : r.documentTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: CloudUi.small),
                _StatusChip(status: r.status),
              ],
            ),
            const SizedBox(height: CloudUi.small),
            Text(
              incoming
                  ? 'Người mượn: ${r.requesterEmail}'
                  : 'Gửi tới chủ sở hữu tài liệu',
              style: theme.textTheme.bodyMedium,
            ),
            if (r.message.isNotEmpty) ...[
              const SizedBox(height: CloudUi.tight),
              Text('"${r.message}"',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: CloudUi.small),
            Wrap(
              spacing: CloudUi.standard,
              runSpacing: CloudUi.tight,
              children: [
                Text('Gửi lúc: ${_dateFmt.format(r.createdAt)}', style: muted),
                if (r.dueDate != null)
                  Text('Hạn trả: ${_dateFmt.format(r.dueDate!)}', style: muted),
                if (r.respondedAt != null)
                  Text('Phản hồi: ${_dateFmt.format(r.respondedAt!)}',
                      style: muted),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: CloudUi.medium),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: CloudUi.small,
                runSpacing: CloudUi.small,
                children: [
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.all(CloudUi.small),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ...actions,
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingIn =
        _incoming.where((r) => r.status == BorrowStatus.pending).length;
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Yêu cầu đến'),
                  if (pendingIn > 0) ...[
                    const SizedBox(width: CloudUi.small),
                    Badge(label: Text('$pendingIn')),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Tôi đã gửi'),
          ],
        ),
        if (_loading && (_incoming.isNotEmpty || _outgoing.isNotEmpty))
          const LinearProgressIndicator(),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _list(_incoming, incoming: true),
              _list(_outgoing, incoming: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final BorrowStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, IconData icon) = switch (status) {
      BorrowStatus.pending => (
          Colors.amber.shade100,
          Colors.brown.shade800,
          Icons.hourglass_top_rounded
        ),
      BorrowStatus.approved => (
          Colors.green.shade100,
          Colors.green.shade900,
          Icons.check_circle_outline_rounded
        ),
      BorrowStatus.rejected => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.block_rounded
        ),
      BorrowStatus.returned => (
          Colors.blue.shade100,
          Colors.blue.shade900,
          Icons.assignment_return_outlined
        ),
      BorrowStatus.cancelled => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          Icons.cancel_outlined
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: CloudUi.small, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: CloudUi.tight),
          Text(
            status.label,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
