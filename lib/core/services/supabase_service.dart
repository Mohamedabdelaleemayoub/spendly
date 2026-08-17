import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initialises the Supabase client using environment variables.
///
/// Must be called once during app startup (before [runApp]).
/// Credentials are loaded from `.env` via [flutter_dotenv] or compile-time
/// `--dart-define` parameters.
abstract final class SupabaseService {
  /// Initialise Supabase. Call from [main].
  static Future<void> init() async {
    final url = (dotenv.env['SUPABASE_URL']?.trim().isNotEmpty == true
            ? dotenv.env['SUPABASE_URL']!.trim()
            : null) ??
        (const String.fromEnvironment('SUPABASE_URL').trim().isNotEmpty
            ? const String.fromEnvironment('SUPABASE_URL').trim()
            : null);

    final anonKey = (dotenv.env['SUPABASE_ANON_KEY']?.trim().isNotEmpty == true
            ? dotenv.env['SUPABASE_ANON_KEY']!.trim()
            : null) ??
        (const String.fromEnvironment('SUPABASE_ANON_KEY').trim().isNotEmpty
            ? const String.fromEnvironment('SUPABASE_ANON_KEY').trim()
            : null);

    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env or via --dart-define',
      );
    }

    // Safe debugging: Log project URL and project ref ONLY (NEVER the anon key)
    final uri = Uri.tryParse(url);
    final projectRef = uri != null && uri.host.contains('.supabase.co')
        ? uri.host.split('.').first
        : 'unknown';

    debugPrint('🔌 [SupabaseService] Initializing Supabase...');
    debugPrint('🔌 [SupabaseService] SUPABASE_URL: $url');
    debugPrint('🔌 [SupabaseService] Project Reference: $projectRef');

    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
    );

    debugPrint('✅ [SupabaseService] Supabase initialized successfully.');
  }

  /// Convenience accessor for the singleton [SupabaseClient].
  static SupabaseClient get client => Supabase.instance.client;
}
