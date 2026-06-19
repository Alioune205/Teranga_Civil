import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../notifications.dart';

({IconData icon, Color color}) _notifVisual(String title) {
  final t = title.toLowerCase();
  if (t.contains('disponible') || t.contains('prêt') || t.contains('pret')) {
    return (icon: Icons.check_circle_outline, color: const Color(0xFF10B981));
  }
  if (t.contains('approuv') || t.contains('valid')) {
    return (icon: Icons.verified_outlined, color: const Color(0xFF10B981));
  }
  if (t.contains('vérification') ||
      t.contains('verification') ||
      t.contains('traitement') ||
      t.contains('cours')) {
    return (icon: Icons.hourglass_top_outlined, color: const Color(0xFFF59E0B));
  }
  if (t.contains('rejet') || t.contains('action requise')) {
    return (icon: Icons.cancel_outlined, color: const Color(0xFFEF4444));
  }
  return (icon: Icons.inbox_outlined, color: const Color(0xFF3B82F6));
}

String _relativeTime(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

/// Page pleine écran des notifications (remplace l'ancienne bottom sheet).
/// Accessible depuis l'accueil et depuis « Mes dossiers ».
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── En-tête : retour + titre + rafraîchir ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Color(0xFF0F172A)),
                  ),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.invalidate(notificationsProvider),
                    icon: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF0B285D)),
                    tooltip: 'Rafraîchir',
                  ),
                ],
              ),
            ),
            // ── Onglets Tous / Non lus + Tout marquer comme lu ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  _tab('Tous', !_unreadOnly,
                      () => setState(() => _unreadOnly = false)),
                  const SizedBox(width: 8),
                  _tab('Non lus', _unreadOnly,
                      () => setState(() => _unreadOnly = true)),
                  const Spacer(),
                  notifsAsync.maybeWhen(
                    data: (list) {
                      final unread = list.where((n) => !n.isRead).length;
                      if (unread == 0) return const SizedBox.shrink();
                      return TextButton(
                        onPressed: () async {
                          await ref
                              .read(notificationsDatasourceProvider)
                              .markAllRead();
                          ref.invalidate(notificationsProvider);
                        },
                        child: const Text(
                          'Tout marquer lu',
                          style: TextStyle(
                            color: Color(0xFF0B285D),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: notifsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0B285D)),
                ),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Impossible de charger les notifications.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(notificationsProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
                data: (list) {
                  final filtered =
                      _unreadOnly ? list.where((n) => !n.isRead).toList() : list;
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 34,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _unreadOnly
                                ? 'Aucune notification non lue'
                                : 'Aucune notification',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: const Color(0xFF0B285D),
                    onRefresh: () async => ref.invalidate(notificationsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final n = filtered[i];
                        final v = _notifVisual(n.title);
                        return GestureDetector(
                          onTap: () => _openNotification(context, n),
                          child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: n.isRead
                                ? Colors.white
                                : const Color(0xFFF5F8FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: n.isRead
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFFBFD4FF),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: v.color.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(v.icon, color: v.color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      n.body,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (n.createdAt != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        _relativeTime(n.createdAt),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!n.isRead)
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin:
                                      const EdgeInsets.only(left: 8, top: 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0B285D),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre la cible d'une notification : le dossier concerné si on a son id
  /// (pour télécharger le document), sinon la liste des dossiers pour une
  /// notification « document disponible ».
  void _openNotification(BuildContext context, NotificationModel n) {
    final id = n.relatedDossierId;
    if (id != null && id.isNotEmpty) {
      context.push(AppRoutes.dossierDetailPath(id));
      return;
    }
    final t = n.title.toLowerCase();
    if (t.contains('disponible') || t.contains('prêt') || t.contains('pret')) {
      context.push(AppRoutes.dossiers);
    }
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0B285D) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
