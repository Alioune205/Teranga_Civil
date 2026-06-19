import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
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
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/remote_datasource.dart';

/// S08A — Formulaire "Pour moi" en assistant multi-étapes.
/// Étape 1 : choix de la méthode (téléverser un extrait OU remplir le
/// formulaire). Étape 2 : informations + région/commune déclarée.
class RecapSelfScreen extends ConsumerStatefulWidget {
  const RecapSelfScreen({super.key});

  @override
  ConsumerState<RecapSelfScreen> createState() => _RecapSelfScreenState();
}

class _RecapSelfScreenState extends ConsumerState<RecapSelfScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registreCtr = TextEditingController();
  final _anneeCtr = TextEditingController();
  DateTime? _dateNaissance;
  BackendCommuneModel? _commune;
  String? _regionName;
  bool _communeError = false;

  // Étape courante : 0 = méthode, 1 = informations.
  int _step = 0;
  // Méthode choisie : '' (aucune), 'form' (saisie) ou 'upload' (téléversement).
  String _method = '';

  // Upload extrait (optionnel)
  String? _extraitNaissance;
  bool _ocrLoading = false;
  String? _ocrMessage;
  bool _ocrSuccess = false;
  bool _imageTooSmall = false;
  String? _ocrCommuneId;

  static const _kRegistre = 'draft_naissance_self_registre';
  static const _kAnnee = 'draft_naissance_self_annee';
  static const _kDate = 'draft_naissance_self_date';

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _ensureUser();
  }

  /// Si l'état auth n'a pas de user (hot-restart, token expiré…),
  /// on le recharge depuis l'API — ou on renvoie vers login.
  Future<void> _ensureUser() async {
    if (ref.read(authProvider).user != null) return;
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.getMe();
      if (mounted) ref.read(authProvider.notifier).setUser(user);
    } catch (_) {
      if (mounted) context.go(AppRoutes.login);
    }
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final registre = prefs.getString(_kRegistre) ?? '';
    final annee = prefs.getString(_kAnnee) ?? '';
    final dateStr = prefs.getString(_kDate);
    if (!mounted) return;
    setState(() {
      if (registre.isNotEmpty) _registreCtr.text = registre;
      if (annee.isNotEmpty) _anneeCtr.text = annee;
      if (dateStr != null) _dateNaissance = DateTime.tryParse(dateStr);
    });
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRegistre, _registreCtr.text.trim());
    await prefs.setString(_kAnnee, _anneeCtr.text.trim());
    if (_dateNaissance != null) {
      await prefs.setString(_kDate, _dateNaissance!.toIso8601String());
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRegistre);
    await prefs.remove(_kAnnee);
    await prefs.remove(_kDate);
  }

  @override
  void dispose() {
    _registreCtr.dispose();
    _anneeCtr.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _registreCtr.text.trim().isNotEmpty &&
      _registreCtr.text.trim().length <= 12 &&
      _anneeCtr.text.trim().length == 4 &&
      _dateNaissance != null &&
      _commune != null;

  // ── Upload & OCR ───────────────────────────────────────────
  Future<void> _pickExtrait() async {
    final path = await DocumentUploadHelper.pick(context);
    if (path == null) return;
    setState(() {
      _extraitNaissance = path;
      _imageTooSmall = false;
    });
    try {
      final size = await File(path).length();
      if (size < 40000 && mounted) setState(() => _imageTooSmall = true);
    } catch (_) {}
    await _runOcr(path);
  }

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
      _registreCtr.clear();
      _anneeCtr.clear();
      _dateNaissance = null;
      _ocrCommuneId = null;
      _commune = null;
      _regionName = null;
    });
  }

  // ── Navigation entre étapes ────────────────────────────────
  bool get _canLeaveStep0 {
    if (_method == 'form') return true;
    if (_method == 'upload') return _extraitNaissance != null && !_ocrLoading;
    return false;
  }

  void _nextStep() {
    if (!_canLeaveStep0) return;
    setState(() => _step = 1);
  }

  void _backStep() => setState(() => _step = 0);

  // ── Navigation vers récap ──────────────────────────────────
  void _goToRecap() {
    if (_commune == null) {
      setState(() => _communeError = true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).user!;
    _clearDraft();
    context.push(
      AppRoutes.naissanceRecapSelf + '/recap',
      extra: {
        'nom': user.nomComplet,
        'registre': _registreCtr.text.trim(),
        'annee_registre': _anneeCtr.text.trim(),
        'date_naissance': _dateNaissance!.toIso8601String(),
        'commune_id': _commune!.code,
        'commune_nom': _commune!.name,
        'region_nom': _regionName ?? '',
        'extrait_naissance': _extraitNaissance,
        'for_self': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Certificat de naissance'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.secondary),
              ),
              SizedBox(height: 16),
              Text('Chargement du profil…'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Certificat de naissance'),
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
            // Sous-étape (1/2 ou 2/2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.statusBlueLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Étape ${_step + 1} / 2',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.statusBlue,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _step == 0 ? 'Comment procéder ?' : 'Vos informations',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _step == 0
                    ? _buildMethodStep()
                    : Form(
                        key: _formKey,
                        onChanged: () {
                          setState(() {});
                          _saveDraft();
                        },
                        child: _buildInfoStep(user.nomComplet),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _step == 0
                  ? PrimaryButton(
                      label: 'Suivant →',
                      onPressed: _nextStep,
                      isEnabled: _canLeaveStep0,
                    )
                  : PrimaryButton(
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

  // ── ÉTAPE 1 : choix de la méthode ──────────────────────────
  Widget _buildMethodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deux options disponibles', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 4),
        Text('Choisissez comment fournir les informations de votre acte.',
            style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),

        _MethodCard(
          icon: Icons.edit_document,
          title: 'Remplir le formulaire',
          subtitle: 'Saisir le registre, l\'année et la commune',
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

        // Zone d'upload (si "téléverser" choisi)
        if (_method == 'upload') ...[
          const SizedBox(height: 20),
          UploadDocumentCard(
            title: 'Mon extrait de naissance',
            subtitle: _ocrLoading
                ? 'Extraction en cours...'
                : 'Photo ou galerie — pré-remplissage automatique',
            icon: Icons.description_outlined,
            filePath: _extraitNaissance,
            isRequired: true,
            isLoading: _ocrLoading,
            onTap: _ocrLoading ? () {} : _pickExtrait,
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

  // ── ÉTAPE 2 : informations + commune ───────────────────────
  Widget _buildInfoStep(String nomComplet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_ocrSuccess) ...[
          _InfoBanner(
            icon: Icons.auto_fix_high,
            color: AppColors.secondary,
            bg: AppColors.statusGreenLight,
            text: 'Champs pré-remplis depuis votre extrait — vérifiez-les.',
          ),
          const SizedBox(height: 16),
        ],

        _LockedField(
          label: 'Nom complet',
          value: nomComplet,
          hint: 'Récupéré depuis votre inscription',
        ),
        const SizedBox(height: 16),

        AppTextField(
          label: 'Numéro de registre',
          hint: 'Ex: 2020-0142',
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
        Text('Choisissez votre région puis votre commune',
            style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),
        BackendCommuneSelect(
          initialCommuneId: _ocrCommuneId,
          onChanged: (region, commune) => setState(() {
            _regionName = region;
            _commune = commune;
            if (commune != null) _communeError = false;
          }),
          errorText: _communeError
              ? 'Veuillez sélectionner une commune.'
              : null,
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

// ── Champ verrouillé visuellement ──────────────────────────────
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                child: Text(value,
                    style: AppTextStyles.inputText.copyWith(
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
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
      ],
    );
  }
}
