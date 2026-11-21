/// Erreur renvoyée par l'API au format `{ message, code, ... }`, ou erreur de transport.
///
/// [code] est stable et sert aux décisions de l'application ; [message] est déjà
/// traduit par le serveur dans la langue demandée, et peut être affiché tel quel.
class ApiFailure implements Exception {
  const ApiFailure({
    required this.code,
    this.message,
    this.status,
    this.retryAfterSeconds,
    this.fieldErrors = const <String, List<String>>{},
  });

  /// Pas de réponse du serveur : réseau coupé, délai dépassé, certificat refusé.
  static const String network = 'network_error';
  static const String unknown = 'unknown_error';
  static const String unauthenticated = 'unauthenticated';
  static const String validationFailed = 'validation_failed';
  static const String consentRequired = 'consent_required';
  static const String otpInvalid = 'otp_invalid';
  static const String otpLocked = 'otp_locked';
  static const String otpTooSoon = 'otp_too_soon';
  static const String accountSuspended = 'account_suspended';
  static const String tooManyRequests = 'too_many_requests';

  final String code;
  final String? message;
  final int? status;
  final int? retryAfterSeconds;
  final Map<String, List<String>> fieldErrors;

  bool get isNetwork => code == network;

  /// Premier message de validation d'un champ, s'il y en a un.
  String? firstErrorFor(String field) {
    final errors = fieldErrors[field];
    return (errors == null || errors.isEmpty) ? null : errors.first;
  }

  @override
  String toString() => 'ApiFailure($code, status: $status)';
}