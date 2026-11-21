import 'package:dio/dio.dart';
import 'package:nc_core/nc_core.dart';

import 'certificate_pinning.dart';

typedef TokenReader = Future<String?> Function();
typedef LanguageReader = String Function();

/// Accès HTTP à l'API. Ajoute le jeton et la langue à chaque requête, et convertit
/// toute erreur en [ApiFailure] : le reste de l'application ne voit jamais Dio.
class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenReader readToken,
    required LanguageReader readLanguage,
    Dio? dio,
  })  : _readToken = readToken, // ignore: prefer_initializing_formals
        _readLanguage = readLanguage, // ignore: prefer_initializing_formals
        _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = config.apiBaseUrl
      ..connectTimeout = const Duration(seconds: 15)
      ..sendTimeout = const Duration(seconds: 30)
      ..receiveTimeout = const Duration(seconds: 30)
      ..headers['Accept'] = 'application/json';

    if (dio == null) {
      CertificatePinning.apply(_dio, config.pinnedCertificateSha256);
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Accept-Language'] = _readLanguage();
          final token = await _readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenReader _readToken;
  final LanguageReader _readLanguage;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) =>
      _send(() => _dio.post<dynamic>(path, data: body));

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) =>
      _send(() => _dio.patch<dynamic>(path, data: body));

  /// Envoi d'un fichier en `multipart/form-data`.
  Future<Map<String, dynamic>> upload(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
  }) {
    return _send(
      () => _dio.post<dynamic>(
        path,
        data: FormData.fromMap(<String, dynamic>{field: MultipartFile.fromBytes(bytes, filename: filename)}),
      ),
    );
  }

  Future<void> delete(String path) async {
    await _send(() => _dio.delete<dynamic>(path));
  }

  Future<Map<String, dynamic>> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final data = response.data;
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } on DioException catch (error) {
      throw _toFailure(error);
    }
  }

  ApiFailure _toFailure(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (response == null || data is! Map<String, dynamic>) {
      return ApiFailure(
        code: response == null ? ApiFailure.network : ApiFailure.unknown,
        status: response?.statusCode,
      );
    }

    final rawErrors = data['errors'];
    final fieldErrors = <String, List<String>>{};
    if (rawErrors is Map<String, dynamic>) {
      rawErrors.forEach((field, messages) {
        if (messages is List<dynamic>) {
          fieldErrors[field] = messages.map((message) => message.toString()).toList();
        }
      });
    }

    final retryAfter = data['retry_after'] ?? response.headers.value('retry-after');

    return ApiFailure(
      code: (data['code'] as String?) ?? ApiFailure.unknown,
      message: data['message'] as String?,
      status: response.statusCode,
      retryAfterSeconds: retryAfter == null ? null : int.tryParse(retryAfter.toString()),
      fieldErrors: fieldErrors,
    );
  }
}