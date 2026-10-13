import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../cloud/cloudDocument.dart';
import '../cloud/cloudDocumentService.dart';
import '../cloud/supabaseDocumentService.dart';
import '../functions.dart';
import '../widgets/cloudUi.dart';
import '../widgets/emptyStateView.dart';

class SupabaseDocumentsPage extends StatefulWidget {
  final CloudDocumentService? firebaseService;

  const SupabaseDocumentsPage({super.key, this.firebaseService});

  @override
  State<SupabaseDocumentsPage> createState() => _SupabaseDocumentsPageState();
}

class _SupabaseDocumentsPageState extends State<SupabaseDocumentsPage> with SingleTickerProviderStateMixin {
  late final CloudDocumentService _firebaseService;
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
    _firebaseService = widget.firebaseService ?? CloudDocumentService();
    _currentUser = _firebaseService.currentUser;

    if (_currentUser != null) {
      _initSupabaseForUser(_currentUser!.uid, _currentUser!.email ?? 'user@studydoc.edu.vn', displayName: _currentUser!.displayName, photoUrl: _currentUser!.photoURL);
    } else {
      // Mặc định chọn Sinh viên A để demo sẵn nếu chưa đăng nhập Firebase
      final defaultAcc = _testAccounts.first;
      _initSupabaseForUser(defaultAcc['uid']!, defaultAcc['email']!, displayName: defaultAcc['name']);
    }

    _authSubscription = _firebaseService.authChanges.listen((user) {
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
      await _firebaseService.signInWithGoogle();
      final user = _firebaseService.currentUser;
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
      await _firebaseService.signOut();
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
      );
      final sharedDocs = await _supabaseService!.getDocuments(
        searchQuery: _searchQuery,
        onlySharedWithMe: true,
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

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
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
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
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
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tải lên thành công! Tài liệu đã được lưu trên Supabase.')),
          );
          _loadDocuments();
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

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(
          'Cập nhật Thông tin Tài liệu',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
    );

    if (saved == true && _supabaseService != null) {
      try {
        await _supabaseService!.updateDocument(
          documentId: doc.id,
          title: titleController.text.trim(),
          description: descController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thông tin tài liệu thành công!')),
          );
          _loadDocuments();
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
          utf8.encode('Tài liệu: ${doc.title}\nTệp: ${doc.fileName}\nMô tả: ${doc.description}\nChủ sở hữu: ${doc.ownerId}\nURL Cloud: ${doc.fileUrl}\nThời gian: ${doc.createdAt}\n'),
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

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tài liệu Cloud',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới danh sách',
            onPressed: _loadDocuments,
          ),
          if (_currentUser == null)
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
        ],
        bottom: TabBar(
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
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUploadDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm tài liệu mới'),
      ),
      body: Column(
        children: [

          // Thẻ định danh tài khoản đang đăng nhập (Checklist 1, 3, 6)
          Container(
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
                          Text(
                            _isUsingGoogle ? 'Tài khoản Google (Firebase)' : 'Tài khoản kiểm thử RLS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isUsingGoogle ? Colors.green.shade900 : Colors.blue.shade900,
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
          ),

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

          if (_busy) ...[
            const LinearProgressIndicator(),
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(_statusMessage!, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
              ),
          ],

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
      ),
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
        child: EmptyStateView(
          icon: isMyDocumentsTab ? Icons.note_add_rounded : Icons.people_outline_rounded,
          title: isMyDocumentsTab ? 'Chưa có tài liệu nào' : 'Chưa có tài liệu nào được chia sẻ với bạn',
          description: isMyDocumentsTab
              ? 'Bấm nút "Thêm tài liệu mới" ở góc dưới để bắt đầu tải tệp lên Cloud.'
              : 'Khi sinh viên khác chia sẻ tài liệu cho email của bạn (${_supabaseService?.currentUserEmail ?? ""}), nó sẽ xuất hiện tại đây.',
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
                    _buildPermissionBadge(doc),
                  ],
                ),
                if (doc.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    doc.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
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
                      'Chủ sở hữu: ${doc.isOwner ? (_supabaseService?.currentUserEmail ?? "Bạn") : doc.ownerId}',
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
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
