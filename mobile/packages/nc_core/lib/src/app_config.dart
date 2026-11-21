import 'client_app.dart';

/// Configuration fournie à la compilation par `--dart-define`. Aucun secret ici :
/// l'adresse de l'API et les empreintes de certificat sont publiques par nature.
class AppConfig {
  const AppConfig({
    required this.clientApp,
    required this.apiBaseUrl,
    this.pinnedCertificateSha256 = const <String>[],
  });

  /// Lit `API_BASE_URL` et `API_CERT_SHA256` (empreintes séparées par des virgules).
  /// Par défaut : l'API locale vue depuis un émulateur Android.
  factory AppConfig.fromEnvironment(ClientApp clientApp) {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000/api/v1',
    );
    const pins = String.fromEnvironment('API_CERT_SHA256');

    return AppConfig(
      clientApp: clientApp,
      apiBaseUrl: baseUrl,
      pinnedCertificateSha256: pins
          .split(',')
          .map((pin) => pin.trim().toLowerCase().replaceAll(':', ''))
          .where((pin) => pin.isNotEmpty)
          .toList(growable: false),
    );
  }

  final ClientApp clientApp;
  final String apiBaseUrl;

  /// Empreintes SHA-256 des certificats acceptés. Vide en développement :
  /// l'épinglage s'active dès qu'au moins une empreinte est fournie.
  final List<String> pinnedCertificateSha256;
}