#!/bin/bash
# ============================================================
# TERANGA CIVIL — Certificat Naissance V2
# Usage : bash fix_naissance_v2.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🚀 TERANGA CIVIL — Certificat Naissance V2"
echo ""

# ════════════════════════════════════════════════════════════
# 1. WIDGET UPLOAD DOCUMENT (réutilisable)
# ════════════════════════════════════════════════════════════
cat > lib/shared/widgets/upload_document_card.dart << 'DART'
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Card d'upload de document (photo ou galerie).
/// Affiche une prévisualisation si un fichier est sélectionné.
class UploadDocumentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? filePath;      // null = rien sélectionné
  final bool isRequired;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const UploadDocumentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.filePath,
    this.isRequired = false,
    this.isLoading = false,
    this.onRemove,
  });

  bool get _hasFile => filePath != null && filePath!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hasFile ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _hasFile
              ? AppColors.statusGreenLight
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hasFile ? AppColors.secondary : AppColors.border,
            width: _hasFile ? 2 : 1,
          ),
        ),
        child: _hasFile
            ? _FilePreview(
                filePath: filePath!,
                title: title,
                onRemove: onRemove,
                onReplace: onTap,
              )
            : _EmptyState(
                title: title,
                subtitle: subtitle,
                icon: icon,
                isRequired: isRequired,
                isLoading: isLoading,
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isRequired;
  final bool isLoading;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isRequired,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.secondary),
                      ),
                    ),
                  )
                : Icon(icon, color: AppColors.textSecondary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: AppTextStyles.labelLarge),
                    if (isRequired) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusRedLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Requis',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.statusRed,
                              fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.add_circle_outline,
              color: AppColors.secondary, size: 22),
        ],
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  final String filePath;
  final String title;
  final VoidCallback? onRemove;
  final VoidCallback onReplace;

  const _FilePreview({
    required this.filePath,
    required this.title,
    required this.onReplace,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Miniature
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(filePath),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: AppColors.border,
                child: const Icon(Icons.insert_drive_file_outlined,
                    color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.secondary, size: 14),
                    const SizedBox(width: 4),
                    Text('Document ajouté',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondary)),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onReplace,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.textSecondary),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.statusRedLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline,
                        size: 16, color: AppColors.statusRed),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Utilitaire pour ouvrir la caméra ou la galerie
class DocumentUploadHelper {
  static final _picker = ImagePicker();

  static Future<String?> pick(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ajouter un document',
                  style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: Text('Prendre une photo',
                    style: AppTextStyles.bodyLarge),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onTap: () async {
                  final nav = Navigator.of(ctx);
                  final file = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  nav.pop(file?.path);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: Text('Choisir depuis la galerie',
                    style: AppTextStyles.bodyLarge),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onTap: () async {
                  final nav = Navigator.of(ctx);
                  final file = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  nav.pop(file?.path);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DART
echo "  ✅ upload_document_card.dart"

# ════════════════════════════════════════════════════════════
# 2. S08 — Choix bénéficiaire (inchangé visuellement)
# ════════════════════════════════════════════════════════════
cat > lib/features/certificates/naissance/presentation/screens/beneficiary_choice_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// S08 — Choix bénéficiaire
class BeneficiaryChoiceScreen extends StatelessWidget {
  const BeneficiaryChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Pour qui ?', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 4),
              Text(
                'Sélectionnez le bénéficiaire du certificat',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 32),
              _ChoiceCard(
                icon: Icons.person_outlined,
                title: 'Pour moi',
                subtitle: 'Utiliser mon nom d\'inscription\net choisir ma commune',
                onTap: () => context.push(AppRoutes.naissanceRecapSelf),
              ),
              const SizedBox(height: 12),
              _ChoiceCard(
                icon: Icons.group_outlined,
                title: 'Pour une autre personne',
                subtitle: 'Remplir les informations manuellement\n+ CNI obligatoire',
                onTap: () => context.push(AppRoutes.naissanceOtherPerson),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.statusGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security_outlined,
                        color: AppColors.secondary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Vos données sont protégées et chiffrées.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.textHint, size: 16),
          ],
        ),
      ),
    );
  }
}
DART
echo "  ✅ beneficiary_choice_screen.dart"

# ════════════════════════════════════════════════════════════
# 3. S08A — Formulaire "Pour moi"
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
import '../../../../../shared/widgets/cascaded_commune_select.dart';
import '../../../../../shared/models/commune_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

