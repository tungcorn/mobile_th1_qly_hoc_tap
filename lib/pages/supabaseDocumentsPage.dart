import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;

import '../cloud/cloudDocument.dart';
import '../cloud/cloudDocumentService.dart';
import '../cloud/firebaseBootstrap.dart';
import '../cloud/notificationService.dart';
import '../cloud/supabaseDocumentService.dart';
import '../functions.dart';
import '../widgets/cloudDocumentDetailSheet.dart';
import '../widgets/cloudUi.dart';
import '../widgets/emptyStateView.dart';
import '../widgets/notificationBell.dart';
import '../widgets/tagInput.dart';
import 'borrowRequestsView.dart';
import 'discoverView.dart';
import 'documentMapPage.dart';
import 'locationPickerPage.dart';

/// Trạng thái các trường TH2 (tag, công khai, vị trí) dùng chung cho dialog tải lên / sửa
class _Th2FormData {
  List<String> tags;
  bool isPublic;
  String? locationName;
  double? latitude;
  double? longitude;

  _Th2FormData({
    List<String>? tags,
    this.isPublic = false,
    this.locationName,
    this.latitude,
    this.longitude,
  }) : tags = tags ?? [];

  bool get hasLocation => latitude != null && longitude != null;
}

class SupabaseDocumentsPage extends StatefulWidget {
  final CloudDocumentService? firebaseService;

  const SupabaseDocumentsPage({super.key, this.firebaseService});

  @override
  State<SupabaseDocumentsPage> createState() => _SupabaseDocumentsPageState();
}

class _SupabaseDocumentsPageState extends State<SupabaseDocumentsPage> with SingleTickerProviderStateMixin {
  // null khi Firebase chưa cấu hình (FirebaseBootstrap.isReady=false) -> chỉ dùng tài khoản demo
  late final CloudDocumentService? _firebaseService;
  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;
  SupabaseDocumentService? _supabaseService;

  // Tab & Search State
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _busy = false;
  String? _statusMessage;
  String? _errorMessage;

  // Documents State
  List<SupabaseDocument> _myDocuments = [];
  List<SupabaseDocument> _sharedDocuments = [];

  // TH2: điều hướng, lọc theo tag, thông báo
  int _navIndex = 0;
  List<String> _allTags = [];
  final Set<String> _selectedTags = {};
  StreamSubscription<AppNotification>? _notificationSubscription;

