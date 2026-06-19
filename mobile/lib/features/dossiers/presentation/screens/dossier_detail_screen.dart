import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/dossiers_provider.dart';
import '../providers/downloaded_docs_provider.dart';
import '../../data/models/dossier_model.dart';

/// Frais officiel par type de démarche (voir [AppConstants]), utilisé en
/// secours quand le dossier n'a pas de `frais` renseigné côté backend.

class DossierDetailScreen extends ConsumerStatefulWidget {
  final String dossierId;
  const DossierDetailScreen({super.key, required this.dossierId});

  @override
  ConsumerState<DossierDetailScreen> createState() => _DossierDetailScreenState();
}

class _DossierDetailScreenState extends ConsumerState<DossierDetailScreen> {
  bool _isDownloading = false;

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité à venir', style: TextStyle(fontFamily: 'Poppins')), behavior: SnackBarBehavior.floating),
    );
  }

  void _showContactModal() {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  alignment: Alignment.center,
                  child: const Text('AG', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Agent état civil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontFamily: 'Poppins')),
                      SizedBox(height: 4),
                      Text('Officier d\'état civil', style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontFamily: 'Poppins')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () { context.pop(); _showComingSoon(); },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message, color: Color(0xFF1D4ED8), size: 20),
                          SizedBox(width: 10),
                          Text('Message', style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () { context.pop(); _showComingSoon(); },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, color: Color(0xFF16A34A), size: 20),
                          SizedBox(width: 10),
                          Text('Appeler', style: TextStyle(color: Color(0xFF16A34A), fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context, String id) async {
    setState(() => _isDownloading = true);
    try {
      final path = await ref.read(downloadCertificateProvider(id).future);
      // Règle métier : un document prêt ne se télécharge qu'une seule fois.
      await ref.read(downloadedDocsProvider.notifier).markDownloaded(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Certificat sauvegardé :\n$path', style: const TextStyle(fontFamily: 'Poppins')), backgroundColor: const Color(0xFF10B981), duration: const Duration(seconds: 5)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e', style: const TextStyle(fontFamily: 'Poppins')), backgroundColor: const Color(0xFFEF4444)),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dossierAsync = ref.watch(dossierDetailProvider(widget.dossierId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: dossierAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0B285D))),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Dossier introuvable', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextButton(onPressed: () => context.pop(), child: const Text('Retour')),
            ],
          ),
        ),
        data: (d) {
          final isDone = d.status == 'pret' || d.status == 'valide';
          final isIncomplete = d.status == 'rejete';
          final fee = d.effectiveFeeFCFA;
          final feeLabel = fee == 0 ? 'Gratuit' : AppFormatters.amountFCFA(fee);
          // Référence réelle du backend (sinon repli sur l'id).
          final reference = d.reference ?? 'SN-${d.id}';
          // Dates réelles des étapes (DossierDetailSerializer).
          final submitted = d.submittedAt ?? d.createdAt;

          Color badgeBg;
          Color badgeText;
          String badgeLabel;
          if (isDone) {
            badgeBg = const Color(0x4010B981); badgeText = const Color(0xFF6EE7B7); badgeLabel = 'VALIDÉ';
          } else if (isIncomplete) {
            badgeBg = const Color(0x40EF4444); badgeText = const Color(0xFFFCA5A5); badgeLabel = 'INCOMPLET';
          } else {
            badgeBg = const Color(0x40F59E0B); badgeText = const Color(0xFFFCD34D); badgeLabel = 'EN COURS';
          }

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ── HEADER BLEU ───────────────────────────────────────
                    Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                        gradient: LinearGradient(colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                      child: Column(
                        children: [
                          // Navigation
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_back, color: Colors.white.withValues(alpha: 0.8), size: 18),
                                    const SizedBox(width: 6),
                                    Text('Mes dossiers', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Info document
                          Row(
                            children: [
                              Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.file_copy_outlined, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(100)),
                                      child: Text(badgeLabel, style: TextStyle(color: badgeText, fontSize: 10, fontWeight: FontWeight.w800, fontFamily: 'Poppins', letterSpacing: 0.5)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(AppFormatters.certTypeLabel(d.type), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Poppins', letterSpacing: -0.3, height: 1.2)),
                                    const SizedBox(height: 4),
                                    Text('$reference · ${d.communeNom ?? 'Mairie'}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontFamily: 'Poppins')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Meta cards
                          Row(
                            children: [
                              Expanded(child: _metaCard('72h', 'Durée')),
                              const SizedBox(width: 8),
                              Expanded(child: _metaCard(feeLabel, 'Coût')),
                              const SizedBox(width: 8),
                              Expanded(child: _metaCard(isDone ? '3/3' : '2/3', 'Étapes')),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── BODY ─────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      child: Column(
                        children: [
                          // Section Informations
                          _sectionCard(
                            icon: Icons.info_outline,
                            title: 'Informations du dossier',
                            child: Column(
                              children: [
                                Row(children: [
                                  Expanded(child: _infoCell('Référence', reference, hasBorder: true)),
                                  Expanded(child: _infoCell('Type', AppFormatters.certTypeLabel(d.type))),
                                ]),
                                Row(children: [
                                  Expanded(child: _infoCell('Soumis le', AppFormatters.dateShort(d.createdAt), hasBorder: true)),
                                  Expanded(child: _infoCell('Statut', AppFormatters.statusLabel(d.status))),
                                ]),
                                Row(children: [
                                  Expanded(child: _infoCell('Mairie', d.communeNom ?? 'N/A', hasBorder: true)),
                                  Expanded(child: _infoCell('Frais', feeLabel)),
                                ]),
                                Row(children: [
                                  Expanded(child: _infoCell('Bénéficiaire', d.beneficiaryNom ?? 'Pour soi-même', hasBorder: true, isLastRow: true)),
                                  Expanded(child: _infoCell('Canal', 'Teranga Civil', isLastRow: true)),
                                ]),
                              ],
                            ),
                          ),

                          // Section Agent assigné
                          _sectionCard(
                            icon: Icons.support_agent,
                            title: 'Agent assigné',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: d.agentNom != null ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                                      border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      d.agentNom != null ? Icons.support_agent : Icons.person_outline,
                                      color: d.agentNom != null ? const Color(0xFF1D4ED8) : const Color(0xFF94A3B8),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.agentNom ?? 'Non encore assigné',
                                          style: TextStyle(
                                            color: d.agentNom != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          d.agentNom != null ? 'Agent en charge du dossier' : 'L\'agent sera visible après prise en charge',
                                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Poppins'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: d.agentNom != null ? _showContactModal : null,
                                        child: Container(width: 36, height: 36, decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle), child: Icon(Icons.message_outlined, size: 16, color: d.agentNom != null ? const Color(0xFF1D4ED8) : const Color(0xFFCBD5E1))),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: d.agentPhone != null ? _showContactModal : null,
                                        child: Container(width: 36, height: 36, decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle), child: Icon(Icons.phone_outlined, size: 16, color: d.agentPhone != null ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1))),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Section Timeline
                          _sectionCard(
                            icon: Icons.timeline,
                            title: 'Suivi de la demande',
                            child: Padding(
                              padding: const EdgeInsets.only(top: 14, bottom: 6),
                              child: Column(
                                children: [
                                  _timelineItem(step: 'Dossier soumis', agent: 'Via Teranga Civil · Système', time: AppFormatters.dateShort(submitted), note: 'Dossier enregistré. Confirmation envoyée par SMS.', isOk: true, isLast: false),
                                  _timelineItem(step: 'Vérification des pièces', agent: d.agentNom ?? 'Agent état civil', time: d.reviewedAt != null ? AppFormatters.dateShort(d.reviewedAt!) : '-', note: d.progress >= 0.5 ? 'Pièces vérifiées et validées.' : 'En attente de vérification.', isOk: d.progress >= 0.5, isLast: false, isErr: isIncomplete),
                                  _timelineItem(step: 'Acte signé et disponible', agent: 'Mairie', time: d.completedAt != null ? AppFormatters.dateShort(d.completedAt!) : '-', note: isDone ? 'Document officiel prêt au téléchargement.' : 'En attente de signature.', isOk: isDone, isLast: true),
                                ],
                              ),
                            ),
                          ),

                          // Section Pièces fournies
                          _sectionCard(
                            icon: Icons.attach_file,
                            title: 'Pièces fournies (${d.documents.length})',
                            child: d.documents.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Icon(Icons.folder_open_outlined,
                                            color: Color(0xFFCBD5E1), size: 28),
                                        SizedBox(height: 8),
                                        Text('Aucune pièce jointe',
                                            style: TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Poppins')),
                                      ],
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Column(
                                      children: d.documents
                                          .map((doc) => _documentRow(doc))
                                          .toList(),
                                    ),
                                  ),
                          ),

                          // ── Boutons d'action ──
                          Column(
                            children: [
                              if (isDone) ...[
                                if (ref.watch(downloadedDocsProvider).contains(d.id))
                                  Container(
                                    width: double.infinity, height: 48,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFFE2E8F0)),
                                    alignment: Alignment.center,
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle, color: Color(0xFF64748B), size: 20),
                                        SizedBox(width: 8),
                                        Text('Acte déjà téléchargé', style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                                      ],
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: () => _download(context, d.id),
                                    child: Container(
                                      width: double.infinity, height: 48,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                                      alignment: Alignment.center,
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.download, color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Text('Télécharger l\'acte officiel', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _showContactModal,
                                      child: Container(height: 48, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center,
                                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.message, color: Color(0xFF1D4ED8), size: 18), SizedBox(width: 6), Text('Contacter l\'agent', style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Poppins'))]),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _showComingSoon,
                                      child: Container(height: 48, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center,
                                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.share, color: Color(0xFF475569), size: 18), SizedBox(width: 6), Text('Partager', style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Poppins'))]),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Prendre rendez-vous (dossier pré-sélectionné)
                              GestureDetector(
                                onTap: () => context.push(
                                    AppRoutes.appointments,
                                    extra: d.id),
                                child: Container(
                                  width: double.infinity,
                                  height: 48,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12)),
                                  alignment: Alignment.center,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.event_rounded,
                                          color: Color(0xFF1D4ED8), size: 18),
                                      SizedBox(width: 8),
                                      Text('Prendre un rendez-vous',
                                          style: TextStyle(
                                              color: Color(0xFF1D4ED8),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Poppins')),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (isIncomplete)
                                GestureDetector(
                                  onTap: _showComingSoon,
                                  child: Container(width: double.infinity, height: 48, decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center,
                                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete, color: Color(0xFF991B1B), size: 18), SizedBox(width: 8), Text('Supprimer le dossier', style: TextStyle(color: Color(0xFF991B1B), fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Poppins'))]),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Overlay téléchargement
              if (_isDownloading)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: Card(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          CircularProgressIndicator(color: Color(0xFF0B285D)),
                          SizedBox(height: 16),
                          Text('Téléchargement...', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _metaCard(String val, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(val, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Poppins', height: 1)),
      const SizedBox(height: 4),
      Text(label.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, fontFamily: 'Poppins')),
    ]),
  );

  Widget _documentRow(DossierDocument doc) {
    final subtitle = [
      if (doc.fileType != null && doc.fileType!.isNotEmpty)
        doc.fileType!.toUpperCase(),
      if (doc.sizeLabel != null) doc.sizeLabel!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: const Icon(Icons.insert_drive_file_outlined,
                color: Color(0xFF1D4ED8), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.description?.isNotEmpty == true
                        ? doc.description!
                        : doc.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins')),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontFamily: 'Poppins')),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
        ],
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required Widget child, bool comingSoon = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
            child: Row(children: [
              Icon(icon, color: const Color(0xFF64748B), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF374151), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5, fontFamily: 'Poppins')),
              ),
              if (comingSoon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(100)),
                  child: const Text('À VENIR', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5, fontFamily: 'Poppins')),
                ),
            ]),
          ),
          child,
        ],
      ),
    );
  }

  Widget _infoCell(String label, String val, {bool hasBorder = false, bool isLastRow = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          right: hasBorder ? const BorderSide(color: Color(0xFFF8FAFC)) : BorderSide.none,
          bottom: isLastRow ? BorderSide.none : const BorderSide(color: Color(0xFFF8FAFC)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Widget _timelineItem({required String step, required String agent, required String time, required String note, required bool isOk, required bool isLast, bool isErr = false}) {
    Color dotColor = const Color(0xFFE2E8F0);
    IconData? dotIcon;
    if (isErr) { dotColor = const Color(0xFFEF4444); dotIcon = Icons.close; }
    else if (isOk) { dotColor = const Color(0xFF10B981); dotIcon = Icons.check; }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 2),
              Container(width: 18, height: 18, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle), child: dotIcon != null ? Icon(dotIcon, size: 12, color: Colors.white) : null),
              if (!isLast) Container(width: 2, height: 88, margin: const EdgeInsets.symmetric(vertical: 4), color: const Color(0xFFE2E8F0)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Poppins', height: 1.3)),
                  const SizedBox(height: 4),
                  Text(agent, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'Poppins')),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(time, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Poppins')),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Text(note, style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.5, fontFamily: 'Poppins')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pieceItem(String num, String name, bool isOk) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC)))),
      child: Row(
        children: [
          Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle), alignment: Alignment.center,
            child: Text(num, style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Poppins'))),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Poppins', height: 1.3))),
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: isOk ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), shape: BoxShape.circle),
            child: Icon(isOk ? Icons.check : Icons.close, size: 14, color: isOk ? const Color(0xFF059669) : const Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }
}
