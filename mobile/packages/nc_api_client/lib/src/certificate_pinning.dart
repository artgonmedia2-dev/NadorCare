import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Épinglage de certificat (cahier des charges §10) : la connexion est refusée si le
/// certificat présenté par le serveur ne correspond à aucune empreinte attendue,
/// même s'il est signé par une autorité reconnue.
class CertificatePinning {
  const CertificatePinning._();

  /// Sans empreinte, rien ne change : c'est le cas en développement.
  static void apply(Dio dio, List<String> sha256Fingerprints) {
    if (sha256Fingerprints.isEmpty) {
      return;
    }

    dio.httpClientAdapter = IOHttpClientAdapter(
      validateCertificate: (X509Certificate? certificate, String host, int port) {
        return certificate != null && matches(certificate.der, sha256Fingerprints);
      },
    );
  }

  /// Compare l'empreinte SHA-256 du certificat (format DER) aux empreintes attendues.
  static bool matches(List<int> certificateDer, List<String> sha256Fingerprints) {
    final fingerprint = sha256.convert(certificateDer).toString();
    return sha256Fingerprints.any(
      (expected) => expected.toLowerCase().replaceAll(':', '') == fingerprint,
    );
  }
}