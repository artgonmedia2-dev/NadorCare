import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nc_api_client/nc_api_client.dart';
import 'package:nc_core/nc_core.dart';

/// Remplace le réseau : enregistre les requêtes et renvoie les réponses prévues.
class _FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];
  final List<ResponseBody> _responses = <ResponseBody>[];
  DioException? failure;

  void reply(int status, Map<String, dynamic> body, {Map<String, List<String>> headers = const {}}) {
    _responses.add(
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          ...headers,
        },
      ),
    );
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (failure != null) {
      throw failure!;
    }
    return _responses.removeAt(0);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeAdapter adapter;
  late AuthApi api;
  String? token;
  var language = 'fr';

  const user = <String, dynamic>{
    'id': '01TESTUSER',
    'phone': '+212612345678',
    'name': null,
    'locale': 'fr',
    'status': 'active',
    'roles': <String>['patient'],
  };

  setUp(() {
    token = null;
    language = 'fr';
    adapter = _FakeAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      config: const AppConfig(clientApp: ClientApp.patient, apiBaseUrl: 'https://api.test/api/v1'),
      readToken: () async => token,
      readLanguage: () => language,
      dio: dio,
    );
    api = HttpAuthApi(client);
  });

  test('la demande de code envoie le numéro et la langue, sans jeton', () async {
    adapter.reply(202, <String, dynamic>{'message': 'ok', 'expires_in': 300, 'resend_in': 60});
    language = 'ar';

    final challenge = await api.requestOtp('0612345678');

    expect(challenge.expiresIn, 300);
    expect(challenge.resendIn, 60);

    final request = adapter.requests.single;
    expect(request.uri.toString(), 'https://api.test/api/v1/auth/otp/request');
    expect(request.method, 'POST');
    expect(request.data, <String, dynamic>{'phone': '0612345678'});
    expect(request.headers['Accept-Language'], 'ar');
    expect(request.headers['Accept'], 'application/json');
    expect(request.headers.containsKey('Authorization'), isFalse);
  });

  test('la vérification renvoie le jeton, le compte et indique un nouveau compte', () async {
    adapter.reply(200, <String, dynamic>{'token': '1|abc', 'token_type': 'Bearer', 'is_new_user': true, 'user': user});

    final session = await api.verifyOtp(
      phone: '+212612345678',
      code: '123456',
      app: ClientApp.patient,
      deviceName: 'android',
      acceptTerms: true,
      locale: 'fr',
    );

    expect(session.token, '1|abc');
    expect(session.isNewUser, isTrue);
    expect(session.user.phone, '+212612345678');
    expect(session.user.roles, <String>['patient']);
    expect(adapter.requests.single.data, <String, dynamic>{
      'phone': '+212612345678',
      'code': '123456',
      'app': 'patient',
      'device_name': 'android',
      'accept_terms': true,
      'locale': 'fr',
    });
  });

  test('le jeton est ajouté aux requêtes une fois connecté', () async {
    token = '1|abc';
    adapter.reply(200, <String, dynamic>{'data': user});

    final me = await api.me();

    expect(me.id, '01TESTUSER');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer 1|abc');
  });

  test('la mise à jour du compte n envoie que les champs fournis', () async {
    token = '1|abc';
    adapter.reply(200, <String, dynamic>{
      'data': <String, dynamic>{...user, 'name': 'Fatima'},
    });

    final updated = await api.updateMe(name: 'Fatima');

    expect(updated.name, 'Fatima');
    expect(adapter.requests.single.method, 'PATCH');
    expect(adapter.requests.single.data, <String, dynamic>{'name': 'Fatima'});
  });

  test('une erreur métier devient une ApiFailure avec son code stable', () async {
    adapter.reply(422, <String, dynamic>{'message': 'Ce code est incorrect ou a expiré.', 'code': 'otp_invalid'});

    await expectLater(
      api.verifyOtp(phone: '+212612345678', code: '000000', app: ClientApp.pro, deviceName: 'ios', acceptTerms: false),
      throwsA(
        isA<ApiFailure>()
            .having((failure) => failure.code, 'code', ApiFailure.otpInvalid)
            .having((failure) => failure.status, 'status', 422)
            .having((failure) => failure.message, 'message', 'Ce code est incorrect ou a expiré.'),
      ),
    );
  });

  test('les erreurs de validation sont rattachées à leur champ', () async {
    adapter.reply(422, <String, dynamic>{
      'message': 'Certaines informations sont incorrectes.',
      'code': 'validation_failed',
      'errors': <String, dynamic>{
        'phone': <String>['Ce numéro de téléphone n\'est pas valide.'],
      },
    });

    try {
      await api.requestOtp('123');
      fail('Une ApiFailure était attendue.');
    } on ApiFailure catch (failure) {
      expect(failure.code, ApiFailure.validationFailed);
      expect(failure.firstErrorFor('phone'), 'Ce numéro de téléphone n\'est pas valide.');
      expect(failure.firstErrorFor('code'), isNull);
    }
  });

  test('le délai avant une nouvelle demande est lu dans le corps ou dans l en-tête', () async {
    adapter.reply(429, <String, dynamic>{'message': 'Patientez.', 'code': 'otp_too_soon', 'retry_after': 42});
    await expectLater(
      api.requestOtp('0612345678'),
      throwsA(isA<ApiFailure>().having((failure) => failure.retryAfterSeconds, 'retryAfter', 42)),
    );

    adapter.reply(
      429,
      <String, dynamic>{'message': 'Trop de demandes.', 'code': 'too_many_requests'},
      headers: <String, List<String>>{
        'retry-after': <String>['17'],
      },
    );
    await expectLater(
      api.requestOtp('0612345678'),
      throwsA(isA<ApiFailure>().having((failure) => failure.retryAfterSeconds, 'retryAfter', 17)),
    );
  });

  test('une coupure réseau devient une erreur réseau', () async {
    adapter.failure = DioException.connectionError(
      requestOptions: RequestOptions(path: '/me'),
      reason: 'hors ligne',
    );

    await expectLater(
      api.me(),
      throwsA(isA<ApiFailure>().having((failure) => failure.isNetwork, 'isNetwork', isTrue)),
    );
  });

  test('l épinglage accepte seulement le certificat attendu', () {
    final certificate = utf8.encode('certificat du serveur');
    final fingerprint = sha256.convert(certificate).toString();
    final withColons = fingerprint.toUpperCase().replaceAllMapped(RegExp('..(?!\$)'), (match) => '${match[0]}:');

    expect(CertificatePinning.matches(certificate, <String>[fingerprint]), isTrue);
    expect(CertificatePinning.matches(certificate, <String>[withColons]), isTrue);
    expect(CertificatePinning.matches(utf8.encode('certificat d un intermédiaire'), <String>[fingerprint]), isFalse);
    expect(CertificatePinning.matches(certificate, const <String>[]), isFalse);
  });

  test('les empreintes sont lues et normalisées depuis la configuration', () {
    const config = AppConfig(clientApp: ClientApp.patient, apiBaseUrl: 'https://api.test');
    expect(config.pinnedCertificateSha256, isEmpty);
    expect(AppConfig.fromEnvironment(ClientApp.pro).clientApp, ClientApp.pro);
  });
}
