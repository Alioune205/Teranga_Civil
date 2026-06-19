import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';

/// Notification telle que renvoyée par le backend (`GET /api/notifications/`).
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;
  final String? relatedDossierId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
    this.relatedDossierId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        body: (json['body'] ?? json['message']) as String? ?? '',
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
        relatedDossierId: json['related_dossier_id'] as String?,
      );
}

/// On ne montre au citoyen que les notifications « utiles » : sa demande
/// **prête** (document disponible) ou **rejetée** (action requise). Les étapes
/// intermédiaires créées par le backend (reçu, en cours, approuvé) sont
/// masquées côté mobile.
bool _isRelevantNotification(NotificationModel n) {
  final t = n.title.toLowerCase();
  final ready = t.contains('disponible') || t.contains('prêt') || t.contains('pret');
  final rejected = t.contains('rejet') || t.contains('action requise');
  return ready || rejected;
}

class NotificationsRemoteDatasource {
  final DioClient client;
  const NotificationsRemoteDatasource({required this.client});

  Future<List<NotificationModel>> getNotifications() async {
    final res = await client.get('/notifications/',
        queryParameters: {'page_size': 50});
    final body = res.data;
    final data = (body is Map<String, dynamic>) ? body['data'] : null;
    final list = (data is Map<String, dynamic>)
        ? data['results']
        : (body is List ? body : null);
    if (list is List) {
      return list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .where(_isRelevantNotification)
          .toList();
    }
    return const [];
  }

  /// Marque toutes les notifications comme lues (best-effort).
  Future<void> markAllRead() async {
    try {
      await client.post('/notifications/mark-all-read/');
    } catch (_) {/* non bloquant */}
  }
}

/// Liste des notifications (auto-rafraîchie à chaque ouverture de l'écran).
final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final ds = NotificationsRemoteDatasource(client: ref.read(dioClientProvider));
  return ds.getNotifications();
});

/// Nombre de notifications non lues (pour le badge de la cloche).
final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

final notificationsDatasourceProvider =
    Provider.autoDispose<NotificationsRemoteDatasource>((ref) =>
        NotificationsRemoteDatasource(client: ref.read(dioClientProvider)));
