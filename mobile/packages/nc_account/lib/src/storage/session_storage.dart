import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nc_core/nc_core.dart';

/// Session conservée sur l'appareil : jeton d'accès et dernier compte connu.
abstract interface class SessionStorage {
  Future<String?> readToken();

  Future<AppUser?> readUser();

  Future<void> save({required String token, required AppUser user});

  Future<void> saveUser(AppUser user);

  Future<void> clear();
}

/// Stockage chiffré par le système : Keystore sur Android, Trousseau sur iOS.
/// Le jeton ne va jamais dans les préférences ni dans un fichier en clair.
class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'nc.session.token';
  static const String _userKey = 'nc.session.user';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<AppUser?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) {
      return null;
    }
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save({required String token, required AppUser user}) async {
    await _storage.write(key: _tokenKey, value: token);
    await saveUser(user);
  }

  @override
  Future<void> saveUser(AppUser user) => _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}

/// Stockage en mémoire, pour les tests.
class InMemorySessionStorage implements SessionStorage {
  InMemorySessionStorage({this.token, this.user});

  String? token;
  AppUser? user;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<AppUser?> readUser() async => user;

  @override
  Future<void> save({required String token, required AppUser user}) async {
    this.token = token;
    this.user = user;
  }

  @override
  Future<void> saveUser(AppUser user) async => this.user = user;

  @override
  Future<void> clear() async {
    token = null;
    user = null;
  }
}
