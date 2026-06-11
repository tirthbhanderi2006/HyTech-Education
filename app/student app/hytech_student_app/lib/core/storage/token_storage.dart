import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessKey  = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey    = 'user_data';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey,  value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  static Future<String?> getAccessToken()  => _storage.read(key: _accessKey);
  static Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  static Future<void> saveUserData(String json) =>
      _storage.write(key: _userKey, value: json);
  static Future<String?> getUserData() => _storage.read(key: _userKey);

  static Future<bool> isLoggedIn() async =>
      (await getAccessToken()) != null;

  static Future<void> clear() async => _storage.deleteAll();
}