/// S08A — Formulaire "Pour moi"
/// Nom pré-rempli (non modifiable), commune + registre + date naissance
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
  DepartementModel? _departement;

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
    if (!_formKey.currentState!.validate() || _commune == null) return;
    final user = ref.read(authProvider).user!;
    context.push(AppRoutes.naissanceRecapSelf + '/recap', extra: {
      'nom': user.nomComplet,
      'registre': _registreCtr.text.trim(),
      'date_naissance': _dateNaissance!.toIso8601String(),
      'commune_id': _commune!.id,
      'commune_nom': _commune!.nom,
      'region_nom': _region?.nom ?? '',
      'for_self': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
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
                        'Renseignez les informations pour votre certificat',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 24),

                      // ── Nom complet — non modifiable ────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nom complet', style: AppTextStyles.inputLabel),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
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
                                  child: Text(
                                    user.nomComplet,
                                    style: AppTextStyles.inputText.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.lock_outline,
                                    color: AppColors.textHint, size: 16),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nom récupéré depuis votre inscription',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textHint),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Numéro de registre (max 5 chiffres) ─
                      AppTextField(
                        label: 'Numéro de registre',
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
                          if (v.trim().length > 5) {
                            return 'Maximum 5 chiffres.';
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
                      const SizedBox(height: 20),

                      // ── Région / Commune déclarée ───────────
                      Text('Commune déclarée',
                          style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Sélectionnez la région et commune où vous êtes déclaré(e)',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      CascadedCommuneSelect(
                        onChanged: (r, d, c) => setState(() {
                          _region = r;
                          _departement = d;
                          _commune = c;
                        }),
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
DART
echo "  ✅ recap_self_screen.dart (formulaire Pour moi)"

# ════════════════════════════════════════════════════════════
# 4. S08B — Formulaire "Pour une autre personne"
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
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/cascaded_commune_select.dart';
import '../../../../../shared/widgets/upload_document_card.dart';
import '../../../../../shared/models/commune_model.dart';

/// S08B — Formulaire "Pour une autre personne"
/// Mêmes champs que "Pour moi" + CNI recto/verso obligatoire
/// + extrait de naissance optionnel
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

  // Documents
  String? _cniRecto;
  String? _cniVerso;
  String? _extraitNaissance; // optionnel

  @override
  void dispose() {
    _nomCtr.dispose();
    _registreCtr.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nomCtr.text.trim().isNotEmpty &&
      _registreCtr.text.trim().isNotEmpty &&
      _registreCtr.text.trim().length <= 5 &&
      _dateNaissance != null &&
      _commune != null &&
      _cniRecto != null &&
      _cniVerso != null;

  Future<void> _pickDocument(String type) async {
    final path = await DocumentUploadHelper.pick(context);
    if (path != null) {
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
            break;
        }
      });
    }
  }

  void _goToRecap() {
    if (!_formKey.currentState!.validate() || _commune == null) return;
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
                      Text('Informations du bénéficiaire',
                          style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 20),

                      // ── Nom complet ─────────────────────────
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

                      // ── Numéro de registre (max 5 chiffres) ─
                      AppTextField(
                        label: 'Numéro de registre',
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
                          if (v.trim().length > 5) {
                            return 'Maximum 5 chiffres.';
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
                      const SizedBox(height: 20),

                      // ── Commune déclarée ────────────────────
                      Text('Commune déclarée',
                          style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Commune où la personne est officiellement déclarée',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      CascadedCommuneSelect(
                        onChanged: (r, d, c) => setState(() {
                          _region = r;
                          _commune = c;
                        }),
                      ),
                      const SizedBox(height: 28),

                      // ── Documents obligatoires ──────────────
                      Row(
                        children: [
                          Text('Pièce d\'identité (CNI)',
                              style: AppTextStyles.headlineSmall),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.statusRedLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Obligatoire',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.statusRed,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
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
                      const SizedBox(height: 28),

                      // ── Document optionnel ──────────────────
                      Row(
                        children: [
                          Text('Extrait de naissance',
                              style: AppTextStyles.headlineSmall),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.statusBlueLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Optionnel',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.statusBlue,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Si disponible, joignez l\'extrait de naissance existant.',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      UploadDocumentCard(
                        title: 'Extrait de naissance',
                        subtitle: 'Document existant (si disponible)',
                        icon: Icons.description_outlined,
                        filePath: _extraitNaissance,
                        isRequired: false,
                        onTap: () => _pickDocument('extrait'),
                        onRemove: _extraitNaissance != null
                            ? () => setState(() => _extraitNaissance = null)
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
DART
echo "  ✅ other_person_screen.dart"

# ════════════════════════════════════════════════════════════
# 5. S08C / S08A-recap — Récapitulatif commun (pour moi & autre)
# ════════════════════════════════════════════════════════════
cat > lib/features/certificates/naissance/presentation/screens/recap_other_screen.dart << 'DART'
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/recap_card.dart';
import '../providers/naissance_provider.dart';

/// Récapitulatif — utilisé pour "Pour moi" et "Pour une autre personne"
class RecapOtherScreen extends ConsumerWidget {
  final Map<String, dynamic> formData;
  const RecapOtherScreen({super.key, required this.formData});

  bool get _forSelf => formData['for_self'] as bool? ?? false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(naissanceProvider).isLoading;
    final dateNaissance = DateTime.tryParse(
            formData['date_naissance'] as String? ?? '') ??
        DateTime(1990);

    final cniRecto = formData['cni_recto'] as String?;
    final cniVerso = formData['cni_verso'] as String?;
    final extrait = formData['extrait_naissance'] as String?;

    Future<void> submit() async {
      try {
        final id = await ref.read(naissanceProvider.notifier).submit(
              communeId: formData['commune_id'] as String,
              nom: formData['nom'] as String,
              dateNaissance: dateNaissance,
              registre: formData['registre'] as String,
              forSelf: _forSelf,
            );
        if (!context.mounted) return;
        context.push(AppRoutes.payment, extra: {
          'dossier_id': id,
          'type': 'naissance',
          'montant': AppConstants.naissanceFeesFCFA,
          'label': 'Certificat de naissance',
        });
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        );
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vérifiez vos informations',
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Text('Assurez-vous que tout est correct avant de payer',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 24),

              // ── Tableau récapitulatif ───────────────────────
              RecapCard(
                title: 'Certificat de naissance',
                fields: [
                  RecapField(
                    label: 'Bénéficiaire',
                    value: _forSelf ? 'Pour moi' : 'Pour une autre personne',
                    icon: Icons.info_outline,
                    valueColor: _forSelf
                        ? AppColors.secondary
                        : AppColors.statusBlue,
                  ),
                  RecapField(
                    label: 'Nom complet',
                    value: formData['nom'] as String,
                    icon: Icons.person_outline,
                  ),
                  RecapField(
                    label: 'N° de registre',
                    value: formData['registre'] as String,
                    icon: Icons.badge_outlined,
                  ),
                  RecapField(
                    label: 'Date de naissance',
                    value: AppFormatters.dateToFrench(dateNaissance),
                    icon: Icons.calendar_today_outlined,
                  ),
                  RecapField(
                    label: 'Commune',
                    value: formData['commune_nom'] as String,
                    icon: Icons.location_on_outlined,
                  ),
                  RecapField(
                    label: 'Frais',
                    value: AppFormatters.amountFCFA(
                        AppConstants.naissanceFeesFCFA),
                    icon: Icons.payment_outlined,
                    valueColor: AppColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Documents joints (si autre personne) ─────────
              if (!_forSelf && (cniRecto != null || cniVerso != null)) ...[
                Text('Documents joints', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                if (cniRecto != null)
                  _DocThumb(path: cniRecto, label: 'CNI Recto'),
                if (cniVerso != null) ...[
                  const SizedBox(height: 8),
                  _DocThumb(path: cniVerso, label: 'CNI Verso'),
                ],
                if (extrait != null) ...[
                  const SizedBox(height: 8),
                  _DocThumb(path: extrait, label: 'Extrait de naissance'),
                ],
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Confirmer et payer — '
                    '${AppFormatters.amountFCFA(AppConstants.naissanceFeesFCFA)}',
                onPressed: submit,
                isLoading: isLoading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

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
DART
echo "  ✅ recap_other_screen.dart (récapitulatif unifié)"

# ════════════════════════════════════════════════════════════
# 6. Mise à jour app_router — nouvelle route recap pour "pour moi"
# ════════════════════════════════════════════════════════════
python3 - << 'PY'
with open('lib/core/router/app_router.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Mettre à jour la route naissanceRecapSelf pour passer par RecapOtherScreen
# (récapitulatif commun aux deux flows)
old = """      GoRoute(
        path: AppRoutes.naissanceRecapSelf,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const RecapSelfScreen(),
        ),
      ),"""

new = """      GoRoute(
        path: AppRoutes.naissanceRecapSelf,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const RecapSelfScreen(),
        ),
        routes: [
          GoRoute(
            path: 'recap',
            pageBuilder: (context, state) {
              final data = state.extra as Map<String, dynamic>? ?? {};
              return _slidePage(
                state: state,
                child: RecapOtherScreen(formData: data),
              );
            },
          ),
        ],
      ),"""

content = content.replace(old, new)
with open('lib/core/router/app_router.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✅ app_router.dart — route recap 'pour moi' ajoutée")
PY

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Certificat Naissance V2 installé !"
echo ""
echo "Flow Pour moi :"
echo "  Choix → Formulaire (nom verrouillé + registre 5ch + date + commune)"
echo "        → Récapitulatif → Paiement"
echo ""
echo "Flow Pour une autre personne :"
echo "  Choix → Formulaire (tous modifiables + CNI recto/verso obligatoire"
echo "          + extrait optionnel) → Récapitulatif → Paiement"
echo ""
echo "  flutter run"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
