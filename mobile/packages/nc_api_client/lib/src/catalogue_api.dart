import 'package:nc_core/nc_core.dart';

import 'api_client.dart';

/// Catalogue des soins. Public côté serveur : il se lit sans jeton.
abstract interface class CatalogueApi {
  Future<List<CareCategory>> categories();

  /// Services d'une catégorie, ou résultat d'une recherche (nom et description,
  /// dans les trois langues, sans tenir compte des accents).
  Future<List<CareService>> services({String? categorySlug, String? query});

  Future<CareService> service(String slug);
}

class HttpCatalogueApi implements CatalogueApi {
  const HttpCatalogueApi(this._client);

  final ApiClient _client;

  static List<Map<String, dynamic>> _list(Map<String, dynamic> json) {
    return ((json['data'] as List<dynamic>?) ?? const <dynamic>[]).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<CareCategory>> categories() async {
    return _list(await _client.get('/catalogue/categories')).map(CareCategory.fromJson).toList();
  }

  @override
  Future<List<CareService>> services({String? categorySlug, String? query}) async {
    final json = await _client.get(
      '/catalogue/services',
      query: <String, dynamic>{'category': ?categorySlug, 'q': ?query},
    );
    return _list(json).map(CareService.fromJson).toList();
  }

  @override
  Future<CareService> service(String slug) async {
    final json = await _client.get('/catalogue/services/${Uri.encodeComponent(slug)}');
    return CareService.fromJson(json['data'] as Map<String, dynamic>);
  }
}
