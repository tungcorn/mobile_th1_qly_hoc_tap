import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../cloud/notificationService.dart';
import 'cloudUi.dart';

/// Nút chuông thông báo (badge = số chưa đọc), mở sheet lịch sử + trạng thái FCM.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
          maxWidth: CloudUi.formWidth,
        ),
        child: const _NotificationSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.unread,
      builder: (context, count, _) => IconButton(
        tooltip: count > 0 ? 'Thông báo ($count chưa đọc)' : 'Thông báo',
        onPressed: () => _openSheet(context),
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: Icon(count > 0
              ? Icons.notifications_active_outlined
              : Icons.notifications_none_rounded),
        ),
      ),
    );
  }
}

class _NotificationSheet extends StatelessWidget {
  const _NotificationSheet();

  String _truncate(String s) =>
      s.length <= 24 ? s : '${s.substring(0, 12)}…${s.substring(s.length - 8)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final muted =
        theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    // Rebuild khi có thông báo mới hoặc khi số chưa đọc thay đổi
    return StreamBuilder<AppNotification>(
      stream: NotificationService.stream,
      builder: (context, _) => ValueListenableBuilder<int>(
        valueListenable: NotificationService.unread,
        builder: (context, unread, _) {
          final items = NotificationService.history;
          final token = NotificationService.fcmToken;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    CloudUi.standard, 0, CloudUi.small, CloudUi.small),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Thông báo',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    TextButton.icon(
                      onPressed:
                          unread > 0 ? NotificationService.markAllRead : null,
                      icon: const Icon(Icons.done_all_rounded),
                      label: const Text('Đánh dấu đã đọc'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(CloudUi.standard),
                        child: CloudMessage(
                          title: 'Chưa có thông báo',
                          message:
                              'Thông báo về yêu cầu mượn tài liệu sẽ hiển thị ở đây.',
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final n = items[i];
                          final isUnread = i < unread;
                          return ListTile(
                            leading: Icon(
                              isUnread
                                  ? Icons.mark_email_unread_outlined
                                  : Icons.drafts_outlined,
                              color: isUnread ? scheme.primary : null,
                            ),
                            title: Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (n.body.isNotEmpty) Text(n.body),
                                Text(fmt.format(n.receivedAt), style: muted),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(CloudUi.standard),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trạng thái FCM: ${NotificationService.status}',
                        style: muted),
                    const SizedBox(height: CloudUi.tight),
                    SelectableText(
                      'Token: ${token == null ? 'Chưa có' : _truncate(token)}',
                      style: muted,
                    ),
                    if (NotificationService.lastError != null) ...[
                      const SizedBox(height: CloudUi.tight),
                      Text(
                        'Lỗi gần nhất: ${NotificationService.lastError}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
