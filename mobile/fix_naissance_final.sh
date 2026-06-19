#!/bin/bash
# ============================================================
# TERANGA CIVIL — Naissance Final
# 1. Select Région → Communes (sans département)
# 2. Formulaire "autre" : upload OCR OU saisie manuelle
# Usage : bash fix_naissance_final.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🚀 TERANGA CIVIL — Naissance Final"
echo ""

# ════════════════════════════════════════════════════════════
# 1. WIDGET SELECT RÉGION → COMMUNES (sans département)
# Nouveau widget dédié, distinct du CascadedCommuneSelect existant
# ════════════════════════════════════════════════════════════
cat > lib/shared/widgets/region_commune_select.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/assets_constants.dart';
import '../models/commune_model.dart';

/// Select à 2 niveaux : Région → toutes les communes de cette région
/// (sans étape département)
class RegionCommuneSelect extends StatefulWidget {
  final void Function(RegionModel? region, CommuneModel? commune) onChanged;
  final String? errorText;

  const RegionCommuneSelect({
    super.key,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<RegionCommuneSelect> createState() => _RegionCommuneSelectState();
}

class _RegionCommuneSelectState extends State<RegionCommuneSelect> {
  List<RegionModel> _regions = [];
  bool _loading = true;

  RegionModel? _selectedRegion;
  CommuneModel? _selectedCommune;

  /// Toutes les communes de la région sélectionnée
  /// (fusion de tous les départements)
  List<CommuneModel> get _communes {
    if (_selectedRegion == null) return [];
    final all = <CommuneModel>[];
    for (final dept in _selectedRegion!.departements) {
      all.addAll(dept.communes);
    }
    // Trier par nom
    all.sort((a, b) => a.nom.compareTo(b.nom));
    return all;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final jsonStr =
          await rootBundle.loadString(Assets.senegalCommunes);
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final regions = (data['regions'] as List)
          .map((r) => RegionModel.fromJson(r as Map<String, dynamic>))
          .toList();
      setState(() {
        _regions = regions;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _onRegionChanged(RegionModel? region) {
    setState(() {
      _selectedRegion = region;
      _selectedCommune = null;
    });
    widget.onChanged(region, null);
  }

  void _onCommuneChanged(CommuneModel? commune) {
    setState(() => _selectedCommune = commune);
    widget.onChanged(_selectedRegion, commune);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.secondary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Région ──────────────────────────────────────
        _DropdownField<RegionModel>(
          label: 'Région',
          hint: 'Sélectionner une région',
          value: _selectedRegion,
          items: _regions,
          itemLabel: (r) => r.nom,
          onChanged: _onRegionChanged,
          enabled: true,
        ),
        const SizedBox(height: 12),

        // ── Commune (toutes les communes de la région) ──
        _DropdownField<CommuneModel>(
          label: 'Commune',
          hint: _selectedRegion == null
              ? 'Choisissez d\'abord une région'
              : 'Sélectionner une commune (${_communes.length})',
          value: _selectedCommune,
          items: _communes,
          itemLabel: (c) => c.nom,
          onChanged: _onCommuneChanged,
          enabled: _selectedRegion != null,
          errorText: widget.errorText,
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final bool enabled;
  final String? errorText;

  const _DropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.enabled,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.inputLabel),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: AppTextStyles.inputHint),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: enabled
                ? AppColors.textSecondary
                : AppColors.buttonDisabledText,
          ),
          style: AppTextStyles.inputText,
          dropdownColor: AppColors.surface,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            errorText: errorText,
            errorStyle: AppTextStyles.inputError,
          ),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabel(item),
                      style: AppTextStyles.inputText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
DART
echo "  ✅ region_commune_select.dart (Région → Communes directement)"

# ════════════════════════════════════════════════════════════
# 2. S08A — Formulaire "Pour moi" avec nouveau select
# ════════════════════════════════════════════════════════════
cat > lib/features/certificates/naissance/presentation/screens/recap_self_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/region_commune_select.dart';
import '../../../../../shared/models/commune_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

/// S08A — Formulaire "Pour moi"
class RecapSelfScreen extends ConsumerStatefulWidget {
  const RecapSelfScreen({super.key});

  @override
  ConsumerState<RecapSelfScreen> createState() => _RecapSelfScreenState();
}

class _RecapSelfScreenState extends ConsumerState<RecapSelfScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registreCtr = TextEditingController();
  DateTime? _dateNaissance;
  CommuneModel? _commune;
  RegionModel? _region;
  bool _communeError = false;

  @override
  void dispose() {
    _registreCtr.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _registreCtr.text.trim().isNotEmpty &&
      _registreCtr.text.trim().length <= 5 &&
      _dateNaissance != null &&
      _commune != null;

  void _goToRecap() {
    if (_commune == null) {
      setState(() => _communeError = true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).user!;
    context.push(
      AppRoutes.naissanceRecapSelf + '/recap',
      extra: {
        'nom': user.nomComplet,
        'registre': _registreCtr.text.trim(),
        'date_naissance': _dateNaissance!.toIso8601String(),
        'commune_id': _commune!.id,
        'commune_nom': _commune!.nom,
        'region_nom': _region?.nom ?? '',
        'for_self': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.secondary),
          )));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Certificat de naissance'),
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
                      Text('Vos informations',
                          style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Complétez les informations pour votre certificat',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 24),

                      // ── Nom complet verrouillé ──────────────
                      _LockedField(
                        label: 'Nom complet',
                        value: user.nomComplet,
                        hint: 'Récupéré depuis votre inscription',
                      ),
                      const SizedBox(height: 16),

                      // ── Numéro de registre (max 5 chiffres) ─
                      AppTextField(
                        label: 'Numéro de registre',
                        hint: 'Ex: 12345 (5 chiffres max)',
                        controller: _registreCtr,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        maxLength: 5,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Le numéro de registre est requis.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Date de naissance ───────────────────
                      DateTextField(
                        label: 'Date de naissance',
                        selectedDate: _dateNaissance,
                        validator: (_) =>
                            Validators.dateNaissance(_dateNaissance),
                        onDateSelected: (d) =>
                            setState(() => _dateNaissance = d),
                      ),
                      const SizedBox(height: 24),

                      // ── Région → Commune (sans département) ─
                      Text('Commune déclarée',
                          style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Choisissez votre région puis votre commune',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      RegionCommuneSelect(
                        onChanged: (r, c) => setState(() {
                          _region = r;
                          _commune = c;
                          if (c != null) _communeError = false;
                        }),
                        errorText: _communeError
                            ? 'Veuillez sélectionner une commune.'
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
                label: 'Voir le récapitulatif →',
                onPressed: _goToRecap,
                isEnabled: _isValid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Champ verrouillé visuellement (non modifiable)
class _LockedField extends StatelessWidget {
  final String label;
  final String value;
  final String hint;

  const _LockedField({
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.inputLabel),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_outline,
                  color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(value, style: AppTextStyles.inputText.copyWith(
                  color: AppColors.textSecondary,
                )),
              ),
              const Icon(Icons.lock_outline,
                  color: AppColors.textHint, size: 16),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(hint,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint)),
      ],
    );
  }
}
DART
echo "  ✅ recap_self_screen.dart (Région → Commune)"

# ════════════════════════════════════════════════════════════
# 3. S08B — Formulaire "Pour une autre personne"
# Upload extrait (OCR) OU saisie manuelle — les deux valables
# ════════════════════════════════════════════════════════════
cat > lib/features/certificates/naissance/presentation/screens/other_person_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/region_commune_select.dart';
import '../../../../../shared/widgets/upload_document_card.dart';
import '../../../../../shared/models/commune_model.dart';
import '../../data/remote_datasource.dart';

/// S08B — Formulaire "Pour une autre personne"
/// L'utilisateur peut : uploader l'extrait (OCR auto) OU saisir manuellement
class OtherPersonScreen extends ConsumerStatefulWidget {
  const OtherPersonScreen({super.key});

  @override
  ConsumerState<OtherPersonScreen> createState() => _OtherPersonScreenState();
}

class _OtherPersonScreenState extends ConsumerState<OtherPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtr = TextEditingController();
  final _registreCtr = TextEditingController();
  DateTime? _dateNaissance;
  CommuneModel? _commune;
  RegionModel? _region;
  bool _communeError = false;

  // Documents
  String? _cniRecto;
  String? _cniVerso;
  String? _extraitNaissance;

  // OCR state
  bool _ocrLoading = false;
  String? _ocrMessage;
  bool _ocrSuccess = false;

  @override
  void dispose() {
    _nomCtr.dispose();
    _registreCtr.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nomCtr.text.trim().isNotEmpty &&
      _registreCtr.text.trim().isNotEmpty &&
      _dateNaissance != null &&
      _commune != null &&
      _cniRecto != null &&
      _cniVerso != null;

  // ── Upload documents ────────────────────────────────────
  Future<void> _pickDocument(String type) async {
    final path = await DocumentUploadHelper.pick(context);
    if (path == null) return;
    setState(() {
      switch (type) {
        case 'recto':  _cniRecto = path; break;
        case 'verso':  _cniVerso = path; break;
        case 'extrait': _extraitNaissance = path; break;
      }
    });
    if (type == 'extrait') await _runOcr(path);
  }

  // ── OCR automatique ────────────────────────────────────
  Future<void> _runOcr(String imagePath) async {
    setState(() {
      _ocrLoading = true;
      _ocrMessage = null;
      _ocrSuccess = false;
    });
    try {
      final ds = NaissanceRemoteDatasource(
          client: ref.read(dioClientProvider));
      final data = await ds.extractOcr(imagePath);
      if (!mounted) return;
      setState(() {
        _ocrLoading = false;
        _ocrSuccess = true;
        if ((data['nom'] as String? ?? '').isNotEmpty) {
          _nomCtr.text = data['nom'] as String;
        }
        final reg = data['registre'] as String? ?? '';
        if (reg.isNotEmpty) {
          _registreCtr.text =
              reg.length > 5 ? reg.substring(0, 5) : reg;
        }
        if (data['date_naissance'] != null) {
          _dateNaissance =
              DateTime.tryParse(data['date_naissance'] as String);
        }
        final communeNom = data['commune_nom'] as String? ?? '';
        _ocrMessage = communeNom.isNotEmpty
            ? 'Données extraites. Commune suggérée : $communeNom — sélectionnez-la dans la liste.'
            : 'Données extraites automatiquement. Vérifiez et corrigez si besoin.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ocrLoading = false;
        _ocrSuccess = false;
        _ocrMessage =
            'Extraction automatique échouée. Remplissez manuellement.';
      });
    }
  }

  void _clearExtrait() {
    setState(() {
      _extraitNaissance = null;
      _ocrMessage = null;
      _ocrSuccess = false;
    });
  }

  void _goToRecap() {
    if (_commune == null) {
      setState(() => _communeError = true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_cniRecto == null || _cniVerso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter les deux faces de la CNI.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.push(AppRoutes.naissanceRecapOther, extra: {
      'nom': _nomCtr.text.trim(),
      'registre': _registreCtr.text.trim(),
      'date_naissance': _dateNaissance!.toIso8601String(),
      'commune_id': _commune!.id,
      'commune_nom': _commune!.nom,
      'region_nom': _region?.nom ?? '',
      'cni_recto': _cniRecto,
      'cni_verso': _cniVerso,
      'extrait_naissance': _extraitNaissance,
      'for_self': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pour une autre personne'),
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

                      // ══════════════════════════════════════
                      // SECTION 1 : Extrait (optionnel / OCR)
                      // ══════════════════════════════════════
                      _SectionHeader(
                        title: 'Extrait de naissance existant',
                        badge: 'Optionnel',
                        badgeColor: AppColors.statusBlue,
                        badgeBg: AppColors.statusBlueLight,
                      ),
                      const SizedBox(height: 8),
                      // Explication claire des deux options
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statusBlueLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.statusBlue.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.info_outline,
                                  color: AppColors.statusBlue, size: 16),
                              const SizedBox(width: 8),
                              Text('Deux options disponibles :',
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: AppColors.statusBlue)),
                            ]),
                            const SizedBox(height: 6),
                            Text(
                              '📎 Uploader un extrait → les champs se remplissent automatiquement\n'
                              '✏️  Remplir manuellement → ignorez cette section',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.statusBlue),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      UploadDocumentCard(
                        title: 'Extrait de naissance',
                        subtitle: _ocrLoading
                            ? 'Extraction en cours...'
                            : 'Photo ou galerie — pré-remplissage automatique',
                        icon: Icons.description_outlined,
                        filePath: _extraitNaissance,
                        isRequired: false,
                        isLoading: _ocrLoading,
                        onTap: _ocrLoading ? () {} : () => _pickDocument('extrait'),
                        onRemove: (_extraitNaissance != null && !_ocrLoading)
                            ? _clearExtrait
                            : null,
                      ),

                      // Feedback OCR
                      if (_ocrLoading) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppColors.secondary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Analyse de l\'extrait en cours...',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.secondary)),
                          ),
                        ]),
                      ],
                      if (_ocrMessage != null && !_ocrLoading) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _ocrSuccess
                                ? AppColors.statusGreenLight
                                : AppColors.statusAmberLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (_ocrSuccess
                                      ? AppColors.secondary
                                      : AppColors.statusAmber)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _ocrSuccess
                                    ? Icons.check_circle_outline
                                    : Icons.warning_amber_outlined,
                                size: 16,
                                color: _ocrSuccess
                                    ? AppColors.secondary
                                    : AppColors.statusAmber,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_ocrMessage!,
                                    style: AppTextStyles.caption.copyWith(
                                      color: _ocrSuccess
                                          ? AppColors.secondary
                                          : AppColors.statusAmber,
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // ══════════════════════════════════════
                      // SECTION 2 : Formulaire bénéficiaire
                      // ══════════════════════════════════════
                      Row(children: [
                        Text('Informations du bénéficiaire',
                            style: AppTextStyles.headlineMedium),
                        if (_ocrSuccess) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.statusGreenLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_fix_high,
                                    size: 12, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text('Pré-rempli',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        _ocrSuccess
                            ? 'Données extraites — vérifiez et corrigez si nécessaire'
                            : 'Remplissez les informations manuellement',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 20),

                      // Nom complet
                      AppTextField(
                        label: 'Nom complet',
                        hint: 'Ex: Fatou Sow',
                        controller: _nomCtr,
                        validator: Validators.fullName,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.person_outline,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(height: 16),

                      // Registre (max 5 chiffres)
                      AppTextField(
                        label: 'Numéro de registre (max 5 chiffres)',
                        hint: 'Ex: 12345',
                        controller: _registreCtr,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        maxLength: 5,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Le numéro de registre est requis.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date de naissance
                      DateTextField(
                        label: 'Date de naissance',
                        selectedDate: _dateNaissance,
                        validator: (_) =>
                            Validators.dateNaissance(_dateNaissance),
                        onDateSelected: (d) =>
                            setState(() => _dateNaissance = d),
                      ),
                      const SizedBox(height: 24),

                      // Région → Commune
                      Text('Commune déclarée',
                          style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        _ocrSuccess && _ocrMessage!.contains('suggérée')
                            ? 'Commune suggérée par l\'OCR — sélectionnez dans la liste'
                            : 'Choisissez la région puis la commune',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      RegionCommuneSelect(
                        onChanged: (r, c) => setState(() {
                          _region = r;
                          _commune = c;
                          if (c != null) _communeError = false;
                        }),
                        errorText: _communeError
                            ? 'Veuillez sélectionner une commune.'
                            : null,
                      ),
                      const SizedBox(height: 32),

                      // ══════════════════════════════════════
                      // SECTION 3 : CNI obligatoire
                      // ══════════════════════════════════════
                      _SectionHeader(
                        title: 'Pièce d\'identité (CNI)',
                        badge: 'Obligatoire',
                        badgeColor: AppColors.statusRed,
                        badgeBg: AppColors.statusRedLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Les deux faces de la CNI sont requises pour valider la demande.',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      UploadDocumentCard(
                        title: 'CNI — Recto',
                        subtitle: 'Face avant de la carte d\'identité',
                        icon: Icons.credit_card_outlined,
                        filePath: _cniRecto,
                        isRequired: true,
                        onTap: () => _pickDocument('recto'),
                        onRemove: _cniRecto != null
                            ? () => setState(() => _cniRecto = null)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      UploadDocumentCard(
                        title: 'CNI — Verso',
                        subtitle: 'Face arrière de la carte d\'identité',
                        icon: Icons.credit_card_outlined,
                        filePath: _cniVerso,
                        isRequired: true,
                        onTap: () => _pickDocument('verso'),
                        onRemove: _cniVerso != null
                            ? () => setState(() => _cniVerso = null)
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
                label: 'Voir le récapitulatif →',
                onPressed: _goToRecap,
                isEnabled: _isValid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;

  const _SectionHeader({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.headlineSmall),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badge,
            style: AppTextStyles.caption.copyWith(
                color: badgeColor, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
DART
echo "  ✅ other_person_screen.dart (upload OCR OU saisie manuelle)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Naissance Final appliqué !"
echo ""
echo "Changements :"
echo "  1. RegionCommuneSelect : Région → toutes les communes"
echo "     (sans département, communes triées par nom)"
echo ""
echo "  2. 'Pour une autre personne' :"
echo "     • Info claire : 2 options (upload OCR ou saisie manuelle)"
echo "     • Upload extrait → OCR auto → pré-remplissage + badge 'Pré-rempli'"
echo "     • OU : saisir directement sans uploader (les deux valables)"
echo "     • CNI recto/verso toujours obligatoire"
echo ""
echo "  flutter run"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
