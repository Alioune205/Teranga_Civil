import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/backend_commune_select.dart';
import '../../../../../shared/widgets/upload_document_card.dart';
import '../../../../../shared/models/commune_model.dart';
import '../providers/foncier_provider.dart';

/// Pièce à fournir pour une demande foncière.
class FoncierDoc {
  final String key;
  final String label;
  final String subtitle;
  final IconData icon;
  const FoncierDoc(this.key, this.label, this.subtitle, this.icon);
}

/// Configuration d'une demande foncière (type backend + titre + pièces).
class FoncierConfig {
  final String type; // 'regularisation' | 'autorisation_construire' | 'mutation_parcelle'
  final String title;
  final List<FoncierDoc> docs;
  final String? note;
  const FoncierConfig({
    required this.type,
    required this.title,
    required this.docs,
    this.note,
  });

  static const regularisation = FoncierConfig(
    type: 'regularisation',
    title: 'Demande de régularisation',
    docs: [
      FoncierDoc('demande_maire', 'Demande adressée au Maire',
          'Lettre de demande de régularisation', Icons.mail_outline),
      FoncierDoc('cni', "Photocopie de la pièce d'identité",
          'CNI ou passeport du requérant', Icons.credit_card_outlined),
      FoncierDoc('acte_terrain', 'Acte original du terrain',
          'Titre / acte de propriété', Icons.description_outlined),
    ],
  );

  static const autorisationConstruire = FoncierConfig(
    type: 'autorisation_construire',
    title: 'Autorisation de construire',
    note: 'Les 12 pièces sont requises, et le dossier doit être déposé en '
        'mairie en 7 exemplaires.',
    docs: [
      FoncierDoc('acte_admin', 'Acte administratif', '', Icons.gavel_outlined),
      FoncierDoc('acte_vente', 'Acte de vente enregistré', '', Icons.receipt_long_outlined),
      FoncierDoc('plan_construction', 'Plan de construction', '', Icons.architecture_outlined),
      FoncierDoc('plan_cadastral', 'Plan cadastral', '', Icons.map_outlined),
      FoncierDoc('cni', "Photocopie de la pièce d'identité", '', Icons.credit_card_outlined),
      FoncierDoc('bail', 'Demande de bail / attestation de dépôt', '', Icons.article_outlined),
      FoncierDoc('demande_maire', 'Demande adressée au Maire', '', Icons.mail_outline),
      FoncierDoc('fiche', 'Fiche de renseignements', '', Icons.assignment_outlined),
      FoncierDoc('devis', 'Devis descriptif du projet', '', Icons.calculate_outlined),
      FoncierDoc('fosse', 'Plan de fosse septique', '', Icons.water_drop_outlined),
      FoncierDoc('taxe_urba', "Taxe d'urbanisme", '', Icons.account_balance_outlined),
      FoncierDoc('taxe_comm', 'Taxe communale', '', Icons.receipt_outlined),
    ],
  );

  static const mutationParcelle = FoncierConfig(
    type: 'mutation_parcelle',
    title: 'Mutation de parcelle',
    note: 'Frais : 1 000 F/m² (confirmé par la mairie au traitement).',
    docs: [
      FoncierDoc('acte_vente', 'Acte de vente', '', Icons.receipt_long_outlined),
      FoncierDoc('acte_terrain', 'Acte original du terrain', '', Icons.description_outlined),
      FoncierDoc('plan_cadastral', 'Plan cadastral', '', Icons.map_outlined),
      FoncierDoc('cni_vendeur', 'Copie CNI du vendeur', '', Icons.badge_outlined),
      FoncierDoc('cni_acheteur', "Copie CNI de l'acheteur", '', Icons.badge_outlined),
      FoncierDoc('cni_temoins', 'Copie CNI des deux témoins', '', Icons.group_outlined),
    ],
  );

  static FoncierConfig byType(String type) {
    switch (type) {
      case 'autorisation_construire':
        return autorisationConstruire;
      case 'mutation_parcelle':
        return mutationParcelle;
      default:
        return regularisation;
    }
  }
}

/// Formulaire générique des demandes foncières (récépissé).
class FoncierFormScreen extends ConsumerStatefulWidget {
  final FoncierConfig config;
  const FoncierFormScreen({super.key, required this.config});

  @override
  ConsumerState<FoncierFormScreen> createState() => _FoncierFormScreenState();
}

