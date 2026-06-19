import 'package:flutter/material.dart';
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

/// S10 — Formulaire certificat de mariage (refonte complète)
class MariageFormScreen extends ConsumerStatefulWidget {
  const MariageFormScreen({super.key});

  @override
  ConsumerState<MariageFormScreen> createState() => _MariageFormScreenState();
}

class _MariageFormScreenState extends ConsumerState<MariageFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Rôle du demandeur ─────────────────────────────────────
  String _role = 'epoux'; // epoux | epouse

  // ── Informations du mariage ───────────────────────────────
  final _nomDemandeurCtr  = TextEditingController();
  final _nomConjointCtr   = TextEditingController();
  final _registreCtr      = TextEditingController();
  int? _anneeMarriage;
  BackendCommuneModel? _commune;
  String? _regionName;
  bool _communeError = false;

  // Étape courante : 0 = infos (jusqu'au n° de registre), 1 = région/commune,
  // 2 = pièce d'identité.
  int _step = 0;

  // ── Documents ─────────────────────────────────────────────
  String _typeDoc  = 'piece'; // piece | extrait
  String? _docRecto;
  String? _docVerso;

  // ── Draft ─────────────────────────────────────────────────
  static const _kRole      = 'draft_mariage_role';
  static const _kDemandeur = 'draft_mariage_demandeur';
  static const _kConjoint  = 'draft_mariage_conjoint';
  static const _kRegistre  = 'draft_mariage_registre';
  static const _kAnnee     = 'draft_mariage_annee';

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final role      = prefs.getString(_kRole);
    final demandeur = prefs.getString(_kDemandeur) ?? '';
    final conjoint  = prefs.getString(_kConjoint) ?? '';
    final registre  = prefs.getString(_kRegistre) ?? '';
    final annee     = prefs.getInt(_kAnnee);
    if (!mounted) return;
    setState(() {
      if (role != null)            _role = role;
      if (demandeur.isNotEmpty)    _nomDemandeurCtr.text = demandeur;
      if (conjoint.isNotEmpty)     _nomConjointCtr.text = conjoint;
      if (registre.isNotEmpty)     _registreCtr.text = registre;
      if (annee != null)           _anneeMarriage = annee;
    });
    if ((demandeur.isNotEmpty || conjoint.isNotEmpty) && mounted) {
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
    await prefs.setString(_kRole,      _role);
    await prefs.setString(_kDemandeur, _nomDemandeurCtr.text.trim());
    await prefs.setString(_kConjoint,  _nomConjointCtr.text.trim());
    await prefs.setString(_kRegistre,  _registreCtr.text.trim());
    if (_anneeMarriage != null) await prefs.setInt(_kAnnee, _anneeMarriage!);
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in [_kRole, _kDemandeur, _kConjoint, _kRegistre, _kAnnee]) {
      await prefs.remove(k);
    }
  }

  @override
  void dispose() {
    _nomDemandeurCtr.dispose();
    _nomConjointCtr.dispose();
    _registreCtr.dispose();
    super.dispose();
  }

  bool get _needsVerso => _typeDoc == 'piece';

  bool get _isValid {
    final baseOk =
        _nomDemandeurCtr.text.trim().isNotEmpty &&
        _nomConjointCtr.text.trim().isNotEmpty &&
        _registreCtr.text.trim().isNotEmpty &&
        _anneeMarriage != null &&
        _commune != null;
    final docsOk = _docRecto != null && (!_needsVerso || _docVerso != null);
    return baseOk && docsOk;
  }

  // Validité par étape
  bool get _step0Valid =>
      _nomDemandeurCtr.text.trim().isNotEmpty &&
      _nomConjointCtr.text.trim().isNotEmpty &&
      _registreCtr.text.trim().isNotEmpty &&
      _anneeMarriage != null;
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
    // Les étapes 1 (infos) et 2 (commune) ont déjà été validées : le Form
    // n'est plus dans l'arbre à l'étape 3, donc on ne le revalide pas ici.
    if (_commune == null) {
      setState(() {
        _step = 1;
        _communeError = true;
      });
      return;
    }
    _clearDraft();
    context.push(AppRoutes.mariageRecap, extra: {
      'role':           _role,
      'nom_demandeur':  _nomDemandeurCtr.text.trim(),
      'nom_conjoint':   _nomConjointCtr.text.trim(),
      // On conserve aussi les clés epoux/epouse pour le provider existant
      'nom_epoux':  _role == 'epoux'
          ? _nomDemandeurCtr.text.trim()
          : _nomConjointCtr.text.trim(),
      'nom_epouse': _role == 'epouse'
          ? _nomDemandeurCtr.text.trim()
          : _nomConjointCtr.text.trim(),
      'registre':       _registreCtr.text.trim().toUpperCase(),
      'annee_marriage': _anneeMarriage,
      'commune_id':     _commune!.code,
      'commune_nom':    _commune!.name,
      'region_nom':     _regionName ?? '',
      'type_doc':       _typeDoc,
      'doc_recto':      _docRecto,
      'doc_verso':      _docVerso,
    });
  }

  // ── Labels dynamiques selon le rôle ──────────────────────
  String get _labelDemandeur =>
      _role == 'epoux' ? 'Votre nom complet (Époux)' : 'Votre nom complet (Épouse)';

  String get _labelConjoint =>
      _role == 'epoux' ? "Nom complet de votre épouse" : "Nom complet de votre époux";

  String get _hintConjoint =>
      _role == 'epoux' ? 'Ex: Aïssatou Fall' : 'Ex: Oumar Diop';

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Informations du mariage',
      'Région et commune',
      'Pièce d\'identité',
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Certificat de mariage'),
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

  // ── ÉTAPE 1 : rôle + infos jusqu'au numéro de registre ─────
  Widget _buildInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.favorite_border_outlined,
          title: 'Vous êtes…',
          color: AppColors.secondary,
          bg: AppColors.secondary.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 14),
        _RolePicker(
          value: _role,
          onChanged: (v) {
            setState(() => _role = v);
            _saveDraft();
          },
        ),
        const SizedBox(height: 28),
        _SectionTitle(
          icon: Icons.villa_outlined,
          title: 'Informations du mariage',
          color: AppColors.primary,
          bg: AppColors.primary.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: _labelDemandeur,
          hint: _role == 'epoux' ? 'Ex: Oumar Diop' : 'Ex: Aïssatou Fall',
          controller: _nomDemandeurCtr,
          validator: Validators.fullName,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.person_outline,
              color: AppColors.textSecondary, size: 20),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: _labelConjoint,
          hint: _hintConjoint,
          controller: _nomConjointCtr,
          validator: Validators.fullName,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.person_outline,
              color: AppColors.textSecondary, size: 20),
        ),
        const SizedBox(height: 16),
        _YearPickerField(
          selectedYear: _anneeMarriage,
          onYearSelected: (y) {
            setState(() => _anneeMarriage = y);
            _saveDraft();
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Numéro de registre du mariage',
          hint: 'Ex: MR-2020-001',
          controller: _registreCtr,
          validator: Validators.mariageRegistre,
          textInputAction: TextInputAction.done,
          suffixIcon: GestureDetector(
            onTap: () => _showTooltipRegistre(context),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.info_outline,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
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
        Text('Région et commune du mariage',
            style: AppTextStyles.headlineSmall),
        const SizedBox(height: 4),
        Text('Commune où le mariage a été enregistré',
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
          title: 'Pièce d\'identité du demandeur',
          color: AppColors.statusRed,
          bg: AppColors.statusRedLight,
          badge: 'Obligatoire',
        ),
        const SizedBox(height: 8),
        Text(
          'Nécessaire pour vous identifier et assurer la traçabilité.',
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
          'Le numéro de registre figure sur votre certificat de mariage, '
          'généralement sous la forme "MR-AAAA-XXX".\n\n'
          'Vous pouvez le trouver en haut ou en bas de l\'acte de mariage.',
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

// ── Sélecteur de rôle ────────────────────────────────────────
class _RolePicker extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _RolePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _RoleCard(
        val: 'epoux',
        icon: Icons.man_outlined,
        label: 'L\'Époux',
        selected: value == 'epoux',
        onTap: () => onChanged('epoux'),
      ),
      const SizedBox(width: 12),
      _RoleCard(
        val: 'epouse',
        icon: Icons.woman_outlined,
        label: 'L\'Épouse',
        selected: value == 'epouse',
        onTap: () => onChanged('epouse'),
      ),
    ]);
  }
}

