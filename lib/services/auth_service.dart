import '../models/models.dart';
import 'api_client.dart';
import 'local_store.dart';

/// Authenticates against the Pinspire API and keeps the Sanctum token in
/// local storage (SharedPreferences). No password is ever stored locally.
class AuthService {
  AuthService(this.store, this.api);

  final LocalStore store;
  final ApiClient api;

  static const tokenKey = 'pinspire.api_token.v1';
  static const demoEmail = 'demo@pinspire.test';
  static const demoPassword = 'password';

  Future<String?> restoreToken() async {
    final token = await store.read(tokenKey);
    api.token = token;
    return token;
  }

  Future<UserProfile> login(String email, String password) async {
    final result = await api.post(
      '/auth/login',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'device_name': 'pinspire-web',
      },
    );
    await _persistToken(result.object['access_token'] as String?);
    return UserProfile.fromApi(result.object['user'] as Map<String, dynamic>);
  }

  Future<UserProfile> register(
    String name,
    String username,
    String email,
    String password,
  ) async {
    final result = await api.post(
      '/auth/register',
      body: {
        'name': name.trim(),
        'username': username.trim().toLowerCase(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'password_confirmation': password,
        'device_name': 'pinspire-web',
      },
    );
    await _persistToken(result.object['access_token'] as String?);
    return UserProfile.fromApi(result.object['user'] as Map<String, dynamic>);
  }

  Future<UserProfile> me() async {
    final result = await api.get('/auth/me');
    return UserProfile.fromApi(result.object);
  }

  Future<void> logout() async {
    try {
      if (api.token != null) await api.post('/auth/logout');
    } finally {
      await clearToken();
    }
  }

  Future<void> _persistToken(String? token) async {
    api.token = token;
    if (token == null || token.isEmpty) {
      await store.remove(tokenKey);
    } else {
      await store.write(tokenKey, token);
    }
  }

  Future<void> clearToken() async {
    api.token = null;
    await store.remove(tokenKey);
  }
}
