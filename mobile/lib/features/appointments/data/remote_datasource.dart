import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/exceptions.dart';
import 'models/appointment_model.dart';

/// Accès API rendez-vous : `/api/appointments/` (ViewSet DRF).
/// - GET  /appointments/            -> liste des RDV du citoyen connecté
/// - POST /appointments/  {dossier_id, reason} -> crée une demande (pending)
class AppointmentsRemoteDatasource {
  final DioClient client;
  const AppointmentsRemoteDatasource({required this.client});

  Future<List<AppointmentModel>> getAppointments() async {
    final res = await client.get('/appointments/');
    if (res.statusCode == 200 && res.data != null) {
      final body = res.data;
      // Réponse paginée standard : {success, message, data: {results: [...]}}
      final data = (body is Map<String, dynamic>) ? body['data'] : null;
      final list = (data is Map<String, dynamic>) ? data['results'] : body;
      if (list is List) {
        return list
            .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw const ApiException(message: 'Impossible de charger les rendez-vous');
  }

  /// Crée une demande de rendez-vous pour un dossier du citoyen.
  /// Le backend refuse si le dossier ne lui appartient pas.
  Future<AppointmentModel> createAppointment({
    required String dossierId,
    required String reason,
  }) async {
    try {
      final res = await client.post('/appointments/', data: {
        'dossier_id': dossierId,
        'reason': reason,
      });
      final body = res.data;
      final inner = (body is Map<String, dynamic>) ? body['data'] : null;
      if (inner is Map<String, dynamic>) {
        return AppointmentModel.fromJson(inner);
      }
      if (body is Map<String, dynamic>) {
        return AppointmentModel.fromJson(body);
      }
      throw const ApiException(message: 'Réponse invalide du serveur');
    } on DioException catch (e) {
      throw ApiException(message: _extractError(e.response?.data) ??
          'Impossible de créer le rendez-vous');
    }
  }

  String? _extractError(dynamic data) {
    if (data is Map<String, dynamic>) {
      final msg = data['message'] ?? data['detail'];
      if (msg is String && msg.isNotEmpty) return msg;
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
    }
    return null;
  }
}
