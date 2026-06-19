import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/recap_card.dart';
import '../../../../../shared/widgets/certificate_step_indicator.dart';
import '../providers/deces_provider.dart';

/// Traduit une erreur technique (Dio, API) en message lisible pour
/// l'utilisateur lors de la soumission du dossier.
String _friendlyError(Object e) {
  if (e is ApiException) return e.message;
  if (e is DioException) {
    final inner = e.error;
    if (inner is ApiException) return inner.message;
    if (inner is UnauthorizedException) return inner.message;
    if (inner is ForbiddenException) return inner.message;
    if (inner is NotFoundException) return inner.message;
    if (inner is ServerException) return inner.message;
    if (inner is NetworkException) return inner.message;
    if (inner is TimeoutException) return inner.message;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La requête a expiré. Vérifiez votre connexion.';
      case DioExceptionType.connectionError:
        return 'Pas de connexion internet.';
      default:
        return 'Une erreur est survenue. Veuillez réessayer.';
    }
  }
  return 'Une erreur est survenue. Veuillez réessayer.';
}

/// S09A — Récapitulatif décès (refonte complète)
class DecesRecapScreen extends ConsumerWidget {
  final Map<String, dynamic> formData;
  const DecesRecapScreen({super.key, required this.formData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(decesProvider).isLoading;

    final dateDeces = DateTime.tryParse(
            formData['date_deces'] as String? ?? '') ??
        DateTime.now();

    final docRecto  = formData['doc_recto'] as String?;
    final docVerso  = formData['doc_verso'] as String?;
    final typeDoc   = formData['type_doc'] as String? ?? 'cni';
    final docLabel  = _docTypeLabel(typeDoc);

    Future<void> submit() async {
      try {
        final id = await ref.read(decesProvider.notifier).submit(
              communeId:    formData['commune_id'] as String,
              nomDefunt:    formData['nom'] as String,
              dateDeces:    dateDeces,
              registre:     formData['registre'] as String,
              nomDeclarant: formData['nom_declarant'] as String,
              lienParente:  formData['lien_parente'] as String,
              docRectoPath: docRecto,
              docVersoPath: docVerso,
            );
        if (!context.mounted) return;
        context.push(AppRoutes.payment, extra: {
          'dossier_id': id,
          'type': 'deces',
          'montant': AppConstants.decesFeesFCFA,
          'label': 'Certificat de décès',
        });
      } catch (e) {
        if (!context.mounted) return;
        // Affichage différé : si le SnackBar est déclenché juste après
        // la mise à jour de l'état isLoading, l'appel peut être
        // silencieusement ignoré.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(
              content: Text(_friendlyError(e)),
              backgroundColor: AppColors.error,
            ));
        });
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Récapitulatif'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Modifier'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const CertificateStepIndicator(currentStep: CertStep.recap),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vérifiez vos informations',
                        style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                        'Assurez-vous que tout est correct avant de payer',
                        style: AppTextStyles.bodySmall),
                    const SizedBox(height: 24),

                    // ── Section défunt ──────────────────────────
                    _SectionHeader(
                      icon: Icons.person_off_outlined,
                      label: 'Défunt',
                      color: AppColors.statusRed,
                    ),
                    const SizedBox(height: 10),
                    RecapCard(
                      title: 'Informations du défunt',
                      accentColor: AppColors.statusRed,
                      titleIcon: Icons.person_off_outlined,
                      fields: [
                        RecapField(
                          label: 'Nom du défunt',
                          value: formData['nom'] as String,
                          icon: Icons.person_outline,
                        ),
                        RecapField(
                          label: 'Date de décès',
                          value: AppFormatters.dateToFrench(dateDeces),
                          icon: Icons.calendar_today_outlined,
                        ),
                        RecapField(
                          label: 'N° de registre',
                          value: formData['registre'] as String,
                          icon: Icons.badge_outlined,
                        ),
                        RecapField(
                          label: 'Commune',
                          value:
                              '${formData['commune_nom']} — ${formData['region_nom']}',
                          icon: Icons.location_on_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Section déclarant ───────────────────────
                    _SectionHeader(
                      icon: Icons.account_circle_outlined,
                      label: 'Déclarant',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    RecapCard(
                      title: 'Informations du déclarant',
                      accentColor: AppColors.primary,
                      titleIcon: Icons.account_circle_outlined,
                      fields: [
                        RecapField(
                          label: 'Nom complet',
                          value: formData['nom_declarant'] as String,
                          icon: Icons.person_outline,
                        ),
                        RecapField(
                          label: 'Lien avec le défunt',
                          value: formData['lien_parente'] as String,
                          icon: Icons.people_outline,
                          valueColor: AppColors.statusBlue,
                        ),
                        RecapField(
                          label: 'Frais',
                          value: AppFormatters.amountFCFA(
                              AppConstants.decesFeesFCFA),
                          icon: Icons.payment_outlined,
                          valueColor: AppColors.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Documents joints ────────────────────────
                    if (docRecto != null) ...[
                      _SectionHeader(
                        icon: typeDoc == 'extrait'
                            ? Icons.article_outlined
                            : Icons.credit_card_outlined,
                        label: docLabel,
                        color: AppColors.statusBlue,
                      ),
                      const SizedBox(height: 10),
                      _DocThumb(
                        path: docRecto,
                        label: typeDoc == 'extrait'
                            ? 'Extrait de naissance'
                            : 'Pièce d\'identité — Recto',
                      ),
                      if (docVerso != null) ...[
                        const SizedBox(height: 8),
                        _DocThumb(
                            path: docVerso,
                            label: 'Pièce d\'identité — Verso'),
                      ],
                      const SizedBox(height: 20),
                    ],

                    // ── Mise en garde ───────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.statusBlue.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                AppColors.statusBlue.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: AppColors.statusBlue, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Votre demande sera traitée par le centre d\'état civil '
                              'compétent. Un email de confirmation vous sera envoyé.',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.statusBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Sticky bouton ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: 'Confirmer et payer — '
                    '${AppFormatters.amountFCFA(AppConstants.decesFeesFCFA)}',
                onPressed: submit,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _docTypeLabel(String key) {
    return key == 'extrait' ? 'Extrait de naissance' : 'Pièce d\'identité';
  }
}

// ── En-tête de section ────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text(label,
          style: AppTextStyles.headlineSmall.copyWith(color: color)),
      const SizedBox(width: 8),
      Expanded(
        child: Divider(
            color: color.withValues(alpha: 0.3), thickness: 1),
      ),
    ]);
  }
}

// ── Miniature document ────────────────────────────────────────
class _DocThumb extends StatelessWidget {
  final String path;
  final String label;
  const _DocThumb({required this.path, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(path),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: AppColors.background,
                child: const Icon(Icons.insert_drive_file_outlined,
                    color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.labelMedium)),
          const Icon(Icons.check_circle,
              color: AppColors.secondary, size: 18),
        ],
      ),
    );
  }
}
