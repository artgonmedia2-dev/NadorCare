/// Application qui parle à l'API. La valeur est envoyée telle quelle au serveur.
enum ClientApp {
  patient('patient'),
  pro('pro');

  const ClientApp(this.apiValue);

  final String apiValue;
}