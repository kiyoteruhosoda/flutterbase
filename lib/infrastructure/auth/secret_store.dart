import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small secrets kept by the platform's keystore — here, the refresh token of
/// the optional sign-in.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// [SecretStore] over the Android Keystore.
final class FlutterSecureStorageSecretStore implements SecretStore {
  const FlutterSecureStorageSecretStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
