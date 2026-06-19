import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/backend_commune_select.dart';
import '../../../../../shared/widgets/upload_document_card.dart';
import '../../../../../shared/widgets/certificate_step_indicator.dart';
import '../../../../../shared/models/commune_model.dart';
import '../providers/residence_provider.dart';

/// Formulaire — Certificat de résidence.
///
/// Validité de 3 mois. Le backend exige les pièces `cni_recto`
/// (pièce d'identité) et `attestation_delegue` (attestation du délégué de
/// quartier).
class ResidenceFormScreen extends ConsumerStatefulWidget {
  const ResidenceFormScreen({super.key});

  @override
  ConsumerState<ResidenceFormScreen> createState() =>
      _ResidenceFormScreenState();
}

class _ResidenceFormScreenState extends ConsumerState<ResidenceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtr = TextEditingController();

  BackendCommuneModel? _commune;
  bool _communeError = false;

  String? _pieceIdentite; // CNI / passeport
  String? _attestation; // attestation du délégué de quartier
  String? _copieCni; // copie de la CNI

  @override
  void dispose() {
    _nomCtr.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nomCtr.text.trim().isNotEmpty &&
      _commune != null &&
      _pieceIdentite != null &&
      _attestation != null &&
      _copieCni != null;

  Future<void> _pick(String which) async {
    final path = await DocumentUploadHelper.pick(context);
    if (path == null) return;
    setState(() {
      if (which == 'piece') _pieceIdentite = path;
      if (which == 'attestation') _attestation = path;
      if (which == 'copie_cni') _copieCni = path;
    });
  }

  Future<void> _submit() async {
    if (_commune == null) {
      setState(() => _communeError = true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    try {
      final id = await ref.read(residenceProvider.notifier).submit(
            communeId: _commune!.code,
            nomComplet: _nomCtr.text.trim(),
            pieceIdentitePath: _pieceIdentite,
            attestationDeleguePath: _attestation,
            copieCniPath: _copieCni,
          );
      if (!mounted) return;
      // Comme les autres certificats : on passe par le paiement.
      context.push(AppRoutes.payment, extra: {
        'dossier_id': id,
        'type': 'residence',
        'montant': AppConstants.residenceFeesFCFA,
        'label': 'Certificat de résidence',
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is Failure ? e.message : 'Une erreur est survenue.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(residenceProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Certificat de résidence'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const CertificateStepIndicator(currentStep: CertStep.formulaire),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  onChanged: () => setState(() {}),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bandeau validité 3 mois
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statusBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.statusBlue.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppColors.statusBlue, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Ce certificat a une validité de 3 mois.',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.statusBlue),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Demandeur
                      AppTextField(
                        label: 'Nom complet du demandeur',
                        hint: 'Ex: Awa Ndiaye',
                        controller: _nomCtr,
                        validator: Validators.fullName,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.person_outline,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(height: 20),

                      Text('Commune de résidence',
                          style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 4),
                      Text('Commune où vous résidez actuellement',
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: 12),
                      BackendCommuneSelect(
                        onChanged: (region, commune) => setState(() {
                          _commune = commune;
                          if (commune != null) _communeError = false;
                        }),
                        errorText: _communeError
                            ? 'Veuillez sélectionner une commune.'
                            : null,
                      ),
                      const SizedBox(height: 28),

                      // Documents
                      Text('Pièces justificatives',
                          style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 4),
                      Text('Obligatoires pour traiter votre demande',
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: 14),

                      UploadDocumentCard(
                        title: 'Pièce d\'identité',
                        subtitle: 'CNI, passeport ou permis (recto)',
                        icon: Icons.credit_card_outlined,
                        filePath: _pieceIdentite,
                        isRequired: true,
                        onTap: () => _pick('piece'),
                        onRemove: _pieceIdentite != null
                            ? () => setState(() => _pieceIdentite = null)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      UploadDocumentCard(
                        title: 'Attestation du délégué de quartier',
                        subtitle: 'Document signé par le délégué de quartier',
                        icon: Icons.assignment_outlined,
                        filePath: _attestation,
                        isRequired: true,
                        onTap: () => _pick('attestation'),
                        onRemove: _attestation != null
                            ? () => setState(() => _attestation = null)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      UploadDocumentCard(
                        title: 'Copie de la CNI',
                        subtitle: 'Photocopie lisible de votre CNI',
                        icon: Icons.badge_outlined,
                        filePath: _copieCni,
                        isRequired: true,
                        onTap: () => _pick('copie_cni'),
                        onRemove: _copieCni != null
                            ? () => setState(() => _copieCni = null)
                            : null,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: 'Envoyer la demande',
                onPressed: _submit,
                isEnabled: _isValid,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
