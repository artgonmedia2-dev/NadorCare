/// Accès à la salle vidéo d'une téléconsultation, délivré par le serveur.
class VideoAccess {
  const VideoAccess({
    required this.provider,
    required this.room,
    required this.token,
    required this.isHost,
    required this.expiresAt,
    this.serverUrl,
  });

  factory VideoAccess.fromJson(Map<String, dynamic> json) {
    return VideoAccess(
      provider: (json['provider'] as String?) ?? fakeProvider,
      room: (json['room'] as String?) ?? '',
      token: (json['token'] as String?) ?? '',
      serverUrl: json['server_url'] as String?,
      isHost: (json['is_host'] as bool?) ?? false,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  /// Pilote factice du serveur : aucun vrai appel, l'application montre un appel simulé.
  static const String fakeProvider = 'fake';

  /// Prestataire vidéo ; l'écran d'appel choisit son module d'après lui.
  final String provider;
  final String room;

  /// Jeton propre au participant, à durée limitée.
  final String token;
  final String? serverUrl;

  /// Vrai pour le professionnel, qui ouvre et ferme l'appel.
  final bool isHost;
  final DateTime expiresAt;

  bool get isSimulated => provider == fakeProvider;
}
