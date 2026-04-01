import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _emailKey    = 'marapedia_email';
  static const _passwordKey = 'marapedia_password';
  static const _tokenKey    = 'marapedia_token';

  static Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }

  static Future<Map<String, String?>> getCredentials() async {
    return {
      'email': await _storage.read(key: _emailKey),
      'password': await _storage.read(key: _passwordKey),
    };
  }

  static Future<void> clearCredentials() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
