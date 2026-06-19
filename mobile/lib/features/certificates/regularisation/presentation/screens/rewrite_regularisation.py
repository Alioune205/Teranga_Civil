import os
import re

content = '''import 'package:flutter/material.dart';
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
import '../providers/regularisation_provider.dart';

class RegularisationFormScreen extends ConsumerStatefulWidget {
  const RegularisationFormScreen({super.key});

  @override
  ConsumerState<RegularisationFormScreen> createState() =>
      _RegularisationFormScreenState();
}

class _RegularisationFormScreenState extends ConsumerState<RegularisationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtr = TextEditingController();
  final _cniCtr = TextEditingController();
  final _telCtr = TextEditingController();
  final _localisationCtr = TextEditingController();

  BackendCommuneModel? _commune;
  bool _communeError = false;

  String? _demandeMaire; 
  String? _pieceIdentite; 
  String? _acteTerrain; 

  @override
  void dispose() {
    _nomCtr.dispose();
    _cniCtr.dispose();
    _telCtr.dispose();
    _localisationCtr.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nomCtr.text.trim().isNotEmpty &&
      _cniCtr.text.trim().isNotEmpty &&
      _telCtr.text.trim().isNotEmpty &&
      _localisationCtr.text.trim().isNotEmpty &&
      _commune != null &&
      _demandeMaire != null &&
      _pieceIdentite != null &&
      _acteTerrain != null;

  Future<void> _pick(String which) async {
    final path = await DocumentUploadHelper.pick(context);
    if (path == null) return;
    setState(() {
      if (which == 'demande') _demandeMaire = path;
      if (which == 'piece') _pieceIdentite = path;
      if (which == 'acte') _acteTerrain = path;
    });
  }

  Future<void> _submit() async {
    if (_commune == null) {
      setState(() => _communeError = true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    try {
      final id = await ref.read(regularisationProvider.notifier).submit(
            communeId: _commune!.code,
            nomComplet: _nomCtr.text.trim(),
            numeroCni: _cniCtr.text.trim(),
            telephone: _telCtr.text.trim(),
            localisationTerrain: _localisationCtr.text.trim(),
            demandeMairePath: _demandeMaire,
            pieceIdentitePath: _pieceIdentite,
            acteTerrainPath: _acteTerrain,
          );
      if (!mounted) return;
      context.push(AppRoutes.payment, extra: {
        'dossier_id': id,
        'type': 'regularisation',
        'montant': AppConstants.residenceFeesFCFA, // 500
        'label': 'Demande de régularisation',
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
    final isLoading = ref.watch(regularisationProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Régularisation Foncier'),
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
                      AppTextField(
                        label: 'Numéro CNI',
                        hint: 'Ex: 1234567890123',
                        controller: _cniCtr,
                        validator: Validators.required,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.credit_card,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: 'Téléphone',
                        hint: 'Ex: 77 123 45 67',
                        controller: _telCtr,
                        validator: Validators.required,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.phone,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: 'Localisation du terrain',
                        hint: 'Quartier ou description',
                        controller: _localisationCtr,
                        validator: Validators.required,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.map,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(height: 20),

                      Text('Commune de la demande',
                          style: AppTextStyles.headlineSmall),
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
                        title: 'Demande adressée au Maire',
                        subtitle: 'Lettre de demande',
                        icon: Icons.description_outlined,
                        filePath: _demandeMaire,
                        isRequired: true,
                        onTap: () => _pick('demande'),
                        onRemove: _demandeMaire != null
                            ? () => setState(() => _demandeMaire = null)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      UploadDocumentCard(
                        title: 'Pièce d\'identité',
                        subtitle: 'Photocopie CNI du requérant',
                        icon: Icons.badge_outlined,
                        filePath: _pieceIdentite,
                        isRequired: true,
                        onTap: () => _pick('piece'),
                        onRemove: _pieceIdentite != null
                            ? () => setState(() => _pieceIdentite = null)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      UploadDocumentCard(
                        title: 'Acte original du terrain',
                        subtitle: 'Document prouvant la possession',
                        icon: Icons.map_outlined,
                        filePath: _acteTerrain,
                        isRequired: true,
                        onTap: () => _pick('acte'),
                        onRemove: _acteTerrain != null
                            ? () => setState(() => _acteTerrain = null)
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
'''

with open('mobile/lib/features/certificates/regularisation/presentation/screens/regularisation_form_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
