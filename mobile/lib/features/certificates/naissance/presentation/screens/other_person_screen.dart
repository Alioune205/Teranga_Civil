import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/backend_commune_select.dart';
import '../../../../../shared/widgets/upload_document_card.dart';
import '../../../../../shared/widgets/certificate_step_indicator.dart';
import '../../../../../shared/models/commune_model.dart';
import '../../data/remote_datasource.dart';

/// S08B — Formulaire "Pour une autre personne" en assistant multi-étapes.
/// Étape 1 : méthode (téléverser un extrait OU remplir). Étape 2 :
/// informations du bénéficiaire + région/commune. Étape 3 : pièce d'identité.
class OtherPersonScreen extends ConsumerStatefulWidget {
  const OtherPersonScreen({super.key});

  @override
  ConsumerState<OtherPersonScreen> createState() => _OtherPersonScreenState();
}

class _OtherPersonScreenState extends ConsumerState<OtherPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtr = TextEditingController();
  final _registreCtr = TextEditingController();
  final _anneeCtr = TextEditingController();
  String? _lienParente;
  DateTime? _dateNaissance;
  BackendCommuneModel? _commune;
  String? _regionName;
  bool _communeError = false;

  // Étape courante : 0 = méthode, 1 = infos, 2 = pièce d'identité.
  int _step = 0;
  String _method = ''; // '' | 'form' | 'upload'

  // Documents
  String? _cniRecto;
  String? _cniVerso;
  String? _extraitNaissance;

  // OCR state
  bool _ocrLoading = false;
  String? _ocrMessage;
  bool _ocrSuccess = false;
  bool _imageTooSmall = false;
  String? _ocrCommuneId;

  static const _kNom = 'draft_naissance_other_nom';
  static const _kRegistre = 'draft_naissance_other_registre';
  static const _kAnnee = 'draft_naissance_other_annee';
  static const _kLien = 'draft_naissance_other_lien';
  static const _kDate = 'draft_naissance_other_date';

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final nom = prefs.getString(_kNom) ?? '';
    final registre = prefs.getString(_kRegistre) ?? '';
    final annee = prefs.getString(_kAnnee) ?? '';
    final lien = prefs.getString(_kLien);
    final dateStr = prefs.getString(_kDate);
    if (!mounted) return;
    setState(() {
      if (nom.isNotEmpty) _nomCtr.text = nom;
      if (registre.isNotEmpty) _registreCtr.text = registre;
      if (annee.isNotEmpty) _anneeCtr.text = annee;
      if (lien != null) _lienParente = lien;
      if (dateStr != null) _dateNaissance = DateTime.tryParse(dateStr);
    });
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNom, _nomCtr.text.trim());
    await prefs.setString(_kRegistre, _registreCtr.text.trim());
    await prefs.setString(_kAnnee, _anneeCtr.text.trim());
    if (_lienParente != null) await prefs.setString(_kLien, _lienParente!);
    if (_dateNaissance != null) {
      await prefs.setString(_kDate, _dateNaissance!.toIso8601String());
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kNom);
    await prefs.remove(_kRegistre);
    await prefs.remove(_kAnnee);
    await prefs.remove(_kLien);
    await prefs.remove(_kDate);
  }

  @override
  void dispose() {
    _nomCtr.dispose();
    _registreCtr.dispose();
    _anneeCtr.dispose();
    super.dispose();
  }

  bool get _infoValid =>
      _nomCtr.text.trim().isNotEmpty &&
      _registreCtr.text.trim().isNotEmpty &&
      _anneeCtr.text.trim().length == 4 &&
      _dateNaissance != null &&
      _commune != null &&
      _lienParente != null;

  bool get _cniValid => _cniRecto != null && _cniVerso != null;

  bool get _canLeaveStep0 {
    if (_method == 'form') return true;
    if (_method == 'upload') return _extraitNaissance != null && !_ocrLoading;
    return false;
  }

  // ── Upload documents ────────────────────────────────────
  Future<void> _pickDocument(String type) async {
    final path = await DocumentUploadHelper.pick(context);
    if (path == null) return;
    setState(() {
      switch (type) {
        case 'recto':
          _cniRecto = path;
          break;
        case 'verso':
          _cniVerso = path;
          break;
        case 'extrait':
          _extraitNaissance = path;
          _imageTooSmall = false;
          break;
      }
    });
    if (type == 'extrait') {
      try {
        final size = await File(path).length();
        if (size < 40000 && mounted) setState(() => _imageTooSmall = true);
      } catch (_) {}
      await _runOcr(path);
    }
  }

  // ── OCR automatique ────────────────────────────────────
  Future<void> _runOcr(String imagePath) async {
    setState(() {
      _ocrLoading = true;
      _ocrMessage = null;
      _ocrSuccess = false;
    });
    try {
      final ds = NaissanceRemoteDatasource(client: ref.read(dioClientProvider));
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
          _registreCtr.text = reg.length > 12 ? reg.substring(0, 12) : reg;
        }
        if (data['date_naissance'] != null) {
          _dateNaissance = DateTime.tryParse(data['date_naissance'] as String);
        }
        final annee = data['annee_registre'];
        if (annee != null) {
          _anneeCtr.text = annee.toString();
        }
        _ocrCommuneId = data['commune_id'] as String? ?? '';
        final communeNom = data['commune_nom'] as String? ?? '';
        _ocrMessage = communeNom.isNotEmpty
            ? 'Données extraites. Région et commune pré-sélectionnées ($communeNom).'
            : 'Données extraites automatiquement. Vérifiez et corrigez si besoin.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ocrLoading = false;
        _ocrSuccess = false;
        _ocrMessage = 'Extraction automatique échouée. Remplissez manuellement.';
      });
    }
  }

  void _clearExtrait() {
    setState(() {
      _extraitNaissance = null;
      _ocrMessage = null;
      _ocrSuccess = false;
      _imageTooSmall = false;
      _nomCtr.clear();
      _registreCtr.clear();
      _anneeCtr.clear();
      _dateNaissance = null;
      _ocrCommuneId = null;
      _commune = null;
      _regionName = null;
    });
  }

  void _showTooltipRegistre(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Numéro de registre'),
          ],
        ),
        content: const Text(
          'Le numéro de registre (aussi appelé numéro d\'acte) figure sur l\'extrait '
          'de naissance, en haut à droite du document.\n\n'
          'Exemple : "2020-0142" ou "42".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  // ── Navigation entre étapes ────────────────────────────────
  void _backStep() => setState(() => _step -= 1);

  void _nextFromMethod() {
    if (!_canLeaveStep0) return;
    setState(() => _step = 1);
  }

  void _nextFromInfo() {
    if (_commune == null) {
      setState(() => _communeError = true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = 2);
  }

  void _goToRecap() {
    if (!_cniValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter les deux faces de la CNI.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    _clearDraft();
    context.push(AppRoutes.naissanceRecapOther, extra: {
      'nom': _nomCtr.text.trim(),
      'registre': _registreCtr.text.trim(),
      'annee_registre': _anneeCtr.text.trim(),
      'date_naissance': _dateNaissance!.toIso8601String(),
      'commune_id': _commune!.code,
      'commune_nom': _commune!.name,
      'region_nom': _regionName ?? '',
      'lien_parente': _lienParente ?? '',
      'cni_recto': _cniRecto,
      'cni_verso': _cniVerso,
      'extrait_naissance': _extraitNaissance,
      'for_self': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Comment procéder ?', 'Bénéficiaire', 'Pièce d\'identité'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pour une autre personne'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => _step == 0 ? context.pop() : _backStep(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const CertificateStepIndicator(currentStep: CertStep.formulaire),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.statusBlueLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Étape ${_step + 1} / 3',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.statusBlue,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Text(titles[_step], style: AppTextStyles.bodySmall),
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _step == 0
                    ? _buildMethodStep()
                    : _step == 1
                        ? Form(
                            key: _formKey,
                            onChanged: () {
                              setState(() {});
                              _saveDraft();
                            },
                            child: _buildInfoStep(),
                          )
                        : _buildCniStep(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _step == 0
                  ? PrimaryButton(
                      label: 'Suivant →',
                      onPressed: _nextFromMethod,
                      isEnabled: _canLeaveStep0)
                  : _step == 1
                      ? PrimaryButton(
                          label: 'Suivant →',
                          onPressed: _nextFromInfo,
                          isEnabled: _infoValid)
                      : PrimaryButton(
                          label: 'Voir le récapitulatif →',
                          onPressed: _goToRecap,
                          isEnabled: _cniValid),
            ),
          ],
        ),
      ),
    );
  }

  // ── ÉTAPE 1 : méthode ──────────────────────────────────────
  Widget _buildMethodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deux options disponibles', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 4),
        Text('Choisissez comment fournir les informations de l\'acte.',
            style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),
        _MethodCard(
          icon: Icons.edit_document,
          title: 'Remplir le formulaire',
          subtitle: 'Saisir le bénéficiaire, le registre et la commune',
          selected: _method == 'form',
          onTap: () => setState(() => _method = 'form'),
        ),
        const SizedBox(height: 12),
        _MethodCard(
          icon: Icons.upload_file_outlined,
          title: 'Téléverser un document',
          subtitle: 'Joindre un extrait déjà en ma possession',
          selected: _method == 'upload',
          onTap: () => setState(() => _method = 'upload'),
        ),
        if (_method == 'upload') ...[
          const SizedBox(height: 20),
          UploadDocumentCard(
            title: 'Extrait de naissance',
            subtitle: _ocrLoading
                ? 'Extraction en cours...'
                : 'Photo ou galerie — pré-remplissage automatique',
            icon: Icons.description_outlined,
            filePath: _extraitNaissance,
            isRequired: true,
            isLoading: _ocrLoading,
            onTap: _ocrLoading ? () {} : () => _pickDocument('extrait'),
            onRemove: (_extraitNaissance != null && !_ocrLoading)
                ? _clearExtrait
                : null,
          ),
          if (_imageTooSmall && !_ocrLoading) ...[
            const SizedBox(height: 10),
            _InfoBanner(
              icon: Icons.photo_size_select_large_outlined,
              color: AppColors.statusAmber,
              bg: AppColors.statusAmberLight,
              text:
                  'Image de faible résolution — l\'extraction peut être imprécise. Prenez une photo nette.',
            ),
          ],
          if (_ocrMessage != null && !_ocrLoading) ...[
            const SizedBox(height: 10),
            _InfoBanner(
              icon: _ocrSuccess
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_outlined,
              color: _ocrSuccess ? AppColors.secondary : AppColors.statusAmber,
              bg: _ocrSuccess
                  ? AppColors.statusGreenLight
                  : AppColors.statusAmberLight,
              text: _ocrMessage!,
            ),
            if (_ocrSuccess) ...[
              const SizedBox(height: 8),
              Text('Les champs seront pré-remplis à l\'étape suivante.',
                  style: AppTextStyles.caption),
            ],
          ],
        ],
      ],
    );
  }

  // ── ÉTAPE 2 : informations bénéficiaire ────────────────────
  Widget _buildInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_ocrSuccess) ...[
          _InfoBanner(
            icon: Icons.auto_fix_high,
            color: AppColors.secondary,
            bg: AppColors.statusGreenLight,
            text: 'Champs pré-remplis depuis l\'extrait — vérifiez-les.',
          ),
          const SizedBox(height: 16),
        ],
        _LienParenteField(
          value: _lienParente,
          onChanged: (v) {
            setState(() => _lienParente = v);
            _saveDraft();
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Nom complet du bénéficiaire',
          hint: 'Ex: Fatou Sow',
          controller: _nomCtr,
          validator: Validators.fullName,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.person_outline,
              color: AppColors.textSecondary, size: 20),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Numéro de registre',
          hint: 'Ex: 2020-0142',
          suffixIcon: GestureDetector(
            onTap: () => _showTooltipRegistre(context),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.info_outline,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
          controller: _registreCtr,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          maxLength: 12,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z/-]')),
            LengthLimitingTextInputFormatter(12),
          ],
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Le numéro de registre est requis.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Année de registre',
          hint: 'Ex: 2010',
          controller: _anneeCtr,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          maxLength: 4,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          prefixIcon: const Icon(Icons.event_outlined,
              color: AppColors.textSecondary, size: 20),
          validator: (v) {
            if (v == null || v.trim().length != 4) {
              return 'L\'année de registre est requise (4 chiffres).';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DateTextField(
          label: 'Date de naissance',
          selectedDate: _dateNaissance,
          validator: (_) => Validators.dateNaissance(_dateNaissance),
          onDateSelected: (d) {
            setState(() => _dateNaissance = d);
            _saveDraft();
          },
        ),
        const SizedBox(height: 24),
        Text('Région et commune déclarée', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 4),
        Text('Choisissez la région puis la commune',
            style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),
        BackendCommuneSelect(
          initialCommuneId: _ocrCommuneId,
          onChanged: (region, commune) => setState(() {
            _regionName = region;
            _commune = commune;
            if (commune != null) _communeError = false;
          }),
          errorText:
              _communeError ? 'Veuillez sélectionner une commune.' : null,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── ÉTAPE 3 : pièce d'identité ─────────────────────────────
  Widget _buildCniStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Pièce d\'identité (CNI)',
          badge: 'Obligatoire',
          badgeColor: AppColors.statusRed,
          badgeBg: AppColors.statusRedLight,
        ),
        const SizedBox(height: 8),
        Text(
          'Les deux faces de votre CNI sont requises pour valider la demande pour un tiers.',
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
          onRemove:
              _cniRecto != null ? () => setState(() => _cniRecto = null) : null,
        ),
        const SizedBox(height: 12),
        UploadDocumentCard(
          title: 'CNI — Verso',
          subtitle: 'Face arrière de la carte d\'identité',
          icon: Icons.credit_card_outlined,
          filePath: _cniVerso,
          isRequired: true,
          onTap: () => _pickDocument('verso'),
          onRemove:
              _cniVerso != null ? () => setState(() => _cniVerso = null) : null,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Carte de choix de méthode ──────────────────────────────────
class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textHint,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bandeau d'information générique ────────────────────────────
class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String text;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.bg,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: AppTextStyles.caption.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

// ── Lien de parenté ──────────────────────────────────────────
class _LienParenteField extends StatelessWidget {
  final String? value;
  final void Function(String?) onChanged;

  static const _options = [
    'Père / Mère',
    'Enfant',
    'Frère / Sœur',
    'Grand-parent',
    'Époux / Épouse',
    'Représentant légal',
    'Autre',
  ];

  const _LienParenteField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Lien de parenté', style: AppTextStyles.inputLabel),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.statusRedLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Requis',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.statusRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          hint: Text('Votre lien avec le bénéficiaire',
              style: AppTextStyles.inputHint),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: AppTextStyles.inputText,
          dropdownColor: AppColors.surface,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: const Icon(Icons.people_outline,
                color: AppColors.textSecondary, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          items: _options
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(o, style: AppTextStyles.inputText),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: (v) =>
              v == null ? 'Veuillez indiquer votre lien de parenté.' : null,
        ),
      ],
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
            style: AppTextStyles.caption
                .copyWith(color: badgeColor, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
