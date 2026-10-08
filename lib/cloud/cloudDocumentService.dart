import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'cloudDocument.dart';
import 'firebaseBootstrap.dart';

class CloudDocumentService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  bool _googleInitialized = false;

  CloudDocumentService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  Stream<User?> get authChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signInWithGoogle() async {
    if (FirebaseBootstrap.useEmulator) {
      throw StateError('Emulator không phải đăng nhập Google thật.');
    }
    if (kIsWeb) {
      await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(
          serverClientId: FirebaseBootstrap.googleServerClientId.isEmpty
              ? null
              : FirebaseBootstrap.googleServerClientId,
        );
        _googleInitialized = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final credential = GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
      await _auth.signInWithCredential(credential);
    }
  }

  Future<void> signInEmulator(String email) async {
    if (!FirebaseBootstrap.useEmulator ||
        !{'alice@example.test', 'bob@example.test'}.contains(email)) {
      throw StateError('Tài khoản thử nghiệm chỉ được dùng với Emulator.');
    }
    const password = 'emulator-only-password';
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found' &&
          error.code != 'invalid-credential') {
        rethrow;
      }
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  }

  Future<void> signOut() => _auth.signOut();

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Vui lòng đăng nhập trước.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _documents(String uid) =>
      _firestore.collection('users').doc(uid).collection('documents');

  Stream<List<CloudDocument>> watchDocuments() => _documents(_uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(CloudDocument.fromSnapshot).toList(),
      );

  Future<void> uploadDocument(
    CloudUpload upload, {
    void Function(double progress)? onProgress,
  }) async {
    CloudFilePolicy.validate(upload);
    final uid = _uid;
    final doc = _documents(uid).doc();
    final path = 'users/$uid/documents/${doc.id}/file';
    final ref = _storage.ref(path);
    final mime = CloudFilePolicy.contentTypeFor(upload.fileName);
    final task = ref.putData(upload.bytes, SettableMetadata(contentType: mime));
    final subscription = task.snapshotEvents.listen(
      (snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      },
      onError: (Object error) {
        // The awaited upload task below reports the failure to the caller.
        debugPrint('Storage upload: $error');
      },
    );
    try {
      await task;
    } finally {
      await subscription.cancel();
    }
    try {
      await doc.set({
        'ownerId': uid,
        'title': upload.title.trim(),
        'subject': upload.subject.trim(),
        'note': upload.note.trim(),
        'fileName': upload.fileName,
        'contentType': mime,
        'size': upload.bytes.length,
        'storagePath': path,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (metadataError) {
      try {
        await ref.delete();
      } on FirebaseException catch (cleanupError) {
        throw StateError(
          'Lưu metadata thất bại (${metadataError.code}); '
          'cần xóa tệp mồ côi trong Console: $path (${cleanupError.code}).',
        );
      }
      rethrow;
    }
  }

  void _checkOwner(CloudDocument document) {
    if (document.ownerId != _uid ||
        document.storagePath != 'users/$_uid/documents/${document.id}/file') {
      throw StateError('Bạn không có quyền truy cập tài liệu này.');
    }
  }

  Future<Uint8List> downloadDocument(CloudDocument document) async {
    _checkOwner(document);
    final bytes = await _storage
        .ref(document.storagePath)
        .getData(CloudFilePolicy.maxBytes);
    if (bytes == null) throw StateError('Không nhận được dữ liệu tệp.');
    return bytes;
  }

  Future<void> updateDocument(
    CloudDocument document,
    String title,
    String note,
  ) async {
    _checkOwner(document);
    if (title.trim().isEmpty ||
        title.trim().length > 250 ||
        note.length > 4000) {
      throw ArgumentError('Tiêu đề 1–250 ký tự, ghi chú tối đa 4000 ký tự.');
    }
    await _documents(_uid)
        .doc(document.id)
        .update({'title': title.trim(), 'note': note.trim()});
  }

  Future<void> deleteDocument(CloudDocument document) async {
    _checkOwner(document);
    final uid = _uid;
    // Storage and Firestore cannot share a transaction. Retry is safe if the
    // object was deleted but the metadata delete failed.
    try {
      await _storage.ref(document.storagePath).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
    await _documents(uid).doc(document.id).delete();
  }
}
