import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/backend_commune_select.dart';
import '../../../../../shared/widgets/upload_document_card.dart';
import '../../../../../shared/widgets/certificate_step_indicator.dart';
import '../../../../../shared/models/commune_model.dart';

/// S09 — Formulaire certificat de décès
class DecesFormScreen extends ConsumerStatefulWidget {
  const DecesFormScreen({super.key});

  @override
  ConsumerState<DecesFormScreen> createState() => _DecesFormScreenState();
}

class _DecesFormScreenState extends ConsumerState<DecesFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Défunt ────────────────────────────────────────────────
  final _nomDefuntCtr = TextEditingController();
  final _registreCtr = TextEditingController();
  DateTime? _dateDeces;
  DateTime? _dateNaissanceDefunt;
  BackendCommuneModel? _commune;
  String? _regionName;
  bool _communeError = false;

  // ── Déclarant ─────────────────────────────────────────────
  final _nomDeclarantCtr = TextEditingController();
  String? _lienParente;

  // Étape courante : 0 = défunt+déclarant, 1 = région/commune, 2 = pièce.
  int _step = 0;

  // ── Documents ────────────────────────────────────────────
  String _typeDoc = 'piece'; // piece | extrait
  String? _docRecto;
  String? _docVerso;

  // ── Draft ────────────────────────────────────────────────
  static const _kNomDefunt    = 'draft_deces_nom_defunt';
  static const _kRegistre     = 'draft_deces_registre';
  static const _kDateDeces    = 'draft_deces_date_deces';
  static const _kNomDeclarant = 'draft_deces_nom_declarant';
  static const _kLien         = 'draft_deces_lien';

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final nomDefunt    = prefs.getString(_kNomDefunt) ?? '';
    final registre     = prefs.getString(_kRegistre) ?? '';
    final dateStr      = prefs.getString(_kDateDeces);
    final nomDeclarant = prefs.getString(_kNomDeclarant) ?? '';
    final lien         = prefs.getString(_kLien);
    if (!mounted) return;
    setState(() {
      if (nomDefunt.isNotEmpty)    _nomDefuntCtr.text = nomDefunt;
      if (registre.isNotEmpty)     _registreCtr.text = registre;
      if (dateStr != null)         _dateDeces = DateTime.tryParse(dateStr);
      if (nomDeclarant.isNotEmpty) _nomDeclarantCtr.text = nomDeclarant;
      if (lien != null)            _lienParente = lien;
    });
    if ((nomDefunt.isNotEmpty || nomDeclarant.isNotEmpty) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.restore_outlined, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Brouillon restauré'),
        ]),
        backgroundColor: AppColors.statusBlue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Effacer',
          textColor: Colors.white,
          onPressed: _clearDraft,
        ),
      ));
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNomDefunt,    _nomDefuntCtr.text.trim());
    await prefs.setString(_kRegistre,     _registreCtr.text.trim());
    await prefs.setString(_kNomDeclarant, _nomDeclarantCtr.text.trim());
    if (_dateDeces != null)   await prefs.setString(_kDateDeces, _dateDeces!.toIso8601String());
    if (_lienParente != null) await prefs.setString(_kLien,      _lienParente!);
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in [_kNomDefunt, _kRegistre, _kDateDeces, _kNomDeclarant, _kLien]) {
      await prefs.remove(k);
    }
  }

  @override
  void dispose() {
    _nomDefuntCtr.dispose();
    _registreCtr.dispose();
    _nomDeclarantCtr.dispose();
    super.dispose();
  }

  // Pièce d'identité = recto + verso ; extrait de naissance = un seul document
  bool get _needsVerso => _typeDoc == 'piece';

  bool get _isValid {
    final baseOk =
        _nomDefuntCtr.text.trim().isNotEmpty &&
        _registreCtr.text.trim().isNotEmpty &&
        _dateDeces != null &&
        _commune != null &&
        _nomDeclarantCtr.text.trim().isNotEmpty &&
        _lienParente != null;
    // Au moins la face principale obligatoire ; verso requis pour CNI seulement
    final docsOk = _docRecto != null && (!_needsVerso || _docVerso != null);
    return baseOk && docsOk;
  }

  // Validité par étape
  bool get _step0Valid =>
      _nomDefuntCtr.text.trim().isNotEmpty &&
      _registreCtr.text.trim().isNotEmpty &&
      _dateDeces != null &&
      _nomDeclarantCtr.text.trim().isNotEmpty &&
      _lienParente != null;
  bool get _step1Valid => _commune != null;
  bool get _step2Valid =>
      _docRecto != null && (!_needsVerso || _docVerso != null);

  void _backStep() => setState(() => _step -= 1);
  void _nextFromInfo() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = 1);
  }
  void _nextFromCommune() {
    if (_commune == null) {
      setState(() => _communeError = true);
      return;
    }
    setState(() => _step = 2);
  }

  Future<void> _pickDoc(String face) async {
    final path = await DocumentUploadHelper.pick(context);
    if (path == null) return;
    setState(() {
      if (face == 'recto') _docRecto = path;
      if (face == 'verso') _docVerso = path;
    });
  }

  void _next() {
    // Étapes déjà validées ; le Form n'est plus dans l'arbre à l'étape 3.
    if (_commune == null) {
      setState(() {
        _step = 1;
        _communeError = true;
      });
      return;
    }
    _clearDraft();
    context.push(AppRoutes.decesRecap, extra: {
      'nom':           _nomDefuntCtr.text.trim(),
      'registre':      _registreCtr.text.trim().toUpperCase(),
      'date_deces':    _dateDeces!.toIso8601String(),
      'commune_id':    _commune!.code,
      'commune_nom':   _commune!.name,
      'region_nom':    _regionName ?? '',
      'nom_declarant': _nomDeclarantCtr.text.trim(),
      'lien_parente':  _lienParente ?? '',
      'type_doc':      _typeDoc,
      'doc_recto':     _docRecto,
      'doc_verso':     _docVerso,
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Défunt et déclarant',
      'Région et commune',
      'Pièce d\'identité',
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Certificat de décès'),
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
                Expanded(
                  child:
                      Text(titles[_step], style: AppTextStyles.bodySmall),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _step == 0
                    ? Form(
                        key: _formKey,
                        onChanged: () {
                          setState(() {});
                          _saveDraft();
                        },
                        child: _buildInfoStep(),
                      )
                    : _step == 1
                        ? _buildCommuneStep()
                        : _buildDocStep(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _step == 0
                  ? PrimaryButton(
                      label: 'Suivant →',
                      onPressed: _nextFromInfo,
                      isEnabled: _step0Valid)
                  : _step == 1
                      ? PrimaryButton(
                          label: 'Suivant →',
                          onPressed: _nextFromCommune,
                          isEnabled: _step1Valid)
                      : PrimaryButton(
                          label: 'Voir le récapitulatif →',
                          onPressed: _next,
                          isEnabled: _step2Valid),
            ),
          ],
        ),
      ),
    );
  }

  // ── ÉTAPE 1 : défunt + déclarant ───────────────────────────
  Widget _buildInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.person_off_outlined,
          title: 'Informations du défunt',
          color: AppColors.statusRed,
          bg: AppColors.statusRedLight,
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Nom complet du défunt',
          hint: 'Ex: Mamadou Ba',
          controller: _nomDefuntCtr,
          validator: Validators.fullName,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.person_outline,
              color: AppColors.textSecondary, size: 20),
        ),
        const SizedBox(height: 16),
        DateTextField(
          label: 'Date de décès',
          selectedDate: _dateDeces,
          // Règle backend : un acte de décès ne peut être établi si la date
          // remonte à plus d'un an. On borne donc le sélecteur en conséquence.
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
          validator: (_) => Validators.dateDeces(_dateDeces),
          onDateSelected: (d) {
            setState(() => _dateDeces = d);
            _saveDraft();
          },
        ),
        const SizedBox(height: 16),
        DateTextField(
          label: 'Date de naissance du défunt (optionnel)',
          selectedDate: _dateNaissanceDefunt,
          validator: (_) => null,
          onDateSelected: (d) => setState(() => _dateNaissanceDefunt = d),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Numéro de registre',
          hint: 'Ex: 2023-0015',
          controller: _registreCtr,
          keyboardType: TextInputType.text,
          maxLength: 12,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z/-]')),
            LengthLimitingTextInputFormatter(12),
          ],
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Le numéro de registre est requis.';
            }
            if (v.trim().length > 12) {
              return 'Maximum 12 caractères.';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
          suffixIcon: GestureDetector(
            onTap: () => _showTooltipRegistre(context),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.info_outline,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _SectionTitle(
          icon: Icons.account_circle_outlined,
          title: 'Informations du déclarant',
          color: AppColors.primary,
          bg: AppColors.primary.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 4),
        Text('La personne qui effectue la demande',
            style: AppTextStyles.bodySmall),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Nom complet du déclarant',
          hint: 'Votre nom complet',
          controller: _nomDeclarantCtr,
          validator: Validators.fullName,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.person_outline,
              color: AppColors.textSecondary, size: 20),
        ),
        const SizedBox(height: 16),
        _LienParenteField(
          value: _lienParente,
          onChanged: (v) {
            setState(() => _lienParente = v);
            _saveDraft();
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── ÉTAPE 2 : région + commune ─────────────────────────────
  Widget _buildCommuneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Région et commune du décès',
            style: AppTextStyles.headlineSmall),
        const SizedBox(height: 4),
        Text('Commune où le décès a été enregistré',
            style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),
        BackendCommuneSelect(
          onChanged: (region, commune) => setState(() {
            _regionName = region;
            _commune = commune;
            if (commune != null) _communeError = false;
          }),
          errorText:
              _communeError ? 'Veuillez sélectionner une commune.' : null,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── ÉTAPE 3 : pièce d'identité ─────────────────────────────
  Widget _buildDocStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.credit_card_outlined,
          title: 'Pièce d\'identité du déclarant',
          color: AppColors.statusRed,
          bg: AppColors.statusRedLight,
          badge: 'Obligatoire',
        ),
        const SizedBox(height: 8),
        Text(
          'Nécessaire pour vous identifier et assurer la traçabilité de la demande.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 14),
        _TypeDocPicker(
          value: _typeDoc,
          onChanged: (v) => setState(() {
            _typeDoc = v;
            _docRecto = null;
            _docVerso = null;
          }),
        ),
        const SizedBox(height: 14),
        UploadDocumentCard(
          title: _typeDoc == 'extrait'
              ? 'Extrait de naissance'
              : 'Pièce d\'identité — Recto',
          subtitle: _typeDoc == 'extrait'
              ? 'Votre acte ou extrait de naissance'
              : 'Face avant (CNI, passeport, permis…)',
          icon: _typeDoc == 'extrait'
              ? Icons.article_outlined
              : Icons.credit_card_outlined,
          filePath: _docRecto,
          isRequired: true,
          onTap: () => _pickDoc('recto'),
          onRemove: _docRecto != null
              ? () => setState(() => _docRecto = null)
              : null,
        ),
        if (_needsVerso) ...[
          const SizedBox(height: 12),
          UploadDocumentCard(
            title: 'Pièce d\'identité — Verso',
            subtitle: 'Face arrière de la pièce',
            icon: Icons.credit_card_outlined,
            filePath: _docVerso,
            isRequired: true,
            onTap: () => _pickDoc('verso'),
            onRemove: _docVerso != null
                ? () => setState(() => _docVerso = null)
                : null,
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  void _showTooltipRegistre(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Numéro de registre'),
        ]),
        content: const Text(
          'Le numéro de registre figure sur l\'acte de décès ou le certificat '
          'médical de décès, généralement sous la forme "SN-XXXXXX-C".\n\n'
          'Si vous ne l\'avez pas, laissez votre centre d\'état civil vous guider.',
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
}

// ── Sélecteur type de document (2 options) ───────────────────
class _TypeDocPicker extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  static const _options = [
    (
      'piece',
      Icons.credit_card_outlined,
      'Pièce d\'identité',
      'CNI, Passeport, Permis…',
    ),
    (
      'extrait',
      Icons.article_outlined,
      'Extrait de naissance',
      'Acte ou extrait de naissance',
    ),
  ];

  const _TypeDocPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final (val, icon, label, sub) = opt;
        final selected = value == val;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(children: [
                Icon(icon,
                    size: 22,
                    color: selected ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                          )),
                      Text(sub,
                          style: AppTextStyles.caption.copyWith(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppColors.textSecondary,
                          )),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Lien de parenté avec le défunt ───────────────────────────
class _LienParenteField extends StatelessWidget {
  final String? value;
  final void Function(String?) onChanged;

  static const _options = [
    'Père / Mère',
    'Enfant',
    'Époux / Épouse',
    'Frère / Sœur',
    'Grand-parent',
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
          Text('Lien avec le défunt', style: AppTextStyles.inputLabel),
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
          hint: Text('Votre lien avec le défunt', style: AppTextStyles.inputHint),
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
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
              v == null ? 'Veuillez indiquer votre lien avec le défunt.' : null,
        ),
      ],
    );
  }
}

// ── En-tête de section ───────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color bg;
  final String? badge;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
    required this.bg,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: AppTextStyles.headlineSmall.copyWith(color: color)),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge!,
                  style: AppTextStyles.caption.copyWith(
                      color: color, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
