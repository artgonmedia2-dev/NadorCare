import 'package:nc_core/nc_core.dart';

import 'api_client.dart';

/// Réponse à une demande de code : durées en secondes.
class OtpChallenge {
  const OtpChallenge({required this.expiresIn, required this.resendIn});

  final int expiresIn;
  final int resendIn;
}

/// Session ouverte après vérification du code.
class AuthSession {
  const AuthSession({required this.token, required this.user, required this.isNewUser});

  final String token;
  final AppUser user;
  final bool isNewUser;
}

/// Authentification et compte. L'interface permet de remplacer l'API dans les tests.
abstract interface class AuthApi {
  Future<OtpChallenge> requestOtp(String phone);

  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
    required ClientApp app,
    required String deviceName,
    required bool acceptTerms,
    String? locale,
  });

  Future<void> logout();

  Future<AppUser> me();

  Future<AppUser> updateMe({String? name, String? locale});
}

class HttpAuthApi implements AuthApi {
  const HttpAuthApi(this._client);

  final ApiClient _client;

  @override
  Future<OtpChallenge> requestOtp(String phone) async {
    final json = await _client.post('/auth/otp/request', <String, dynamic>{'phone': phone});

    return OtpChallenge(
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 300,
      resendIn: (json['resend_in'] as num?)?.toInt() ?? 60,
    );
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
    required ClientApp app,
    required String deviceName,
    required bool acceptTerms,
    String? locale,
  }) async {
    final json = await _client.post('/auth/otp/verify', <String, dynamic>{
      'phone': phone,
      'code': code,
      'app': app.apiValue,
      'device_name': deviceName,
      'accept_terms': acceptTerms,
      'locale': ?locale,
    });

    return AuthSession(
      token: json['token'] as String,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      isNewUser: (json['is_new_user'] as bool?) ?? false,
    );
  }

  @override
  Future<void> logout() async {
    await _client.post('/auth/logout');
  }

  @override
  Future<AppUser> me() async {
    final json = await _client.get('/me');
    return AppUser.fromJson(json['data'] as Map<String, dynamic>);
  }

  @override
  Future<AppUser> updateMe({String? name, String? locale}) async {
    final json = await _client.patch('/me', <String, dynamic>{
      'name': ?name,
      'locale': ?locale,
    });
    return AppUser.fromJson(json['data'] as Map<String, dynamic>);
  }
}