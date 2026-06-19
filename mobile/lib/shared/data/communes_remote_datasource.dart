import '../../core/network/dio_client.dart';
import '../../core/errors/exceptions.dart';
import '../models/commune_model.dart';

/// Datasource pour la liste des communes côté backend (`GET /communes/`).
///
/// Endpoint public (AllowAny), paginé via le format standard
/// `{success, message, data: {results: [...], next, ...}, errors}`.
class CommunesRemoteDatasource {
  final DioClient client;
  const CommunesRemoteDatasource({required this.client});

  /// Récupère toutes les communes (en suivant la pagination si nécessaire).
  Future<List<BackendCommuneModel>> getCommunes() async {
    final results = <BackendCommuneModel>[];
    String path = '/communes/';
    Map<String, dynamic>? query = {'page_size': 100};

    while (path.isNotEmpty) {
      final res = await client.get(path, queryParameters: query);
      query = null; // les liens "next" embarquent déjà leurs query params

      if (res.statusCode != 200 || res.data == null) {
        throw const ApiException(message: 'Impossible de charger les communes');
      }

      final body = res.data;
      final data = (body is Map<String, dynamic>) ? body['data'] : null;
      final list = (data is Map<String, dynamic>) ? data['results'] : body;
      if (list is List) {
        results.addAll(
          list.map((e) => BackendCommuneModel.fromJson(e as Map<String, dynamic>)),
        );
      }

      final next = (data is Map<String, dynamic>) ? data['next'] as String? : null;
      if (next == null || next.isEmpty) break;
      // `next` est une URL absolue ; on n'en garde que le chemin + la query.
      final uri = Uri.parse(next);
      path = uri.path.replaceFirst(RegExp(r'^/api'), '');
      query = uri.queryParameters;
    }

    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }
}