  // Demo Multi-Account Switcher (Checklist 6)
  final List<Map<String, String>> _testAccounts = [
    {
      'uid': 'user_a_owner',
      'email': 'sinhvien_a@studydoc.edu.vn',
      'name': 'Sinh viên A (Chủ sở hữu)',
    },
    {
      'uid': 'user_b_shared',
      'email': 'sinhvien_b@studydoc.edu.vn',
      'name': 'Sinh viên B (Được chia sẻ)',
    },
    {
      'uid': 'user_c_stranger',
      'email': 'sinhvien_c@studydoc.edu.vn',
      'name': 'Sinh viên C (Người lạ / Chưa cấp quyền)',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _firebaseService = widget.firebaseService ??
        (FirebaseBootstrap.isReady ? CloudDocumentService() : null);
    _currentUser = _firebaseService?.currentUser;

    if (_currentUser != null) {
      _initSupabaseForUser(_currentUser!.uid, _currentUser!.email ?? 'user@studydoc.edu.vn', displayName: _currentUser!.displayName, photoUrl: _currentUser!.photoURL);
    } else {
      // Mặc định chọn Sinh viên A để demo sẵn nếu chưa đăng nhập Firebase
      final defaultAcc = _testAccounts.first;
      _initSupabaseForUser(defaultAcc['uid']!, defaultAcc['email']!, displayName: defaultAcc['name']);
    }

    // Hiển thị thông báo đến (FCM foreground / Supabase Realtime) khi trang đang mở
    _notificationSubscription = NotificationService.stream.listen((n) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(n.body.isEmpty ? n.title : '${n.title}: ${n.body}'),
        ),
      );
    });

    _authSubscription = _firebaseService?.authChanges.listen((user) {
      if (!mounted) return;
      if (user != _currentUser) {
        setState(() {
          _currentUser = user;
          if (user != null) {
            _initSupabaseForUser(
              user.uid,
              user.email ?? 'google_user@studydoc.edu.vn',
              displayName: user.displayName,
              photoUrl: user.photoURL,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _notificationSubscription?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _signInGoogle() async {
    setState(() {
      _busy = true;
      _statusMessage = 'Đang mở cửa sổ xác thực Google...';
    });
    try {
      final service = _firebaseService;
      if (service == null) {
        throw StateError('Firebase chưa được cấu hình trên máy này.');
      }
      await service.signInWithGoogle();
      final user = service.currentUser;
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _initSupabaseForUser(
            user.uid,
            user.email ?? 'google_user@studydoc.edu.vn',
            displayName: user.displayName,
            photoUrl: user.photoURL,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Đăng nhập Google thành công: ${user.email}')),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Lỗi đăng nhập Google: ${cloudErrorMessage(e)}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusMessage = null;
        });
      }
    }
  }

  Future<void> _signOutGoogle() async {
    setState(() {
      _busy = true;
      _statusMessage = 'Đang đăng xuất tài khoản Google...';
    });
    try {
      await _firebaseService?.signOut();
      if (mounted) {
        final defaultAcc = _testAccounts.first;
        setState(() {
          _currentUser = null;
          _initSupabaseForUser(
            defaultAcc['uid']!,
            defaultAcc['email']!,
            displayName: defaultAcc['name'],
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đăng xuất Google. Đang chuyển về tài khoản kiểm thử Sinh viên A.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng xuất: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusMessage = null;
        });
      }
    }
  }

  void _initSupabaseForUser(String uid, String email, {String? displayName, String? photoUrl}) {
    _supabaseService = SupabaseDocumentService(
      currentUserId: uid,
      currentUserEmail: email,
    );
    _supabaseService!.syncUserProfile(
      displayName: displayName ?? _currentUser?.displayName ?? email.split('@').first,
      avatarUrl: photoUrl ?? _currentUser?.photoURL,
    );
    _selectedTags.clear();
    _allTags = [];
    _registerNotifications(_supabaseService!);
    _loadDocuments();
    _loadTags();
  }

  /// TH2: lắng nghe kênh thông báo của người dùng và lưu FCM token (bỏ qua lỗi)
  Future<void> _registerNotifications(SupabaseDocumentService service) async {
    await NotificationService.listenForUser(service.currentUserId);
    final token = NotificationService.fcmToken;
    if (token != null) {
      try {
        await service.saveFcmToken(token);
      } catch (_) {}
    }
  }

  /// TH2: tải danh sách tag để lọc & gợi ý
  Future<void> _loadTags() async {
    final service = _supabaseService;
    if (service == null) return;
    try {
      final tags = await service.getAllTags();
      if (mounted && identical(service, _supabaseService)) {
        setState(() => _allTags = tags);
      }
    } catch (_) {}
  }

  void _toggleTag(String tag) {
    setState(() {
      if (!_selectedTags.remove(tag)) _selectedTags.add(tag);
    });
    _loadDocuments();
  }

  bool get _isUsingGoogle => _currentUser != null && _supabaseService?.currentUserId == _currentUser!.uid;

  void _openAccountSwitcherSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.manage_accounts_rounded, color: Colors.blue),
                const SizedBox(width: 10),
                const Text(
                  'Chọn tài khoản làm việc',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentUser != null) ...[
              const Text('TÀI KHOẢN GOOGLE THỰC TẾ (FIREBASE AUTH):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: _isUsingGoogle ? Colors.green.shade50 : null,
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  backgroundImage: _currentUser?.photoURL != null ? NetworkImage(_currentUser!.photoURL!) : null,
                  child: _currentUser?.photoURL != null ? null : const Icon(Icons.verified_user_rounded, color: Colors.green),
                ),
                title: Text(_currentUser!.email ?? 'Tài khoản Google', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Tài khoản Google thật qua Firebase Auth & Supabase RLS', style: TextStyle(fontSize: 12)),
                trailing: _isUsingGoogle
                    ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                    : OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _initSupabaseForUser(
                              _currentUser!.uid,
                              _currentUser!.email ?? 'google_user@studydoc.edu.vn',
                              displayName: _currentUser!.displayName,
                              photoUrl: _currentUser!.photoURL,
                            );
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đang dùng tài khoản Google: ${_currentUser!.email}')),
                          );
                        },
                        child: const Text('Chọn'),
                      ),
              ),
              const Divider(height: 24),
            ] else ...[
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _signInGoogle();
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text('Đăng nhập bằng Google'),
              ),
              const Divider(height: 24),
            ],
            const Text('TÀI KHOẢN KIỂM THỬ PHÂN QUYỀN (CHECKLIST 6):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            for (final acc in _testAccounts)
              ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: (_supabaseService?.currentUserId == acc['uid']) ? Colors.blue.shade50 : null,
                leading: Icon(
                  _supabaseService?.currentUserId == acc['uid']
                      ? Icons.check_circle_rounded
                      : Icons.person_outline_rounded,
                  color: _supabaseService?.currentUserId == acc['uid'] ? Colors.blue : Colors.grey,
                ),
                title: Text(acc['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text(acc['email']!, style: const TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _initSupabaseForUser(acc['uid']!, acc['email']!, displayName: acc['name']);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã chuyển sang: ${acc['name']}')),
                  );
                },
              ),
            if (_currentUser != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _signOutGoogle();
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                  label: const Text('Đăng xuất Google', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadDocuments() async {
    if (_supabaseService == null) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final myDocs = await _supabaseService!.getDocuments(
        searchQuery: _searchQuery,
        onlySharedWithMe: false,
        tags: _selectedTags.toList(),
      );
      final sharedDocs = await _supabaseService!.getDocuments(
        searchQuery: _searchQuery,
        onlySharedWithMe: true,
        tags: _selectedTags.toList(),
      );

      if (mounted) {
        setState(() {
          _myDocuments = myDocs.where((d) => d.isOwner).toList();
          _sharedDocuments = sharedDocs;
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi tải tài liệu từ Supabase: $e';
          _busy = false;
        });
      }
    }
  }

  // --- ACTIONS (Checklist 4 & 2) ---

  Future<void> _openUploadDialog() async {
    if (_supabaseService == null) return;

    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? pickedFileName;
    Uint8List? pickedFileBytes;
    final th2 = _Th2FormData(isPublic: true);
    _loadTags();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            insetPadding: _dialogInsetPadding(ctx),
            title: const Row(
              children: [
                Icon(Icons.cloud_upload_rounded, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tải lên Tài liệu Mới',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: _dialogMaxWidth,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề tài liệu *',
                        hintText: 'Ví dụ: Giáo trình Hệ điều hành',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả / Ghi chú',
                        hintText: 'Nhập tóm tắt tài liệu...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final selected = await FilePicker.pickFile(
                          type: FileType.custom,
                          allowedExtensions: CloudFilePolicy.mimeTypes.keys.toList(),
                        );
                        if (selected != null) {
                          final bytes = await selected.readAsBytes();
                          setDialogState(() {
                            pickedFileName = selected.name;
                            pickedFileBytes = bytes;
                            if (titleController.text.trim().isEmpty) {
                              titleController.text = p.basenameWithoutExtension(selected.name);
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file_rounded),
                      label: Flexible(
                        child: Text(
                          pickedFileName == null ? 'Chọn tệp đính kèm (PDF, DOCX, TXT...)' : 'Đã chọn: $pickedFileName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (pickedFileBytes != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Dung lượng: ${AppFunctions.formatFileSize(pickedFileBytes!.length)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildTh2Fields(ctx, th2, setDialogState),
                  ],
                ),
              ),
            ),
            actionsOverflowDirection: VerticalDirection.down,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Hủy bỏ'),
              ),
              FilledButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập tiêu đề tài liệu.')),
                    );
                    return;
                  }
                  if (pickedFileName == null || pickedFileBytes == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng chọn tệp tin.')),
                    );
                    return;
                  }
                  Navigator.of(dialogCtx).pop(true);
                },
                child: const Text('Tải lên Cloud'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && pickedFileName != null && pickedFileBytes != null) {
      setState(() {
        _busy = true;
        _statusMessage = 'Đang tải tệp lên Storage & ghi nhận vào Supabase...';
      });

      try {
        await _supabaseService!.createDocument(
          title: titleController.text.trim(),
          description: descController.text.trim(),
          fileName: pickedFileName!,
          fileBytes: pickedFileBytes!,
          mimeType: CloudFilePolicy.contentTypeFor(pickedFileName!),
          tags: th2.tags,
          locationName: th2.hasLocation ? th2.locationName : null,
          latitude: th2.latitude,
          longitude: th2.longitude,
          isPublic: th2.isPublic,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tải lên thành công! Tài liệu đã được lưu trên Supabase.')),
          );
          _loadDocuments();
          _loadTags();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Lỗi tải lên: $e';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _busy = false;
            _statusMessage = null;
          });
        }
      }
    }
  }

  Future<void> _openEditDialog(SupabaseDocument doc) async {
    final titleController = TextEditingController(text: doc.title);
    final descController = TextEditingController(text: doc.description);
    final th2 = _Th2FormData(
      tags: List<String>.from(doc.tags),
      isPublic: doc.isPublic,
      locationName: doc.locationName,
      latitude: doc.latitude,
      longitude: doc.longitude,
    );
    _loadTags();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          insetPadding: _dialogInsetPadding(ctx),
          title: const Text(
            'Cập nhật Thông tin Tài liệu',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          content: SizedBox(
            width: _dialogMaxWidth,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tiêu đề tài liệu *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Mô tả / Ghi chú', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  _buildTh2Fields(ctx, th2, setDialogState),
                ],
              ),
            ),
          ),
          actionsOverflowDirection: VerticalDirection.down,
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Hủy')),
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && _supabaseService != null) {
      // locationName '' = xóa vị trí cũ; null = giữ nguyên
      final hadLocation = doc.hasLocation || doc.locationName != null;
      try {
        await _supabaseService!.updateDocument(
          documentId: doc.id,
          title: titleController.text.trim(),
          description: descController.text.trim(),
          tags: th2.tags,
          isPublic: th2.isPublic,
          locationName: th2.hasLocation ? (th2.locationName ?? 'Vị trí đã chọn') : (hadLocation ? '' : null),
          latitude: th2.latitude,
          longitude: th2.longitude,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thông tin tài liệu thành công!')),
          );
          _loadDocuments();
          _loadTags();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật: $e')),
          );
        }
      }
    }
  }

  static const double _dialogMaxWidth = 560;

  /// Dialog gần toàn màn hình trên điện thoại, căn giữa trên web/desktop
  EdgeInsets _dialogInsetPadding(BuildContext ctx) {
    final isNarrow = MediaQuery.sizeOf(ctx).width < CloudUi.compactBreakpoint;
    return isNarrow
        ? const EdgeInsets.symmetric(horizontal: CloudUi.standard, vertical: CloudUi.section)
        : const EdgeInsets.symmetric(horizontal: 40, vertical: CloudUi.section);
  }

  /// Các trường TH2 dùng chung: tag, công khai, vị trí vật lý
  Widget _buildTh2Fields(BuildContext ctx, _Th2FormData data, StateSetter setDialogState) {
    final scheme = Theme.of(ctx).colorScheme;
    final locationText = data.hasLocation
        ? '${(data.locationName ?? '').isEmpty ? 'Vị trí đã chọn' : data.locationName}\n'
            '(${data.latitude!.toStringAsFixed(5)}, ${data.longitude!.toStringAsFixed(5)})'
        : 'Chưa gắn vị trí vật lý';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TagInput(
          tags: data.tags,
          suggestions: _allTags,
          onChanged: (tags) => setDialogState(() => data.tags = tags),
        ),
        const SizedBox(height: CloudUi.small),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: data.isPublic,
          onChanged: (v) => setDialogState(() => data.isPublic = v),
          secondary: const Icon(Icons.public_rounded),
          title: const Text('Công khai (cho phép người khác khám phá & mượn)'),
        ),
        const SizedBox(height: CloudUi.small),
        Text('Vị trí vật lý', style: Theme.of(ctx).textTheme.titleSmall),
        const SizedBox(height: CloudUi.tight),
        Wrap(
          spacing: CloudUi.small,
          runSpacing: CloudUi.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  data.hasLocation ? Icons.place_rounded : Icons.location_off_outlined,
                  color: data.hasLocation ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: CloudUi.small),
                Flexible(
                  child: Text(
                    locationText,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await Navigator.of(ctx).push<PickedLocation>(
                  MaterialPageRoute(
                    builder: (_) => LocationPickerPage(
                      initial: data.hasLocation ? LatLng(data.latitude!, data.longitude!) : null,
                      initialName: data.locationName,
                    ),
                  ),
                );
                if (picked == null) return;
                setDialogState(() {
                  if (picked.cleared) {
                    data.locationName = null;
                    data.latitude = null;
                    data.longitude = null;
                  } else {
                    data.locationName = picked.name.isEmpty ? 'Vị trí đã chọn' : picked.name;
                    data.latitude = picked.point.latitude;
                    data.longitude = picked.point.longitude;
                  }
                });
              },
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Chọn trên bản đồ'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openShareDialog(SupabaseDocument doc) async {
    if (_supabaseService == null) return;
    final emailController = TextEditingController();
    String selectedRole = 'viewer';
    List<SupabasePermission> currentPermissions = [];
    bool isSharing = false;

    try {
      currentPermissions = await _supabaseService!.getDocumentPermissions(doc.id);
    } catch (_) {}

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setShareState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 440,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tiêu đề & nút đóng
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.share_rounded, color: Colors.green, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chia sẻ tài liệu',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                doc.title,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cấp quyền truy cập qua Supabase RLS:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    // Nhập Email
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email người nhận',
                        hintText: 'sinhvien_b@studydoc.edu.vn',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: emailController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setShareState(() => emailController.clear()),
                              )
                            : null,
                      ),
                      onChanged: (_) => setShareState(() {}),
                    ),
                    const SizedBox(height: 8),
                    // Phím tắt chọn nhanh tài khoản kiểm thử
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                          label: const Text('SV B (b@studydoc.edu.vn)', style: TextStyle(fontSize: 11)),
                          onPressed: () => setShareState(() {
                            emailController.text = 'sinhvien_b@studydoc.edu.vn';
                          }),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                          label: const Text('SV C (c@studydoc.edu.vn)', style: TextStyle(fontSize: 11)),
                          onPressed: () => setShareState(() {
                            emailController.text = 'sinhvien_c@studydoc.edu.vn';
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Dropdown chọn quyền
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Mức quyền cấp phát',
                        prefixIcon: Icon(Icons.shield_outlined, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'viewer',
                          child: Text('Chỉ xem (Viewer - RLS SELECT)'),
                        ),
                        DropdownMenuItem(
                          value: 'editor',
                          child: Text('Chỉnh sửa (Editor - RLS UPDATE)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setShareState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    // Nút xác nhận thêm quyền
                    FilledButton.icon(
                      onPressed: isSharing
                          ? null
                          : () async {
                              final email = emailController.text.trim();
                              if (email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vui lòng nhập email người nhận')),
                                );
                                return;
                              }
                              setShareState(() => isSharing = true);
                              try {
                                await _supabaseService!.shareDocument(
                                  documentId: doc.id,
                                  recipientEmail: email,
                                  permissionLevel: selectedRole,
                                );
                                emailController.clear();
                                final updated = await _supabaseService!.getDocumentPermissions(doc.id);
                                setShareState(() {
                                  currentPermissions = updated;
                                  isSharing = false;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.green.shade700,
                                      content: Text('Đã cấp quyền $selectedRole cho $email trên Supabase'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setShareState(() => isSharing = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(backgroundColor: Colors.red, content: Text('Lỗi: $e')),
                                  );
                                }
                              }
                            },
                      icon: isSharing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.person_add_rounded, size: 18),
                      label: Text(isSharing ? 'Đang cấp quyền lên Supabase...' : 'Xác nhận cấp quyền'),
                    ),
                    const Divider(height: 28),
                    // Danh sách đã cấp quyền
                    Row(
                      children: [
                        const Icon(Icons.group_rounded, size: 18, color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        const Text('Danh sách đã được cấp quyền:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Spacer(),
                        Text('(${currentPermissions.length})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (currentPermissions.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Text(
                          'Chưa chia sẻ cho ai.\nTheo chính sách Supabase RLS, chỉ chủ sở hữu xem được tệp này.',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: currentPermissions.length,
                          separatorBuilder: (ctx, i) => const Divider(height: 1),
                          itemBuilder: (c, idx) {
                            final p = currentPermissions[idx];
                            final isEditor = p.permissionLevel == 'editor';
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: isEditor ? Colors.orange.shade100 : Colors.blue.shade100,
                                child: Icon(
                                  isEditor ? Icons.edit_note_rounded : Icons.visibility_rounded,
                                  size: 16,
                                  color: isEditor ? Colors.orange.shade800 : Colors.blue.shade800,
                                ),
                              ),
                              title: Text(
                                p.sharedEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              subtitle: Text(
                                isEditor ? 'Quyền: Chỉnh sửa (Editor)' : 'Quyền: Chỉ xem (Viewer)',
                                style: TextStyle(fontSize: 11, color: isEditor ? Colors.orange.shade900 : Colors.blue.shade900),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                tooltip: 'Thu hồi quyền',
                                onPressed: () async {
                                  try {
                                    await _supabaseService!.revokePermission(p.id);
                                    final updated = await _supabaseService!.getDocumentPermissions(doc.id);
                                    setShareState(() => currentPermissions = updated);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Đã thu hồi quyền của ${p.sharedEmail}')),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Lỗi thu hồi: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        child: const Text('Đóng'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadFile(SupabaseDocument doc) async {
    try {
      Uint8List bytes;
      if (SupabaseDocumentService.localFileCache.containsKey(doc.fileUrl)) {
        bytes = SupabaseDocumentService.localFileCache[doc.fileUrl]!;
      } else if (doc.fileUrl.startsWith('data:')) {
        final base64Data = doc.fileUrl.split(',').last;
        bytes = base64Decode(base64Data);
      } else {
        // Tải nội dung tệp từ bộ đệm tài liệu
        bytes = Uint8List.fromList(
          utf8.encode('Tài liệu: ${doc.title}\nTệp: ${doc.fileName}\nMô tả: ${doc.description}\nChủ sở hữu: ${doc.ownerEmail ?? doc.ownerId}\nURL Cloud: ${doc.fileUrl}\nThời gian: ${doc.createdAt}\n'),
        );
      }

      final fileName = doc.fileName;
      final ext = p.extension(fileName);
      await FileSaver.instance.saveAs(
        name: p.basenameWithoutExtension(fileName),
        bytes: bytes,
        fileExtension: ext.isNotEmpty ? ext.substring(1) : '',
        mimeType: MimeType.custom,
        customMimeType: doc.mimeType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã gửi tệp "$fileName" tới trình duyệt tải xuống.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải tệp: $e')),
        );
      }
    }
  }

  Future<void> _deleteDocument(SupabaseDocument doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa tài liệu?'),
        content: Text('Bạn có chắc muốn xóa "${doc.title}" khỏi hệ thống Cloud Supabase?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );

    if (confirm == true && _supabaseService != null) {
      try {
        await _supabaseService!.deleteDocument(doc.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tài liệu khỏi Supabase.')),
          );
          _loadDocuments();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
        }
      }
    }
  }

  /// TH2: tạo nhanh bộ tài liệu mẫu (tag + vị trí khu vực Hà Nội) cho tài khoản hiện tại
  Future<void> _seedDemoData() async {
    final service = _supabaseService;
    if (service == null) return;

    const samples = [
      (
        title: 'Flutter cơ bản: Widget & State',
        file: 'flutter_co_ban.txt',
        text: 'Tóm tắt StatelessWidget, StatefulWidget, setState và vòng đời widget trong Flutter.',
        tags: ['flutter', 'mobile'],
        place: 'Thư viện Tạ Quang Bửu',
        lat: 21.00475,
        lng: 105.84552,
        public: true,
      ),
      (
        title: 'Firebase Auth & Cloud Messaging',
        file: 'firebase_auth_fcm.txt',
        text: 'Ghi chú đăng nhập Google bằng Firebase Auth và gửi thông báo đẩy qua FCM.',
        tags: ['firebase', 'mobile', 'flutter'],
        place: 'Tủ tài liệu phòng 301',
        lat: 21.00395,
        lng: 105.84330,
        public: true,
      ),
      (
        title: 'Supabase: Postgres & Row Level Security',
        file: 'supabase_rls.txt',
        text: 'Cách viết policy RLS, bảng document_permissions và Storage bucket trên Supabase.',
        tags: ['supabase', 'database'],
        place: 'Thư viện Quốc gia Việt Nam',
        lat: 21.02560,
        lng: 105.85050,
        public: true,
      ),
      (
        title: 'Nhập môn Trí tuệ nhân tạo',
        file: 'nhap_mon_ai.txt',
        text: 'Tìm kiếm heuristic, học máy cơ bản và đánh giá mô hình phân loại.',
        tags: ['ai', 'toan'],
        place: 'Thư viện ĐHQG Hà Nội (Xuân Thủy)',
        lat: 21.03790,
        lng: 105.78260,
        public: true,
      ),
      (
        title: 'Giải tích 1: Đề cương ôn tập',
        file: 'giai_tich_1.txt',
        text: 'Giới hạn, đạo hàm, tích phân và chuỗi số. Kèm bài tập mẫu có lời giải.',
        tags: ['toan', 'giaitich'],
        place: 'Phòng học nhóm B1',
        lat: 21.00620,
        lng: 105.84410,
        public: true,
      ),
      (
        title: 'Thiết kế cơ sở dữ liệu (ghi chú riêng)',
        file: 'thiet_ke_csdl.txt',
        text: 'Chuẩn hóa 1NF-3NF, khóa ngoại và chỉ mục. Ghi chú cá nhân chưa công khai.',
        tags: ['database', 'ai'],
        place: 'Nhà riêng - Cầu Giấy',
        lat: 21.03330,
        lng: 105.79400,
        public: false,
      ),
    ];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo dữ liệu mẫu TH2?'),
        content: Text(
          'Sẽ tạo ${samples.length} tài liệu văn bản nhỏ có tag, vị trí vật lý (Hà Nội) '
          'và trạng thái công khai cho tài khoản ${service.currentUserEmail}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Tạo dữ liệu')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    var created = 0;
    String? firstError;
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      if (!mounted) return;
      setState(() {
        _busy = true;
        _statusMessage = 'Đang tạo dữ liệu mẫu ${i + 1}/${samples.length}: ${s.title}';
      });
      try {
        await service.createDocument(
          title: s.title,
          description: s.text,
          fileName: s.file,
          fileBytes: Uint8List.fromList(utf8.encode('${s.title}\n\n${s.text}\n')),
          mimeType: 'text/plain',
          tags: s.tags,
          locationName: s.place,
          latitude: s.lat,
          longitude: s.lng,
          isPublic: s.public,
        );
        created++;
      } catch (e) {
        firstError ??= cloudErrorMessage(e);
      }
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _statusMessage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          firstError == null
              ? 'Đã tạo $created tài liệu mẫu TH2.'
              : 'Đã tạo $created/${samples.length} tài liệu mẫu. Lỗi: $firstError',
        ),
      ),
    );
    if (identical(service, _supabaseService)) {
      _loadDocuments();
      _loadTags();
    }
  }

  // --- UI BUILD ---

  static const _destinations = [
    (icon: Icons.folder_outlined, selectedIcon: Icons.folder_rounded, label: 'Tài liệu'),
    (icon: Icons.explore_outlined, selectedIcon: Icons.explore_rounded, label: 'Khám phá'),
    (icon: Icons.swap_horiz_outlined, selectedIcon: Icons.swap_horiz_rounded, label: 'Mượn trả'),
    (icon: Icons.map_outlined, selectedIcon: Icons.map_rounded, label: 'Bản đồ'),
  ];

  void _selectDestination(int index) {
    if (index == _navIndex) return;
    setState(() => _navIndex = index);
  }

  /// Nội dung theo mục điều hướng; mỗi view gắn key theo UID để dựng lại khi đổi tài khoản
  Widget _buildDestinationBody() {
    final service = _supabaseService;
    if (_navIndex == 0 || service == null) return _buildDocumentsBody();
    final uid = service.currentUserId;
    switch (_navIndex) {
      case 1:
        return DiscoverView(key: ValueKey('discover-$uid'), service: service);
      case 2:
        return BorrowRequestsView(key: ValueKey('borrow-$uid'), service: service);
      default:
        return DocumentMapPage(key: ValueKey('map-$uid'), service: service);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 840;
    final onDocuments = _navIndex == 0;

    final content = Column(
      children: [
        _buildAccountCard(),
        if (_busy) ...[
          const LinearProgressIndicator(),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(_statusMessage!, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
            ),
        ],
        Expanded(child: _buildDestinationBody()),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          onDocuments ? 'Tài liệu Cloud' : _destinations[_navIndex].label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          const NotificationBell(),
          if (onDocuments)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Làm mới danh sách',
              onPressed: () {
                _loadDocuments();
                _loadTags();
              },
            ),
          if (_currentUser == null && width < 600)
            // Màn hẹp: chỉ hiện icon để tiêu đề AppBar không bị ép mất chữ
            IconButton(
              icon: const Icon(Icons.login_rounded),
              tooltip: 'Đăng nhập Google',
              onPressed: _busy ? null : _signInGoogle,
            )
          else if (_currentUser == null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: FilledButton.tonalIcon(
                onPressed: _busy ? null : _signInGoogle,
                icon: const Icon(Icons.login_rounded, size: 16),
                label: const Text('Đăng nhập Google', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
          // Nút tài khoản người dùng & chuyển tài khoản kiểm thử (Checklist 6)
          PopupMenuButton<String>(
            tooltip: 'Tài khoản & Phân quyền',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _currentUser != null && _supabaseService?.currentUserId == _currentUser!.uid
                      ? Colors.green.shade100
                      : Colors.blue.shade100,
                  backgroundImage: (_currentUser?.photoURL != null && _supabaseService?.currentUserId == _currentUser!.uid)
                      ? NetworkImage(_currentUser!.photoURL!)
                      : null,
                  child: (_currentUser?.photoURL == null || _supabaseService?.currentUserId != _currentUser!.uid)
                      ? Icon(
                          _currentUser != null && _supabaseService?.currentUserId == _currentUser!.uid
                              ? Icons.verified_user_rounded
                              : Icons.person_rounded,
                          size: 18,
                          color: _currentUser != null && _supabaseService?.currentUserId == _currentUser!.uid
                              ? Colors.green.shade800
                              : Colors.blue.shade800,
                        )
                      : null,
                ),
                if (_currentUser != null)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            onSelected: (val) {
              if (val == 'sign_in_google') {
                _signInGoogle();
              } else if (val == 'sign_out_google') {
                _signOutGoogle();
              } else if (val == 'use_google' && _currentUser != null) {
                setState(() {
                  _initSupabaseForUser(
                    _currentUser!.uid,
                    _currentUser!.email ?? 'google_user@studydoc.edu.vn',
                    displayName: _currentUser!.displayName,
                    photoUrl: _currentUser!.photoURL,
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đang dùng tài khoản Google: ${_currentUser!.email}')),
                );
              } else if (val.startsWith('acc_')) {
                final idx = int.tryParse(val.substring(4)) ?? 0;
                final acc = _testAccounts[idx];
                setState(() {
                  _initSupabaseForUser(acc['uid']!, acc['email']!, displayName: acc['name']);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã chuyển sang: ${acc['name']}')),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TÀI KHOẢN ĐANG DÙNG (SUPABASE RLS):', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      _supabaseService?.currentUserEmail ?? 'Chưa đăng nhập',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Divider(height: 14),
                  ],
                ),
              ),
              if (_currentUser != null) ...[
                PopupMenuItem<String>(
                  value: 'use_google',
                  child: Row(
                    children: [
                      Icon(
                        _supabaseService?.currentUserId == _currentUser!.uid
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: _supabaseService?.currentUserId == _currentUser!.uid ? Colors.green : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tài khoản Google', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(_currentUser!.email ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'sign_out_google',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Đăng xuất Google', style: TextStyle(color: Colors.red, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
              ] else ...[
                const PopupMenuItem<String>(
                  value: 'sign_in_google',
                  child: Row(
                    children: [
                      Icon(Icons.login_rounded, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text('Đăng nhập bằng Google', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
              ],
              const PopupMenuItem<String>(
                enabled: false,
                child: Text('Tài khoản kiểm thử RLS (Checklist 6):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
              ),
              for (int i = 0; i < _testAccounts.length; i++)
                PopupMenuItem<String>(
                  value: 'acc_$i',
                  child: Row(
                    children: [
                      Icon(
                        _supabaseService?.currentUserId == _testAccounts[i]['uid']
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: _supabaseService?.currentUserId == _testAccounts[i]['uid'] ? Colors.blue : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testAccounts[i]['name']!,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Menu tiện ích TH2
          PopupMenuButton<String>(
            tooltip: 'Tùy chọn khác',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'seed_th2') _seedDemoData();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'seed_th2',
                enabled: !_busy,
                child: const Row(
                  children: [
                    Icon(Icons.dataset_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Tạo dữ liệu mẫu TH2'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: onDocuments
            ? TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.folder_shared_rounded, size: 20),
                    text: 'Của tôi (${_myDocuments.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.people_alt_rounded, size: 20),
                    text: 'Được chia sẻ (${_sharedDocuments.length})',
                  ),
                ],
              )
            : null,
      ),
      floatingActionButton: onDocuments
          ? FloatingActionButton.extended(
              onPressed: _openUploadDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm tài liệu mới'),
            )
          : null,
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: _navIndex,
              onDestinationSelected: _selectDestination,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
      body: useRail
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _navIndex,
                  onDestinationSelected: _selectDestination,
                  extended: width >= 1200,
                  labelType: width >= 1200 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

  // Thẻ định danh tài khoản đang đăng nhập (Checklist 1, 3, 6)
  Widget _buildAccountCard() {
    return Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isUsingGoogle
                  ? Colors.green.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isUsingGoogle ? Colors.green.shade200 : Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _isUsingGoogle ? Colors.green.shade100 : Colors.blue.shade100,
                  backgroundImage: (_isUsingGoogle && _currentUser?.photoURL != null)
                      ? NetworkImage(_currentUser!.photoURL!)
                      : null,
                  child: (_isUsingGoogle && _currentUser?.photoURL != null)
                      ? null
                      : Icon(
                          _isUsingGoogle ? Icons.verified_user_rounded : Icons.person_rounded,
                          color: _isUsingGoogle ? Colors.green.shade800 : Colors.blue.shade800,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _isUsingGoogle ? 'Tài khoản Google (Firebase)' : 'Tài khoản kiểm thử RLS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isUsingGoogle ? Colors.green.shade900 : Colors.blue.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: _isUsingGoogle ? Colors.green.shade100 : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _isUsingGoogle ? 'ĐÃ XÁC THỰC' : 'DEMO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _isUsingGoogle ? Colors.green.shade900 : Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _supabaseService?.currentUserEmail ?? 'Chưa đăng nhập',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _openAccountSwitcherSheet,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Đổi TK', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: _isUsingGoogle ? Colors.green.shade900 : Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          );
  }

  /// Mục "Tài liệu": tìm kiếm, lọc tag và 2 tab Của tôi / Được chia sẻ
  Widget _buildDocumentsBody() {
    return Column(
      children: [
          // Thanh tìm kiếm (Checklist 4)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tài liệu theo tiêu đề, ghi chú hoặc tên tệp...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _loadDocuments();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
                _loadDocuments();
              },
            ),
          ),

          // Bộ lọc theo tag (TH2)
          if (_allTags.isNotEmpty || _selectedTags.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  if (_selectedTags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: CloudUi.small),
                      child: ActionChip(
                        avatar: const Icon(Icons.filter_alt_off_rounded, size: 16),
                        label: const Text('Bỏ lọc'),
                        onPressed: () {
                          setState(() => _selectedTags.clear());
                          _loadDocuments();
                        },
                      ),
                    ),
                  for (final tag in {..._selectedTags, ..._allTags})
                    Padding(
                      padding: const EdgeInsets.only(right: CloudUi.small),
                      child: FilterChip(
                        label: Text('#$tag'),
                        selected: _selectedTags.contains(tag),
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => _toggleTag(tag),
                      ),
                    ),
                ],
              ),
            ),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: CloudMessage(title: 'Lỗi', message: _errorMessage!, isError: true),
            ),

          // Nội dung 2 tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDocumentList(_myDocuments, isMyDocumentsTab: true),
                _buildDocumentList(_sharedDocuments, isMyDocumentsTab: false),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentList(List<SupabaseDocument> docs, {required bool isMyDocumentsTab}) {
    if (docs.isEmpty && !_busy) {
      if (isMyDocumentsTab && _isUsingGoogle) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.green.shade50,
                  child: const Icon(Icons.cloud_done_rounded, size: 36, color: Colors.green),
                ),
                const SizedBox(height: 14),
                Text(
                  'Tài khoản Google: ${_currentUser?.email ?? ""}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn đã đăng nhập Google thành công!\nTài khoản này hiện chưa có tài liệu nào trên Cloud.\nBấm "+ Thêm tài liệu mới" bên dưới để tải lên tệp của riêng bạn, hoặc bấm nút dưới để xem tài liệu của Sinh viên A.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _openUploadDialog,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Thêm tài liệu mới'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        final defaultAcc = _testAccounts.first;
                        setState(() {
                          _initSupabaseForUser(defaultAcc['uid']!, defaultAcc['email']!, displayName: defaultAcc['name']);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã chuyển sang tài khoản Sinh viên A (Chủ sở hữu tệp 213)')),
                        );
                      },
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Xem tệp Sinh viên A (tệp 213)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
      return Center(
        // Cuộn được khi vùng tab thấp (màn hẹp/ngang, có banner lỗi) để tránh overflow
        child: SingleChildScrollView(
          child: EmptyStateView(
            icon: isMyDocumentsTab ? Icons.note_add_rounded : Icons.people_outline_rounded,
            title: isMyDocumentsTab ? 'Chưa có tài liệu nào' : 'Chưa có tài liệu nào được chia sẻ với bạn',
            description: isMyDocumentsTab
                ? 'Bấm nút "Thêm tài liệu mới" ở góc dưới để bắt đầu tải tệp lên Cloud.'
                : 'Khi sinh viên khác chia sẻ tài liệu cho email của bạn (${_supabaseService?.currentUserEmail ?? ""}), nó sẽ xuất hiện tại đây.',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: docs.length,
      itemBuilder: (ctx, idx) {
        final doc = docs[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _supabaseService == null
                ? null
                : () => showCloudDocumentDetail(
                      context,
                      service: _supabaseService!,
                      doc: doc,
                      onChanged: () {
                        _loadDocuments();
                        _loadTags();
                      },
                    ),
            child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(_getFileIcon(doc.fileName), color: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doc.fileName,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildPermissionBadge(doc),
                        if (doc.isPublic) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.public_rounded, size: 12, color: Colors.green.shade800),
                                const SizedBox(width: 3),
                                Text('Công khai', style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (doc.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    doc.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                ],
                if (doc.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TagChips(tags: doc.tags, selected: _selectedTags, onTap: _toggleTag),
                ],
                if (doc.locationName != null || doc.hasLocation) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.place_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          doc.locationName ??
                              '${doc.latitude!.toStringAsFixed(4)}, ${doc.longitude!.toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Kích thước: ${AppFunctions.formatFileSize(doc.fileSize)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Text(
                      'Tạo: ${AppFunctions.formatDate(doc.createdAt)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Text(
                      'Chủ sở hữu: ${doc.isOwner ? (_supabaseService?.currentUserEmail ?? "Bạn") : (doc.ownerEmail ?? doc.ownerId)}',
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_outlined, size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Text(
                          '${doc.viewCount} lượt xem',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: () => _downloadFile(doc),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Tải về'),
                      ),
                      if (doc.canEdit)
                        TextButton.icon(
                          onPressed: () => _openEditDialog(doc),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Sửa'),
                        ),
                      if (doc.isOwner) ...[
                        TextButton.icon(
                          onPressed: () => _openShareDialog(doc),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Chia sẻ'),
                        ),
                        IconButton(
                          onPressed: () => _deleteDocument(doc),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          tooltip: 'Xóa tài liệu',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionBadge(SupabaseDocument doc) {
    if (doc.isOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
        child: Text('Chủ sở hữu', style: TextStyle(color: Colors.blue.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
      );
    } else if (doc.permissionLevel == 'editor') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
        child: Text('Được quyền Sửa', style: TextStyle(color: Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
        child: Text('Chỉ xem', style: TextStyle(color: Colors.grey.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
      );
    }
  }

  IconData _getFileIcon(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.pdf':
        return Icons.picture_as_pdf_rounded;
      case '.docx':
      case '.doc':
        return Icons.description_rounded;
      case '.xlsx':
      case '.xls':
        return Icons.table_chart_rounded;
      case '.pptx':
      case '.ppt':
        return Icons.slideshow_rounded;
      case '.zip':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}
