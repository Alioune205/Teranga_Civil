import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/dossier_model.dart';
import '../providers/dossiers_provider.dart';
import '../providers/downloaded_docs_provider.dart';

class DossiersListScreen extends ConsumerStatefulWidget {
  const DossiersListScreen({super.key});

  @override
  ConsumerState<DossiersListScreen> createState() => _DossiersListScreenState();
}

class _DossiersListScreenState extends ConsumerState<DossiersListScreen> {
  String _selectedFilter = 'Tous';
  final ScrollController _scrollController = ScrollController();

  final List<String> _filters = ['Tous', 'En cours', 'Validés', 'Incomplets'];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isDone(String s) => s == 'pret' || s == 'valide';
  bool _isIncomplete(String s) => s == 'rejete';

  @override
  Widget build(BuildContext context) {
    final dossiersAsync = ref.watch(dossiersListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: dossiersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0B285D))),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_outlined, size: 64, color: Color(0xFF94A3B8)),
              const SizedBox(height: 16),
              const Text('Impossible de charger', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(dossiersListProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (dossiers) {
          final total = dossiers.length;
          final termines = dossiers.where((d) => _isDone(d.status)).length;
          final enCours = dossiers.where((d) => !_isDone(d.status) && !_isIncomplete(d.status)).length;
          final incomplets = dossiers.where((d) => _isIncomplete(d.status)).length;

          final filtered = dossiers.where((d) {
            switch (_selectedFilter) {
              case 'En cours':   return !_isDone(d.status) && !_isIncomplete(d.status);
              case 'Validés':    return _isDone(d.status);
              case 'Incomplets': return _isIncomplete(d.status);
              default:           return true;
            }
          }).toList();

          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── HEADER BLEU ───────────────────────────────────────
                    Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        gradient: LinearGradient(
                          colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mes dossiers',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Poppins',
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Dernière mise à jour · aujourd\'hui',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  _hdrBtn(Icons.event_rounded,
                                      onTap: () => context
                                          .push(AppRoutes.appointments)),
                                  const SizedBox(width: 10),
                                  _hdrBtn(Icons.notifications_none,
                                      onTap: () => context
                                          .push(AppRoutes.notifications)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Stats
                          Row(
                            children: [
                              Expanded(child: _statCard('Total', total, Colors.white.withValues(alpha: 0.1), Colors.white, Colors.white.withValues(alpha: 0.6))),
                              const SizedBox(width: 8),
                              Expanded(child: _statCard('Validés', termines, const Color(0x3310B981), const Color(0xFF6EE7B7), const Color(0x996EE7B7))),
                              const SizedBox(width: 8),
                              Expanded(child: _statCard('En cours', enCours, const Color(0x33F59E0B), const Color(0xFFFCD34D), const Color(0x99FCD34D))),
                              const SizedBox(width: 8),
                              Expanded(child: _statCard('Incomplet', incomplets, const Color(0x33EF4444), const Color(0xFFFCA5A5), const Color(0x99FCA5A5))),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── FILTRES ───────────────────────────────────────────
                    Container(
                      color: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      height: 66,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final f = _filters[i];
                          final sel = _selectedFilter == f;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedFilter = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: sel ? const LinearGradient(colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
                                color: sel ? null : Colors.white,
                                borderRadius: BorderRadius.circular(100),
                                border: sel ? null : Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(f, style: TextStyle(color: sel ? Colors.white : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Compteur ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${filtered.length} dossier${filtered.length > 1 ? 's' : ''} · triés par date',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(100)),
                            child: const Row(
                              children: [
                                Icon(Icons.swap_vert, size: 14, color: Color(0xFF0B285D)),
                                SizedBox(width: 4),
                                Text('Récents', style: TextStyle(color: Color(0xFF0B285D), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── LISTE ─────────────────────────────────────────────────
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_outlined, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('Aucun dossier trouvé', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DossierCard(dossier: filtered[i]),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _hdrBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _statCard(String label, int count, Color bg, Color num, Color lbl) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text('$count', style: TextStyle(color: num, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Poppins', height: 1)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(), style: TextStyle(color: lbl, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte dossier
// ─────────────────────────────────────────────────────────────────────────────
class _DossierCard extends ConsumerWidget {
  final DossierModel dossier;
  const _DossierCard({required this.dossier});

  bool get _isDone => dossier.status == 'pret' || dossier.status == 'valide';
  bool get _isIncomplete => dossier.status == 'rejete';
  bool get _isEnCours => !_isDone && !_isIncomplete;

  /// Télécharge le certificat PDF du dossier (web/natif via downloadCertificate).
  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
      content: Text('Téléchargement en cours…'),
      duration: Duration(seconds: 1),
    ));
    try {
      final path =
          await ref.read(downloadCertificateProvider(dossier.id).future);
      // Règle métier : un document prêt ne se télécharge qu'une seule fois.
      await ref.read(downloadedDocsProvider.notifier).markDownloaded(dossier.id);
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Certificat téléchargé : $path'),
          backgroundColor: const Color(0xFF10B981),
        ));
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Échec du téléchargement.'),
          backgroundColor: Color(0xFFEF4444),
        ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Couleurs selon statut
    final Color borderColor;
    final Color badgeBg;
    final Color badgeText;
    final String badgeLabel;
    final Color iconBg;
    final Color iconColor;

    if (_isDone) {
      borderColor = const Color(0xFFBFDBFE);
      badgeBg = const Color(0xFFD1FAE5);
      badgeText = const Color(0xFF065F46);
      badgeLabel = 'VALIDÉ';
      iconBg = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF475569);
    } else if (_isIncomplete) {
      borderColor = const Color(0xFFFECACA);
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFF991B1B);
      badgeLabel = 'INCOMPLET';
      iconBg = const Color(0xFFFEF2F2);
      iconColor = const Color(0xFFDC2626);
    } else {
      borderColor = const Color(0xFFFDE68A);
      badgeBg = const Color(0xFFFEF9C3);
      badgeText = const Color(0xFF92400E);
      badgeLabel = 'EN COURS';
      iconBg = const Color(0xFFFFF7ED);
      iconColor = const Color(0xFFEA580C);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: _isDone ? 1.0 : 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.file_copy_outlined, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppFormatters.certTypeLabel(dossier.type),
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Poppins', height: 1.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#SN-${dossier.id.length > 8 ? dossier.id.substring(0, 8) : dossier.id} · ${dossier.communeNom ?? 'Mairie'}',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontFamily: 'Poppins'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(100)),
                      child: Text(badgeLabel, style: TextStyle(color: badgeText, fontSize: 10, fontWeight: FontWeight.w800, fontFamily: 'Poppins', letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 6),
                    Text(AppFormatters.dateShort(dossier.createdAt), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),

          // ── Stepper de progression ──
          if (!_isDone)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DossierProgressStepper(currentStatus: dossier.status),
                  if (_isIncomplete) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text('Action requise — pièce manquante', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          // ── Chips ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (_isIncomplete)
                  _chip(Icons.warning_amber, 'Action requise', color: const Color(0xFFDC2626), bg: const Color(0xFFFEF2F2), border: const Color(0xFFFECACA))
                else
                  _chip(Icons.access_time, _isDone ? 'Terminé' : '~2 j restants'),
                _chip(
                    Icons.paid_outlined,
                    dossier.effectiveFeeFCFA == 0
                        ? 'Gratuit'
                        : AppFormatters.amountFCFA(dossier.effectiveFeeFCFA)),
                if (dossier.beneficiaryNom != null)
                  _chip(Icons.person_outline, dossier.beneficiaryNom!.split(' ').last),
              ],
            ),
          ),

          // ── Séparateur ──
          Container(height: 1.0, color: const Color(0xFFF1F5F9), margin: const EdgeInsets.symmetric(horizontal: 16)),

          // ── Actions ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (_isDone) ...[
                  Expanded(
                    child: ref.watch(downloadedDocsProvider).contains(dossier.id)
                        ? _actionBtn('Déjà téléchargé', Icons.check_circle,
                            const Color(0xFFE2E8F0), const Color(0xFF64748B))
                        : GestureDetector(
                            onTap: () => _download(context, ref),
                            child: _actionBtn('Télécharger', Icons.download,
                                null, Colors.white, useGradient: true),
                          ),
                  ),
                ],
                if (_isIncomplete) ...[
                  Expanded(child: _actionBtn('Supprimer', Icons.delete_outline, Colors.white, const Color(0xFF475569), border: const Color(0xFFE2E8F0))),
                  const SizedBox(width: 8),
                  Expanded(child: _actionBtn('Corriger', Icons.refresh, const Color(0xFFDC2626), Colors.white)),
                ],
                if (_isEnCours) ...[
                  Expanded(child: _actionBtn('Relancer', Icons.phone, const Color(0xFFFEF9C3), const Color(0xFF92400E))),
                  const SizedBox(width: 8),
                  Expanded(child: _actionBtn('Contacter', Icons.message, Colors.white, const Color(0xFF475569), border: const Color(0xFFE2E8F0))),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.dossierDetailPath(dossier.id)),
                    child: Container(
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_red_eye, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Détail', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, {Color color = const Color(0xFF64748B), Color bg = const Color(0xFFF8FAFC), Color border = const Color(0xFFE2E8F0)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color? bg, Color text, {Color? border, bool useGradient = false}) {
    return Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: useGradient ? null : bg,
        gradient: useGradient ? const LinearGradient(colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
        borderRadius: BorderRadius.circular(100),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}