class _FoncierFormScreenState extends ConsumerState<FoncierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _localisationCtr = TextEditingController();
  final _quartierCtr = TextEditingController();
  final _superficieCtr = TextEditingController();
  final _referenceCtr = TextEditingController();

  BackendCommuneModel? _commune;
  bool _communeError = false;
  final Map<String, String?> _docs = {};

  @override
  void dispose() {
    _localisationCtr.dispose();
    _quartierCtr.dispose();
    _superficieCtr.dispose();
    _referenceCtr.dispose();
    super.dispose();
  }

  int get _docsAttached =>
      widget.config.docs.where((d) => _docs[d.key] != null).length;

  bool get _isValid =>
      _localisationCtr.text.trim().isNotEmpty &&
      _quartierCtr.text.trim().isNotEmpty &&
      _superficieCtr.text.trim().isNotEmpty &&
      _referenceCtr.text.trim().isNotEmpty &&
      _commune != null &&
      // Le backend exige TOUTES les pièces avant la soumission.
      _docsAttached == widget.config.docs.length;

  Future<void> _pick(String key) async {
    final path = await DocumentUploadHelper.pick(context);
    if (path == null) return;
    setState(() => _docs[key] = path);
  }

  Future<void> _submit() async {
    if (_commune == null) {
      setState(() => _communeError = true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    try {
      final docs = <({String path, String description})>[];
      for (final d in widget.config.docs) {
        final p = _docs[d.key];
        if (p != null) docs.add((path: p, description: d.label));
      }
      final id = await ref.read(foncierProvider.notifier).submit(
            type: widget.config.type,
            communeId: _commune!.code,
            localisationTerrain: _localisationCtr.text.trim(),
            quartierVillage: _quartierCtr.text.trim(),
            superficie: _superficieCtr.text.trim(),
            referenceCadastrale: _referenceCtr.text.trim(),
            documents: docs,
          );
      if (!mounted) return;
      context.push(AppRoutes.payment, extra: {
        'dossier_id': id,
        'type': widget.config.type,
        'montant': AppConstants.foncierFeesFCFA,
        'label': widget.config.title,
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException
          ? e.message
          : e is Failure
              ? e.message
              : 'Une erreur est survenue.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(foncierProvider).isLoading;
    final cfg = widget.config;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(cfg.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  onChanged: () => setState(() {}),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cfg.note != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.statusBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    AppColors.statusBlue.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: AppColors.statusBlue, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(cfg.note!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.statusBlue)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      Text('Informations sur le terrain',
                          style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Localisation du terrain',
                        hint: 'Ex: Parcelles Assainies U22',
                        controller: _localisationCtr,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.location_on_outlined,
                            color: AppColors.textSecondary, size: 20),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'La localisation est requise.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Quartier / Village',
                        hint: 'Ex: Médina',
                        controller: _quartierCtr,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.holiday_village_outlined,
                            color: AppColors.textSecondary, size: 20),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Le quartier/village est requis.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Superficie',
                        hint: 'Ex: 150 m2',
                        controller: _superficieCtr,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.straighten_outlined,
                            color: AppColors.textSecondary, size: 20),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'La superficie est requise.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Référence cadastrale / N° de lot',
                        hint: 'Ex: TF 1234/DK ou Lot N° 45',
                        controller: _referenceCtr,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.tag_outlined,
                            color: AppColors.textSecondary, size: 20),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'La référence est requise (ou "Non applicable").'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      Text('Commune', style: AppTextStyles.headlineSmall),
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pièces à joindre',
                              style: AppTextStyles.headlineSmall),
                          Text('$_docsAttached / ${cfg.docs.length}',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: _docsAttached == cfg.docs.length
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              )),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          'Toutes les pièces sont obligatoires, et chacune doit '
                          'être un fichier différent.',
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: 14),
                      ...cfg.docs.map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: UploadDocumentCard(
                              title: d.label,
                              subtitle: d.subtitle.isEmpty
                                  ? 'Document à joindre'
                                  : d.subtitle,
                              icon: d.icon,
                              filePath: _docs[d.key],
                              isRequired: true,
                              onTap: () => _pick(d.key),
                              onRemove: _docs[d.key] != null
                                  ? () => setState(() => _docs[d.key] = null)
                                  : null,
                            ),
                          )),
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
