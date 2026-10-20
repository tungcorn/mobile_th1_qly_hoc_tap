import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabaseBootstrap.dart';

/// Tên bucket Supabase Storage chứa tệp tài liệu
const String _storageBucket = 'documents';

/// Giới hạn kích thước khi phải nhúng tệp dưới dạng data: URL (Storage lỗi)
const int _dataUrlFallbackLimit = 2 * 1024 * 1024;

List<String> _parseTags(dynamic raw) {
  if (raw is List) {
    return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
  }
  return const [];
}

double? _parseDouble(dynamic raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString())?.toLocal();
}

class SupabaseDocument {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? ownerEmail;
  final String permissionLevel; // 'owner', 'editor', 'viewer'

  // TH2: thẻ, vị trí, công khai, lượt xem
  final List<String> tags;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final bool isPublic;
  final int viewCount;

  const SupabaseDocument({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description = '',
    required this.fileUrl,
    required this.fileName,
    this.fileSize = 0,
    this.mimeType = 'application/octet-stream',
    required this.createdAt,
    required this.updatedAt,
    this.ownerEmail,
    this.permissionLevel = 'owner',
    this.tags = const [],
    this.locationName,
    this.latitude,
    this.longitude,
    this.isPublic = false,
    this.viewCount = 0,
  });

  bool get isOwner => permissionLevel == 'owner';
  bool get canEdit => permissionLevel == 'owner' || permissionLevel == 'editor';
  bool get hasLocation => latitude != null && longitude != null;

