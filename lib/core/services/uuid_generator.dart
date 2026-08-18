import 'dart:math';

/// Secure client-side RFC 4122 v4 UUID generator.
///
/// Uses [Random.secure] to produce cryptographically secure random UUIDs
/// without external native plugin dependencies.
abstract final class UuidGenerator {
  static final Random _secureRandom = Random.secure();

  /// Generates a standard RFC 4122 version 4 UUID string.
  /// Format: `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`
  static String generate() {
    final values = List<int>.generate(16, (_) => _secureRandom.nextInt(256));

    // Set version to 4 -> 0100xxxx
    values[6] = (values[6] & 0x0f) | 0x40;
    // Set variant to RFC 4122 -> 10xxxxxx
    values[8] = (values[8] & 0x3f) | 0x80;

    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).toList();

    return '${hex[0]}${hex[1]}${hex[2]}${hex[3]}-'
        '${hex[4]}${hex[5]}-'
        '${hex[6]}${hex[7]}-'
        '${hex[8]}${hex[9]}-'
        '${hex[10]}${hex[11]}${hex[12]}${hex[13]}${hex[14]}${hex[15]}';
  }
}
