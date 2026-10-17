import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  static const String url = 'https://opfzpgscyxwppgjpefhz.supabase.co';
  static const String anonKey = 'sb_publishable_eeuPeFE-5kD4eFuQKiFPKA_ITn0KjWq';

  static bool isReady = false;
  static String? initializationError;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
      );
      isReady = true;
    } catch (e) {
      initializationError = e.toString();
      debugPrint('Lỗi khởi tạo Supabase: $e');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Tạo client có gắn header x-user-id (và x-user-email nếu có) để
  /// Supabase Row Level Security (RLS) nhận diện người dùng
  static SupabaseClient clientForUser(String userId, {String? email}) {
    if (!isReady) throw StateError('Supabase chưa được khởi tạo thành công.');
    final normalizedEmail = email?.trim().toLowerCase() ?? '';
    return SupabaseClient(
      url,
      anonKey,
      headers: {
        'x-user-id': userId,
        if (normalizedEmail.isNotEmpty) 'x-user-email': normalizedEmail,
      },
    );
  }
}