class _RoleCard extends StatelessWidget {
  final String val;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard({
    required this.val,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Column(children: [
            Icon(icon,
                size: 32,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Sélecteur type de document ────────────────────────────────
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
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
                    color:
                        selected ? Colors.white : AppColors.textSecondary),
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

// ── Section title ─────────────────────────────────────────────
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
      child: Row(children: [
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
      ]),
    );
  }
}

// ── Sélecteur d'année ─────────────────────────────────────────
class _YearPickerField extends StatelessWidget {
  final int? selectedYear;
  final void Function(int) onYearSelected;

  const _YearPickerField(
      {required this.selectedYear, required this.onYearSelected});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Année de mariage',
      hint: 'Sélectionner l\'année',
      readOnly: true,
      controller:
          TextEditingController(text: selectedYear?.toString() ?? ''),
      suffixIcon: const Icon(Icons.calendar_today_outlined,
          color: AppColors.textSecondary, size: 20),
      onTap: () => _showYearPicker(context),
    );
  }

  void _showYearPicker(BuildContext context) {
    final now = DateTime.now().year;
    int currentSelection = selectedYear ?? now;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SizedBox(
          height: 300,
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Année de mariage',
                  style: AppTextStyles.headlineSmall),
            ),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                itemExtent: 48,
                perspective: 0.005,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                controller: FixedExtentScrollController(
                    initialItem: now - currentSelection),
                onSelectedItemChanged: (i) =>
                    setS(() => currentSelection = now - i),
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, i) {
                    final year = now - i;
                    if (year < 1900) return null;
                    return Center(
                      child: Text(
                        year.toString(),
                        style: year == currentSelection
                            ? AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.primary)
                            : AppTextStyles.bodyLarge,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: 'Confirmer $currentSelection',
                onPressed: () {
                  onYearSelected(currentSelection);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
