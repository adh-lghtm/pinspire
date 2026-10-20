import 'package:shared_preferences/shared_preferences.dart';

// Ganti implementasi ini saat memakai database/API. Tidak menyimpan token backend.
abstract class LocalStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class PreferencesStore implements LocalStore {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  @override
  Future<String?> read(String key) => _preferences.getString(key);
  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
  @override
  Future<void> remove(String key) => _preferences.remove(key);
}

// Dipakai oleh pengujian tanpa plugin atau disk.
class MemoryStore implements LocalStore {
  final Map<String, String> values = {};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}
