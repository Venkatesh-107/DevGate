import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Central abstraction over [FlutterSecureStorage].
///
/// All storage key strings live here — no magic strings elsewhere in the app.
class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  // ─── Keys ──────────────────────────────────────────────────────────────────
  static const keyName              = 'user_name';
  static const keyUsername          = 'github_username';
  static const keyToken             = 'github_access_token';
  static const keyEntropyThreshold  = 'entropy_threshold';
  static const keyMaxFileSizeKb     = 'max_file_size_kb';

  // ─── Read ──────────────────────────────────────────────────────────────────
  Future<String?> getName()     => _storage.read(key: keyName);
  Future<String?> getUsername() => _storage.read(key: keyUsername);
  Future<String?> getToken()    => _storage.read(key: keyToken);

  Future<double> getEntropyThreshold() async {
    final raw = await _storage.read(key: keyEntropyThreshold);
    return double.tryParse(raw ?? '') ?? 4.8;
  }

  Future<int> getMaxFileSizeKb() async {
    final raw = await _storage.read(key: keyMaxFileSizeKb);
    return int.tryParse(raw ?? '') ?? 5120; // default 5 MB
  }

  // ─── Write ─────────────────────────────────────────────────────────────────
  Future<void> saveName(String name) =>
      _storage.write(key: keyName, value: name);

  Future<void> saveUsername(String username) =>
      _storage.write(key: keyUsername, value: username);

  Future<void> saveToken(String token) =>
      _storage.write(key: keyToken, value: token);

  Future<void> saveEntropyThreshold(double threshold) =>
      _storage.write(key: keyEntropyThreshold, value: threshold.toString());

  Future<void> saveMaxFileSizeKb(int kb) =>
      _storage.write(key: keyMaxFileSizeKb, value: kb.toString());

  // ─── Check ─────────────────────────────────────────────────────────────────
  /// Returns true when a complete profile (name + token) exists.
  Future<bool> hasProfile() async {
    final name  = await getName();
    final token = await getToken();
    return name != null && name.isNotEmpty && token != null && token.isNotEmpty;
  }

  // ─── Danger zone ───────────────────────────────────────────────────────────
  Future<void> clearAll() => _storage.deleteAll();
}

/// App-wide singleton — avoids creating multiple storage instances.
final storageService = SecureStorageService();
