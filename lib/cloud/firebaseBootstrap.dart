import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  static const useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
  static const emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _bucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static bool isReady = false;
  static String? initializationError;
  static bool get platformSupported =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;
  static String get activeProjectId =>
      useEmulator ? 'demo-studydoc' : projectId;
  static bool get hasConfiguration =>
      useEmulator ||
      [
        projectId,
        _apiKey,
        _appId,
        _senderId,
        _bucket,
        _authDomain,
      ].every((value) => value.isNotEmpty);

  static Future<void> initialize() async {
    if (!hasConfiguration || !platformSupported) return;
    try {
      await Firebase.initializeApp(
        options: useEmulator
            ? const FirebaseOptions(
                apiKey: 'demo-api-key',
                appId: '1:123456789:web:studydoc',
                messagingSenderId: '123456789',
                projectId: 'demo-studydoc',
                storageBucket: 'demo-studydoc.appspot.com',
                authDomain: 'demo-studydoc.firebaseapp.com',
              )
            : const FirebaseOptions(
                apiKey: _apiKey,
                appId: _appId,
                messagingSenderId: _senderId,
                projectId: projectId,
                storageBucket: _bucket,
                authDomain: _authDomain,
              ),
      );
      // Cloud metadata is online-only; SQLite remains the separate offline store.
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
      if (useEmulator) {
        await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
        await FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
      }
      isReady = true;
    } on FirebaseException catch (error) {
      initializationError = '${error.code}: ${error.message}';
    }
  }
}