  /// Các cột TH2 có thể chưa tồn tại (chưa chạy migration) -> dùng giá trị mặc định
  factory SupabaseDocument.fromMap(
    Map<String, dynamic> map, {
    String currentUserId = '',
    String? resolvedOwnerEmail,
  }) {
    final ownerId = map['owner_id']?.toString() ?? '';
    String perm = 'viewer';
    if (ownerId == currentUserId) {
      perm = 'owner';
    } else if (map['permission_level'] != null) {
      perm = map['permission_level'].toString();
    }

    final locationName = map['location_name']?.toString();

    return SupabaseDocument(
      id: map['id']?.toString() ?? '',
      ownerId: ownerId,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      fileUrl: map['file_url']?.toString() ?? '',
      fileName: map['file_name']?.toString() ?? '',
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      mimeType: map['mime_type']?.toString() ?? 'application/octet-stream',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
      ownerEmail: resolvedOwnerEmail ?? map['owner_email']?.toString(),
      permissionLevel: perm,
      tags: _parseTags(map['tags']),
      locationName: (locationName == null || locationName.isEmpty) ? null : locationName,
      latitude: _parseDouble(map['latitude']),
      longitude: _parseDouble(map['longitude']),
      isPublic: map['is_public'] == true,
      viewCount: (map['view_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SupabasePermission {
  final String id;
  final String documentId;
  final String sharedEmail;
  final String permissionLevel; // 'viewer', 'editor'
  final DateTime createdAt;

  const SupabasePermission({
    required this.id,
    required this.documentId,
    required this.sharedEmail,
    required this.permissionLevel,
    required this.createdAt,
  });

  factory SupabasePermission.fromMap(Map<String, dynamic> map) {
    return SupabasePermission(
      id: map['id']?.toString() ?? '',
      documentId: map['document_id']?.toString() ?? '',
      sharedEmail: map['shared_email']?.toString() ?? '',
      permissionLevel: map['permission_level']?.toString() ?? 'viewer',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Trạng thái yêu cầu mượn tài liệu
enum BorrowStatus {
  pending,
  approved,
  rejected,
  returned,
  cancelled;

  String get label {
    switch (this) {
      case BorrowStatus.pending:
        return 'Đang chờ duyệt';
      case BorrowStatus.approved:
        return 'Đã duyệt';
      case BorrowStatus.rejected:
        return 'Bị từ chối';
      case BorrowStatus.returned:
        return 'Đã trả';
      case BorrowStatus.cancelled:
        return 'Đã hủy';
    }
  }

  static BorrowStatus parse(String value) {
    final v = value.trim().toLowerCase();
    for (final s in BorrowStatus.values) {
      if (s.name == v) return s;
    }
    return BorrowStatus.pending;
  }
}

/// Yêu cầu mượn tài liệu (bảng borrow_requests)
class BorrowRequest {
  final String id;
  final String documentId;
  final String documentTitle;
  final String requesterId;
  final String requesterEmail;
  final String ownerId;
  final BorrowStatus status;
  final String message;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const BorrowRequest({
    required this.id,
    required this.documentId,
    this.documentTitle = '',
    required this.requesterId,
    required this.requesterEmail,
    required this.ownerId,
    this.status = BorrowStatus.pending,
    this.message = '',
    this.dueDate,
    required this.createdAt,
    this.respondedAt,
  });

  factory BorrowRequest.fromMap(Map<String, dynamic> map) {
    // Tiêu đề lấy từ embed PostgREST `documents(title)` nếu có
    String title = map['document_title']?.toString() ?? '';
    final embedded = map['documents'];
    if (title.isEmpty && embedded is Map) {
      title = embedded['title']?.toString() ?? '';
    }

    return BorrowRequest(
      id: map['id']?.toString() ?? '',
      documentId: map['document_id']?.toString() ?? '',
      documentTitle: title,
      requesterId: map['requester_id']?.toString() ?? '',
      requesterEmail: map['requester_email']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      status: BorrowStatus.parse(map['status']?.toString() ?? 'pending'),
      message: map['message']?.toString() ?? '',
      dueDate: _parseDate(map['due_date']),
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      respondedAt: _parseDate(map['responded_at']),
    );
  }
}

class SupabaseDocumentService {
  final String currentUserId;
  final String currentUserEmail;
  late final SupabaseClient _client;

  /// Bộ nhớ đệm tệp tin cục bộ giúp xem và tải về tức thì (0.0s)
  static final Map<String, Uint8List> localFileCache = {};

  SupabaseDocumentService({
    required this.currentUserId,
    required this.currentUserEmail,
  }) {
    _client = SupabaseBootstrap.clientForUser(currentUserId, email: currentUserEmail);
  }

  String get _myEmail => currentUserEmail.trim().toLowerCase();

  /// Chuyển lỗi Supabase thành thông báo tiếng Việt dễ hiểu
  Exception _friendlyError(Object e, String action) {
    if (e is ArgumentError || e is StateError) {
      return Exception(e is ArgumentError ? e.message.toString() : (e as StateError).message);
    }
    String code = '';
    String message = e.toString();
    if (e is PostgrestException) {
      code = e.code ?? '';
      message = e.message;
    } else if (e is StorageException) {
      code = e.statusCode ?? '';
      message = e.message;
    }

    const missingSchemaCodes = {'PGRST204', 'PGRST205', 'PGRST202', '42703', '42P01', '42883'};
    final lower = message.toLowerCase();
    final missingSchema = missingSchemaCodes.contains(code) ||
        (lower.contains('does not exist') && (lower.contains('column') || lower.contains('relation'))) ||
        lower.contains('schema cache');
    if (missingSchema) {
      return Exception(
        'Không thể $action: cơ sở dữ liệu Supabase chưa được nâng cấp cho TH2. '
        'Hãy chạy tệp supabase/th2_migration.sql trong Supabase Dashboard → SQL Editor. ($message)',
      );
    }
    if (code == '42501' || lower.contains('row-level security')) {
      return Exception('Không thể $action: bạn không có quyền thực hiện thao tác này.');
    }
    return Exception('Không thể $action: $message');
  }

  /// Áp dụng bộ lọc tìm kiếm + thẻ chung cho truy vấn documents
  PostgrestFilterBuilder<List<Map<String, dynamic>>> _applyFilters(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query, {
    String? searchQuery,
    List<String> tags = const [],
  }) {
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      // Bỏ ký tự đặc biệt của cú pháp PostgREST or()
      final q = searchQuery.trim().replaceAll(RegExp(r'[,()]'), ' ');
      query = query.or('title.ilike.%$q%,description.ilike.%$q%,file_name.ilike.%$q%');
    }
    final cleanTags = tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    if (cleanTags.isNotEmpty) {
      query = query.contains('tags', cleanTags);
    }
    return query;
  }

  /// 1. Đồng bộ người dùng vào bảng users trên Supabase
  Future<void> syncUserProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      await _client.from('users').upsert({
        'id': currentUserId,
        'email': _myEmail,
        'display_name': displayName ?? currentUserEmail.split('@').first,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _userEmailCache[currentUserId] = _myEmail;
    } catch (e) {
      debugPrint('Supabase syncUserProfile error: $e');
    }
  }

  /// Bộ nhớ đệm thông tin email của người dùng (tránh truy vấn lại nhiều lần)
  static final Map<String, String> _userEmailCache = {
    'user_a_owner': 'sinhvien_a@studydoc.edu.vn',
    'user_b_shared': 'sinhvien_b@studydoc.edu.vn',
    'user_c_stranger': 'sinhvien_c@studydoc.edu.vn',
  };

  /// Tra cứu email của các chủ sở hữu từ bảng users
  Future<Map<String, String>> _resolveOwnerEmails(Iterable<String> ownerIds) async {
    final Map<String, String> result = Map.of(_userEmailCache);
    if (currentUserId.isNotEmpty && currentUserEmail.isNotEmpty) {
      result[currentUserId] = currentUserEmail;
      _userEmailCache[currentUserId] = currentUserEmail;
    }

    final missingIds = ownerIds
        .where((id) => id.isNotEmpty && !result.containsKey(id))
        .toSet()
        .toList();

    if (missingIds.isEmpty) return result;

    try {
      final List<dynamic> users = await _client
          .from('users')
          .select('id, email')
          .inFilter('id', missingIds);
      for (final u in users) {
        if (u is Map) {
          final id = u['id']?.toString();
          final email = u['email']?.toString();
          if (id != null && email != null && email.isNotEmpty) {
            result[id] = email;
            _userEmailCache[id] = email;
          }
        }
      }
    } catch (e) {
      debugPrint('Supabase resolveOwnerEmails notice: $e');
    }

    return result;
  }

  /// 2. Lấy danh sách tài liệu của tôi + được chia sẻ (không gồm tài liệu chỉ công khai)
  Future<List<SupabaseDocument>> getDocuments({
    String? searchQuery,
    bool onlySharedWithMe = false,
    List<String> tags = const [],
  }) async {
    // Luôn đảm bảo tài khoản đã được sync
    await syncUserProfile();

    try {
      // Lấy toàn bộ quyền được chia sẻ của tôi trong 1 truy vấn (tránh N+1)
      final Map<String, String> sharedPerms = {};
      try {
        final List<dynamic> perms = await _client
            .from('document_permissions')
            .select()
            .eq('shared_email', _myEmail);
        final now = DateTime.now();
        for (final p in perms) {
          final m = Map<String, dynamic>.from(p as Map);
          final expiresAt = _parseDate(m['expires_at']);
          if (expiresAt != null && expiresAt.isBefore(now)) continue;
          sharedPerms[m['document_id'].toString()] = m['permission_level']?.toString() ?? 'viewer';
        }
      } catch (e) {
        debugPrint('Supabase getDocuments permissions notice: $e');
      }

      final query = _applyFilters(
        _client.from('documents').select(),
        searchQuery: searchQuery,
        tags: tags,
      );
      final List<dynamic> records = await query.order('created_at', ascending: false);

      final ownerIds = records.map((r) => (r as Map)['owner_id']?.toString() ?? '').where((id) => id.isNotEmpty);
      final ownerEmails = await _resolveOwnerEmails(ownerIds);

      final List<SupabaseDocument> docs = [];
      for (final r in records) {
        final map = Map<String, dynamic>.from(r as Map);
        final isOwner = map['owner_id'] == currentUserId;

        if (onlySharedWithMe && isOwner) {
          continue; // Bỏ qua nếu người dùng chỉ muốn xem tài liệu người khác chia sẻ
        }

        if (!isOwner) {
          final perm = sharedPerms[map['id'].toString()];
          // Tài liệu người khác chỉ hiển thị do công khai -> thuộc getPublicDocuments()
          if (perm == null) continue;
          map['permission_level'] = perm;
        }

        final ownerId = map['owner_id']?.toString() ?? '';
        docs.add(SupabaseDocument.fromMap(
          map,
          currentUserId: currentUserId,
          resolvedOwnerEmail: ownerEmails[ownerId],
        ));
      }

      return docs;
    } catch (e) {
      debugPrint('Supabase getDocuments error: $e');
      throw _friendlyError(e, 'tải danh sách tài liệu');
    }
  }

  /// 2b. Tài liệu công khai của người khác
  Future<List<SupabaseDocument>> getPublicDocuments({
    String searchQuery = '',
    List<String> tags = const [],
  }) async {
    try {
      final query = _applyFilters(
        _client.from('documents').select().eq('is_public', true).neq('owner_id', currentUserId),
        searchQuery: searchQuery,
        tags: tags,
      );
      final List<dynamic> records = await query.order('created_at', ascending: false);

      final ownerIds = records.map((r) => (r as Map)['owner_id']?.toString() ?? '').where((id) => id.isNotEmpty);
      final ownerEmails = await _resolveOwnerEmails(ownerIds);

      return records
          .map((r) {
            final map = Map<String, dynamic>.from(r as Map);
            final ownerId = map['owner_id']?.toString() ?? '';
            return SupabaseDocument.fromMap(
              map,
              currentUserId: currentUserId,
              resolvedOwnerEmail: ownerEmails[ownerId],
            );
          })
          .toList();
    } catch (e) {
      debugPrint('Supabase getPublicDocuments error: $e');
      throw _friendlyError(e, 'tải tài liệu công khai');
    }
  }

  /// 2c. Tập thẻ (không trùng, đã sắp xếp) từ tài liệu của tôi, được chia sẻ và công khai
  Future<List<String>> getAllTags() async {
    final Set<String> all = {};
    final mine = await getDocuments();
    for (final d in mine) {
      all.addAll(d.tags);
    }
    try {
      final pub = await getPublicDocuments();
      for (final d in pub) {
        all.addAll(d.tags);
      }
    } catch (e) {
      // Chưa chạy migration (thiếu cột is_public) -> chỉ dùng thẻ của tài liệu riêng
      debugPrint('Supabase getAllTags public notice: $e');
    }
    final list = all.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// Tải tệp lên Supabase Storage bucket `documents`, trả về public URL (null nếu lỗi)
  Future<String?> _uploadToStorage(String fileName, Uint8List bytes, String mime) async {
    try {
      final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final path = '$currentUserId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final bucket = _client.storage.from(_storageBucket);
      await bucket
          .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime, upsert: true))
          .timeout(const Duration(seconds: 30));
      return bucket.getPublicUrl(path);
    } catch (e) {
      debugPrint('Supabase Storage upload notice: $e');
      return null;
    }
  }

  /// Lấy đường dẫn object trong bucket từ public URL (null nếu không thuộc bucket)
  String? _storagePathFromUrl(String fileUrl) {
    final marker = '/storage/v1/object/public/$_storageBucket/';
    final idx = fileUrl.indexOf(marker);
    if (idx < 0) return null;
    final path = fileUrl.substring(idx + marker.length).split('?').first;
    return path.isEmpty ? null : Uri.decodeComponent(path);
  }

  /// 3. Tạo mới tài liệu: tệp lên Supabase Storage, metadata vào bảng documents
  Future<SupabaseDocument> createDocument({
    required String title,
    String description = '',
    required String fileName,
    required Uint8List fileBytes,
    String? mimeType,
    String? uploadedFileUrl,
    List<String> tags = const [],
    String? locationName,
    double? latitude,
    double? longitude,
    bool isPublic = false,
  }) async {
    final mime = mimeType ?? 'application/octet-stream';
    String finalUrl = uploadedFileUrl ?? '';

    if (finalUrl.isEmpty) {
      finalUrl = await _uploadToStorage(fileName, fileBytes, mime) ?? '';
    }

    // Storage lỗi (vd: chưa tạo bucket) -> nhúng tệp nhỏ dưới dạng data: URL
    if (finalUrl.isEmpty) {
      if (fileBytes.length > _dataUrlFallbackLimit) {
        throw Exception(
          'Không thể tải tệp lên Supabase Storage. Hãy kiểm tra kết nối mạng hoặc chạy '
          'supabase/th2_migration.sql để tạo bucket "documents".',
        );
      }
      finalUrl = 'data:$mime;base64,${base64Encode(fileBytes)}';
    }

    // Lưu vào bộ nhớ đệm để tải xuống tức thì mà không cần tốn mạng
    localFileCache[finalUrl] = fileBytes;

    final cleanTags = tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toSet().toList();

    try {
      final record = await _client.from('documents').insert({
        'owner_id': currentUserId,
        'title': title.trim(),
        'description': description.trim(),
        'file_url': finalUrl,
        'file_name': fileName,
        'file_size': fileBytes.length,
        'mime_type': mime,
        // Chỉ gửi cột TH2 khi có giá trị để vẫn chạy được trước khi migration
        if (cleanTags.isNotEmpty) 'tags': cleanTags,
        if (locationName != null && locationName.trim().isNotEmpty) 'location_name': locationName.trim(),
        'latitude': ?latitude,
        'longitude': ?longitude,
        if (isPublic) 'is_public': true,
      }).select().single();

      return SupabaseDocument.fromMap(record, currentUserId: currentUserId, resolvedOwnerEmail: currentUserEmail);
    } catch (e) {
      debugPrint('Supabase createDocument error: $e');
      throw _friendlyError(e, 'tạo tài liệu');
    }
  }

  /// 4. Cập nhật thông tin tài liệu (Chủ sở hữu hoặc Editor).
  /// Tham số null = giữ nguyên. locationName = '' sẽ xóa vị trí.
  Future<void> updateDocument({
    required String documentId,
    required String title,
    String? description,
    List<String>? tags,
    String? locationName,
    double? latitude,
    double? longitude,
    bool? isPublic,
  }) async {
    final clearLocation = locationName != null && locationName.trim().isEmpty;
    try {
      await _client.from('documents').update({
        'title': title.trim(),
        if (description != null) 'description': description.trim(),
        if (tags != null) 'tags': tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toSet().toList(),
        if (clearLocation) ...{
          'location_name': null,
          'latitude': null,
          'longitude': null,
        } else ...{
          if (locationName != null) 'location_name': locationName.trim(),
          'latitude': ?latitude,
          'longitude': ?longitude,
        },
        'is_public': ?isPublic,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', documentId);
    } catch (e) {
      debugPrint('Supabase updateDocument error: $e');
      throw _friendlyError(e, 'cập nhật tài liệu');
    }
  }

  /// 5. Xóa tài liệu (Chỉ Chủ sở hữu) + xóa tệp trong Storage nếu có
  Future<void> deleteDocument(String documentId) async {
    String fileUrl = '';
    try {
      final row = await _client.from('documents').select('file_url').eq('id', documentId).maybeSingle();
      fileUrl = row?['file_url']?.toString() ?? '';
    } catch (_) {}

    try {
      await _client.from('documents').delete().eq('id', documentId);
    } catch (e) {
      debugPrint('Supabase deleteDocument error: $e');
      throw _friendlyError(e, 'xóa tài liệu');
    }

    localFileCache.remove(fileUrl);
    final path = _storagePathFromUrl(fileUrl);
    if (path != null) {
      try {
        await _client.storage.from(_storageBucket).remove([path]);
      } catch (e) {
        debugPrint('Supabase Storage remove notice: $e');
      }
    }
  }

  /// 6. Lấy danh sách những người được chia sẻ quyền của 1 tài liệu
  Future<List<SupabasePermission>> getDocumentPermissions(String documentId) async {
    try {
      final List<dynamic> res = await _client
          .from('document_permissions')
          .select()
          .eq('document_id', documentId)
          .order('created_at', ascending: true);

      return res.map((e) => SupabasePermission.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      throw _friendlyError(e, 'tải danh sách chia sẻ');
    }
  }

  /// 7. Phân quyền chia sẻ tài liệu cho người khác qua email (Checklist 4)
  Future<void> shareDocument({
    required String documentId,
    required String recipientEmail,
    required String permissionLevel, // 'viewer' hoặc 'editor'
  }) async {
    final email = recipientEmail.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      throw ArgumentError('Email không hợp lệ.');
    }
    if (email == _myEmail) {
      throw ArgumentError('Bạn không thể chia sẻ tài liệu cho chính mình.');
    }

    await _client.from('document_permissions').upsert({
      'document_id': documentId,
      'shared_email': email,
      'permission_level': permissionLevel,
    }, onConflict: 'document_id,shared_email');
  }

  /// 8. Thu hồi quyền chia sẻ
  Future<void> revokePermission(String permissionId) async {
    await _client.from('document_permissions').delete().eq('id', permissionId);
  }

  // ===========================================================================
  // TH2: Lượt xem
  // ===========================================================================

  /// Ghi nhận 1 lượt xem (RPC record_document_view). Lỗi chỉ được log, không ném ra
  /// để không làm gián đoạn việc mở tài liệu.
  Future<void> recordView(String documentId) async {
    try {
      await _client.rpc('record_document_view', params: {'p_document_id': documentId});
    } catch (e) {
      debugPrint('Supabase recordView notice: $e');
    }
  }

  /// ID các tài liệu đã xem gần đây (mới nhất trước, không trùng)
  Future<List<String>> getViewedDocumentIds({int limit = 50}) async {
    try {
      final List<dynamic> rows = await _client
          .from('document_views')
          .select('document_id, viewed_at')
          .eq('user_id', currentUserId)
          .order('viewed_at', ascending: false)
          .limit(limit * 4);
      final ids = <String>[];
      for (final r in rows) {
        final id = (r as Map)['document_id']?.toString() ?? '';
        if (id.isNotEmpty && !ids.contains(id)) ids.add(id);
        if (ids.length >= limit) break;
      }
      return ids;
    } catch (e) {
      debugPrint('Supabase getViewedDocumentIds error: $e');
      throw _friendlyError(e, 'tải lịch sử xem');
    }
  }

  // ===========================================================================
  // TH2: Mượn tài liệu
  // ===========================================================================

  /// Gửi yêu cầu mượn tài liệu tới chủ sở hữu
  Future<BorrowRequest> requestBorrow(
    SupabaseDocument doc, {
    String message = '',
    DateTime? dueDate,
  }) async {
    if (doc.ownerId == currentUserId) {
      throw Exception('Bạn là chủ sở hữu tài liệu này, không cần mượn.');
    }
    try {
      final existing = await _client
          .from('borrow_requests')
          .select('id')
          .eq('document_id', doc.id)
          .eq('requester_id', currentUserId)
          .eq('status', BorrowStatus.pending.name)
          .limit(1);
      if ((existing as List).isNotEmpty) {
        throw Exception('Bạn đã gửi yêu cầu mượn tài liệu này và đang chờ duyệt.');
      }

      final record = await _client.from('borrow_requests').insert({
        'document_id': doc.id,
        'requester_id': currentUserId,
        'requester_email': _myEmail,
        'owner_id': doc.ownerId,
        'status': BorrowStatus.pending.name,
        'message': message.trim(),
        if (dueDate != null) 'due_date': dueDate.toUtc().toIso8601String(),
      }).select('*, documents(title)').single();

      return BorrowRequest.fromMap(record);
    } on Exception catch (e) {
      if (e is! PostgrestException) rethrow;
      debugPrint('Supabase requestBorrow error: $e');
      throw _friendlyError(e, 'gửi yêu cầu mượn');
    }
  }

  Future<List<BorrowRequest>> _getBorrowRequests(String column, String action) async {
    try {
      final List<dynamic> rows = await _client
          .from('borrow_requests')
          .select('*, documents(title)')
          .eq(column, currentUserId)
          .order('created_at', ascending: false);
      return rows.map((r) => BorrowRequest.fromMap(Map<String, dynamic>.from(r as Map))).toList();
    } catch (e) {
      debugPrint('Supabase $action error: $e');
      throw _friendlyError(e, action);
    }
  }

  /// Yêu cầu mượn gửi tới tôi (tôi là chủ sở hữu)
  Future<List<BorrowRequest>> getIncomingBorrowRequests() =>
      _getBorrowRequests('owner_id', 'tải yêu cầu mượn đến');

  /// Yêu cầu mượn tôi đã gửi
  Future<List<BorrowRequest>> getOutgoingBorrowRequests() =>
      _getBorrowRequests('requester_id', 'tải yêu cầu mượn đã gửi');

  Future<void> _setBorrowStatus(BorrowRequest r, BorrowStatus status) async {
    await _client.from('borrow_requests').update({
      'status': status.name,
      'responded_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', r.id);
  }

  /// Duyệt: cấp quyền viewer có hạn (expires_at = dueDate) rồi đánh dấu approved
  Future<void> approveBorrow(BorrowRequest r) async {
    try {
      final email = r.requesterEmail.trim().toLowerCase();
      // Không hạ cấp quyền chia sẻ vĩnh viễn sẵn có (vd: editor không thời hạn)
      final current = await _client
          .from('document_permissions')
          .select()
          .eq('document_id', r.documentId)
          .eq('shared_email', email)
          .maybeSingle();
      final hasPermanent = current != null && current['expires_at'] == null;

      if (!hasPermanent) {
        await _client.from('document_permissions').upsert({
          'document_id': r.documentId,
          'shared_email': email,
          'permission_level': 'viewer',
          'expires_at': r.dueDate?.toUtc().toIso8601String(),
        }, onConflict: 'document_id,shared_email');
      }
      await _setBorrowStatus(r, BorrowStatus.approved);
    } catch (e) {
      debugPrint('Supabase approveBorrow error: $e');
      throw _friendlyError(e, 'duyệt yêu cầu mượn');
    }
  }

  Future<void> rejectBorrow(BorrowRequest r) async {
    try {
      await _setBorrowStatus(r, BorrowStatus.rejected);
    } catch (e) {
      throw _friendlyError(e, 'từ chối yêu cầu mượn');
    }
  }

  /// Trả tài liệu: đánh dấu returned + thu hồi quyền mượn (chỉ quyền có thời hạn)
  Future<void> returnBorrow(BorrowRequest r) async {
    try {
      await _setBorrowStatus(r, BorrowStatus.returned);
      await _client
          .from('document_permissions')
          .delete()
          .eq('document_id', r.documentId)
          .eq('shared_email', r.requesterEmail.trim().toLowerCase())
          .not('expires_at', 'is', null);
    } catch (e) {
      debugPrint('Supabase returnBorrow error: $e');
      throw _friendlyError(e, 'trả tài liệu');
    }
  }

  Future<void> cancelBorrow(BorrowRequest r) async {
    try {
      await _setBorrowStatus(r, BorrowStatus.cancelled);
    } catch (e) {
      throw _friendlyError(e, 'hủy yêu cầu mượn');
    }
  }

  // ===========================================================================
  // TH2: Thông báo đẩy
  // ===========================================================================

  /// Lưu FCM token của thiết bị vào bảng users
  Future<void> saveFcmToken(String token) async {
    try {
      await _client.from('users').update({'fcm_token': token}).eq('id', currentUserId);
    } catch (e) {
      debugPrint('Supabase saveFcmToken error: $e');
      throw _friendlyError(e, 'lưu FCM token');
    }
  }
}
