import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/models.dart';
import 'local_store.dart';

/// Autentikasi lokal untuk presentasi. Bukan pengganti layanan autentikasi server.
/// Password tidak disimpan sebagai teks. Jangan gunakan kredensial akun nyata.
class AuthService {
  AuthService(this.store);
  final LocalStore store;
  static const accountKey = 'pinspire.local_account.v1';
  static const demoEmail = 'demo@pinspire.app';
  static const demoPassword = 'Pinspire123!';

  String _digest(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
  Future<UserProfile> login(String email, String password) async {
    if (email.trim().toLowerCase() == demoEmail && password == demoPassword) {
      return const UserProfile();
    }
    final raw = await store.read(accountKey);
    if (raw != null) {
      final account = jsonDecode(raw) as Map<String, dynamic>;
      if (account['email'] == email.trim().toLowerCase() &&
          account['hash'] == _digest(password, account['salt'] as String)) {
        return UserProfile.fromJson(account['profile'] as Map<String, dynamic>);
      }
    }
    throw const FormatException(
      'Email atau kata sandi tidak cocok dengan akun lokal.',
    );
  }

  Future<UserProfile> register(
    String name,
    String email,
    String password,
  ) async {
    final normalized = email.trim().toLowerCase();
    if (normalized == demoEmail) {
      throw const FormatException('Alamat ini sudah dipakai akun demo.');
    }
    final existing = await store.read(accountKey);
    if (existing != null) {
      throw const FormatException(
        'Satu akun lokal sudah terdaftar di perangkat ini. Silakan masuk atau reset melalui Pengaturan.',
      );
    }
    final salt = base64Encode(
      List<int>.generate(24, (_) => Random.secure().nextInt(256)),
    );
    final username = normalized
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-z0-9_.]'), '');
    final profile = UserProfile(
      name: name.trim(),
      username: username,
      email: normalized,
      bio: 'Mengumpulkan ide, satu pin setiap hari.',
    );
    await store.write(
      accountKey,
      jsonEncode({
        'email': normalized,
        'salt': salt,
        'hash': _digest(password, salt),
        'profile': profile.toJson(),
      }),
    );
    return profile;
  }

  Future<void> updateProfile(UserProfile profile) async {
    final raw = await store.read(accountKey);
    if (raw == null) return;
    final account = jsonDecode(raw) as Map<String, dynamic>;
    if (account['email'] == profile.email) {
      account['profile'] = profile.toJson();
      await store.write(accountKey, jsonEncode(account));
    }
  }

  Future<void> reset() => store.remove(accountKey);
}
