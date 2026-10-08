import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class CloudUi {
  static const tight = 4.0;
  static const small = 8.0;
  static const medium = 12.0;
  static const standard = 16.0;
  static const section = 24.0;
  static const controlHeight = 48.0;
  static const compactBreakpoint = 600.0;
  static const contentWidth = 960.0;
  static const formWidth = 640.0;
}

String cloudErrorMessage(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' || 'unauthorized' =>
        'Bạn không có quyền thực hiện thao tác này. Kiểm tra tài khoản và Firebase Rules.',
      'unauthenticated' || 'user-token-expired' || 'requires-recent-login' =>
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng xuất rồi đăng nhập lại.',
      'unavailable' || 'network-request-failed' || 'retry-limit-exceeded' =>
        'Không kết nối được Firebase. Kiểm tra mạng hoặc Emulator rồi thử lại.',
      'popup-closed-by-user' || 'cancelled-popup-request' =>
        'Đăng nhập đã bị hủy. Bạn có thể thử lại khi sẵn sàng.',
      'popup-blocked' =>
        'Trình duyệt chặn cửa sổ Google. Cho phép cửa sổ bật lên rồi thử lại.',
      'object-not-found' =>
        'Tệp không còn trong kho. Làm mới danh sách rồi thử lại.',
      _ =>
        'Firebase báo lỗi (${error.code}). ${error.message ?? 'Kiểm tra cấu hình trong HUONG_DAN_FIREBASE_VA_DEMO.md rồi thử lại.'}',
    };
  }
  if (error is ArgumentError) return '${error.message}';
  if (error is StateError) return error.message;
  return 'Không thể hoàn tất thao tác. Vui lòng thử lại. Chi tiết: $error';
}

class CloudScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final bool busy;
  final double maxWidth;

  const CloudScaffold({
    super.key,
    this.title = 'Kho Cloud',
    required this.child,
    this.busy = false,
    this.maxWidth = CloudUi.contentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && busy) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng chờ thao tác hoàn tất trước khi rời trang.'),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  tooltip: 'Quay lại',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: busy
                      ? null
                      : () => Navigator.of(context).maybePop(),
                )
              : null,
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: const EdgeInsets.all(CloudUi.standard),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CloudPanel extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget child;
  final Color? color;
  final Color? foreground;

  const CloudPanel({
    super.key,
    this.title,
    this.icon,
    required this.child,
    this.color,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(CloudUi.standard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: foreground),
                    const SizedBox(width: CloudUi.small),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CloudUi.medium),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class CloudMessage extends StatelessWidget {
  final String title;
  final String message;
  final bool isError;
  final bool isWarning;
  final Widget? action;

  const CloudMessage({
    super.key,
    required this.title,
    required this.message,
    this.isError = false,
    this.isWarning = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = isError
        ? colors.onErrorContainer
        : isWarning
        ? colors.onTertiaryContainer
        : colors.onSurface;
    return Semantics(
      liveRegion: isError,
      child: CloudPanel(
        title: title,
        icon: isError
            ? Icons.error_outline_rounded
            : isWarning
            ? Icons.science_outlined
            : Icons.info_outline_rounded,
        color: isError
            ? colors.errorContainer
            : isWarning
            ? colors.tertiaryContainer
            : null,
        foreground: foreground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
            if (action != null) ...[
              const SizedBox(height: CloudUi.medium),
              Align(alignment: Alignment.centerLeft, child: action!),
            ],
          ],
        ),
      ),
    );
  }
}
