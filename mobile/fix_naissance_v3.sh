#!/bin/bash
# ============================================================
# TERANGA CIVIL — Fix naissance V3
# 1. "Pour moi" — fix chargement user
# 2. "Pour une autre" — OCR mock sur upload extrait
# Usage : bash fix_naissance_v3.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🔧 Fix Naissance V3..."
echo ""

# ════════════════════════════════════════════════════════════
# FIX 1 — Charger le profil user au démarrage (splash)
# Le user était null car getMe() n'était jamais appelé
# ════════════════════════════════════════════════════════════
cat > lib/features/auth/presentation/screens/splash_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/assets_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

/// S01 — Splash Screen
/// Charge le profil utilisateur si un token existe
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(AppConstants.splashDuration);
    if (!mounted) return;

    final repo = ref.read(authRepositoryProvider);
    final token = await repo.getToken();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // ── Charger le profil utilisateur ──────────────────
      try {
        final user = await repo.getMe();
        if (mounted) {
          // Injecter le user dans l'état auth
          ref.read(authProvider.notifier).setUser(user);
        }
      } catch (_) {
        // Si getMe échoue (token expiré), on redirige vers login
        if (mounted) context.go(AppRoutes.login);
        return;
      }
      if (mounted) context.go(AppRoutes.home);
    } else {
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          Assets.logoTeranga,
                          width: 100,
                          height: 100,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'TERANGA ',
                              style: AppTextStyles.appNameBold.copyWith(
                                color: AppColors.textOnPrimary,
                                fontSize: 26,
                              ),
                            ),
                            Text(
                              'CIVIL',
                              style: AppTextStyles.appNameRegular.copyWith(
                                color: AppColors.textOnPrimary,
                                fontSize: 26,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 2,
                          color: AppColors.secondary,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        Text(
                          AppConstants.appTagline,
                          style: AppTextStyles.tagline.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.secondary),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chargement...',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DART
echo "  ✅ splash_screen.dart — getMe() appelé au démarrage"

# ════════════════════════════════════════════════════════════
# FIX 1b — Ajouter setUser() dans AuthNotifier
# + charger le user après login aussi
# ════════════════════════════════════════════════════════════
python3 - << 'PY'
with open('lib/features/auth/presentation/providers/auth_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Ajouter setUser() dans AuthNotifier après clearError()
old = "  void clearError() => state = state.copyWith(clearError: true);"
new = """  void clearError() => state = state.copyWith(clearError: true);

  /// Injecte le profil utilisateur dans l'état (appelé depuis splash)
  void setUser(UserModel user) {
    state = state.copyWith(user: user, isAuthenticated: true);
  }"""

content = content.replace(old, new)

# Charger le user après login réussi
old_login = """      state = state.copyWith(
        isLoading: false,
        isAuthenticated: !result.needsOtp,
      );
      return (needsOtp: result.needsOtp);"""

new_login = """      // Charger le profil après login réussi
      if (!result.needsOtp) {
        try {
          final user = await _repo.getMe();
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: user,
          );
        } catch (_) {
          state = state.copyWith(isLoading: false, isAuthenticated: true);
        }
      } else {
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
      return (needsOtp: result.needsOtp);"""

content = content.replace(old_login, new_login)

# Charger le user après verifyOtp aussi
old_verify = """      await _verifyOtp(identifier: identifier, code: code);
      state = state.copyWith(isLoading: false, isAuthenticated: true);"""

new_verify = """      await _verifyOtp(identifier: identifier, code: code);
      // Charger le profil après vérification OTP
      try {
        final user = await _repo.getMe();
        state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
      } catch (_) {
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      }"""

content = content.replace(old_verify, new_verify)

with open('lib/features/auth/presentation/providers/auth_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✅ auth_provider.dart — setUser() + chargement profil après login/OTP")
PY

# ════════════════════════════════════════════════════════════
# FIX 2 — OCR mock sur upload extrait de naissance
# Endpoint : POST /ocr/extract-naissance
# Mock retourne des données pré-remplies simulées
# ════════════════════════════════════════════════════════════

# 2a. Ajouter endpoint OCR dans mock_service
python3 - << 'PY'
with open('lib/core/mock/mock_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Ajouter la méthode extractNaissanceOcr à la fin avant le dernier }
ocr_method = """
  /// Simule l'OCR d'un extrait de naissance
  /// En production : POST /ocr/extract-naissance avec l'image en multipart
  static Future<Map<String, dynamic>> extractNaissanceOcr() async {
    await delay(1500); // Simule le temps de traitement OCR
    // Données simulées — seront remplacées par la vraie réponse backend
    return {
      'success': true,
      'data': {
        'nom': 'Moussa Diallo',
        'registre': '45678',
        'date_naissance': '1995-08-22',
        'commune_id': 'DK-PI-01',
        'commune_nom': 'Pikine Est',
        'region_id': 'DK',
        'region_nom': 'Dakar',
        'departement_id': 'DK-PI',
        'departement_nom': 'Pikine',
      },
    };
  }
"""

# Insérer avant la dernière accolade fermante du fichier
last_brace = content.rfind('}')
content = content[:last_brace] + ocr_method + content[last_brace:]

with open('lib/core/mock/mock_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✅ mock_service.dart — extractNaissanceOcr() ajouté")
PY

# 2b. Ajouter endpoint OCR dans mock_interceptor
python3 - << 'PY'
with open('lib/core/network/mock_interceptor.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """    debugPrint('[MOCK] Route non gérée: $method $path');
    return {'success': true};"""

new = """    // ── OCR ──────────────────────────────────────────────
    if (path == '/ocr/extract-naissance') {
      return MockService.extractNaissanceOcr();
    }

    debugPrint('[MOCK] Route non gérée: $method $path');
    return {'success': true};"""

content = content.replace(old, new)
with open('lib/core/network/mock_interceptor.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✅ mock_interceptor.dart — route /ocr/extract-naissance ajoutée")
PY

# 2c. Datasource OCR
cat > lib/features/certificates/naissance/data/remote_datasource.dart << 'DART'
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/errors/exceptions.dart';

class NaissanceRemoteDatasource {
  final DioClient client;
  const NaissanceRemoteDatasource({required this.client});

  /// Envoie l'image de l'extrait au backend pour extraction OCR.
  /// Retourne les données extraites : nom, registre, date, commune...
  /// TODO prod : utiliser MultipartFile pour envoyer la vraie image
  Future<Map<String, dynamic>> extractOcr(String imagePath) async {
    try {
      // En production, envoyer l'image en multipart :
      // final formData = FormData.fromMap({
      //   'image': await MultipartFile.fromFile(imagePath, filename: 'extrait.jpg'),
      // });
      // final res = await client.post('/ocr/extract-naissance', data: formData);

      // En mode mock : simple POST sans fichier
      final res = await client.post('/ocr/extract-naissance', data: {
        'image_path': imagePath,
      });

      if (res.statusCode == 200 && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      throw const ApiException(message: 'Extraction OCR échouée');
    } on DioException {
      throw const ApiException(message: 'Erreur lors de l\'extraction OCR');
    }
  }
}
DART
echo "  ✅ naissance remote_datasource.dart — OCR"

# 2d. Mettre à jour other_person_screen avec OCR
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
import '../../../../../shared/widgets/cascaded_commune_select.dart';
import '../../../../../shared/widgets/upload_document_card.dart';
import '../../../../../shared/models/commune_model.dart';
import '../../data/remote_datasource.dart';

/// S08B — Formulaire "Pour une autre personne"
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
  DepartementModel? _departement;

  // Documents
  String? _cniRecto;
  String? _cniVerso;
  String? _extraitNaissance;

  // OCR
  bool _ocrLoading = false;
  String? _ocrMessage;

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
          break;
      }
    });

    // Si c'est l'extrait → lancer l'OCR automatiquement
    if (type == 'extrait' && path.isNotEmpty) {
      await _runOcr(path);
    }
  }

  /// Lance l'OCR sur l'extrait uploadé et pré-remplit le formulaire
  Future<void> _runOcr(String imagePath) async {
    setState(() {
      _ocrLoading = true;
      _ocrMessage = null;
    });

    try {
      final ds = NaissanceRemoteDatasource(client: ref.read(dioClientProvider));
      final data = await ds.extractOcr(imagePath);

      if (!mounted) return;

      setState(() {
        _ocrLoading = false;

        // Pré-remplir nom
        if (data['nom'] != null && (data['nom'] as String).isNotEmpty) {
          _nomCtr.text = data['nom'] as String;
        }

        // Pré-remplir registre
        if (data['registre'] != null) {
          _registreCtr.text = (data['registre'] as String).substring(
            0,
            (data['registre'] as String).length > 5
                ? 5
                : (data['registre'] as String).length,
          );
        }

        // Pré-remplir date de naissance
        if (data['date_naissance'] != null) {
          _dateNaissance =
              DateTime.tryParse(data['date_naissance'] as String);
        }

        _ocrMessage =
            '✅ Données extraites automatiquement. Vérifiez et corrigez si nécessaire.';
      });

      // La commune OCR sera gérée manuellement car le select cascadé
      // nécessite de sélectionner région → département → commune
      // On affiche juste un message indicatif
      if (data['commune_nom'] != null) {
        setState(() {
          _ocrMessage =
              '✅ Données extraites. Commune suggérée : ${data['commune_nom']}. '
              'Vérifiez et sélectionnez manuellement dans le select.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ocrLoading = false;
        _ocrMessage =
            '⚠️ Extraction automatique échouée. Remplissez manuellement.';
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
                      // ── Extrait en premier (OCR) ────────────
                      _SectionTitle(
                        title: 'Extrait de naissance',
                        badge: 'Optionnel',
                        badgeColor: AppColors.statusBlue,
                        badgeBg: AppColors.statusBlueLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uploadez l\'extrait existant pour pré-remplir '
                        'automatiquement le formulaire.',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 12),

                      UploadDocumentCard(
                        title: 'Extrait de naissance',
                        subtitle: _ocrLoading
                            ? 'Extraction en cours...'
                            : 'Photo ou galerie — pré-remplissage auto',
                        icon: Icons.description_outlined,
                        filePath: _extraitNaissance,
                        isRequired: false,
                        isLoading: _ocrLoading,
                        onTap: _ocrLoading
                            ? () {}
                            : () => _pickDocument('extrait'),
                        onRemove: _extraitNaissance != null && !_ocrLoading
                            ? () => setState(() {
                                  _extraitNaissance = null;
                                  _ocrMessage = null;
                                })
                            : null,
                      ),

                      // Message OCR
                      if (_ocrLoading) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    AppColors.secondary),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Extraction des données en cours...',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ],
                      if (_ocrMessage != null && !_ocrLoading) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _ocrMessage!.startsWith('✅')
                                ? AppColors.statusGreenLight
                                : AppColors.statusAmberLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _ocrMessage!.startsWith('✅')
                                  ? AppColors.secondary.withValues(alpha: 0.4)
                                  : AppColors.statusAmber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            _ocrMessage!,
                            style: AppTextStyles.caption.copyWith(
                              color: _ocrMessage!.startsWith('✅')
                                  ? AppColors.secondary
                                  : AppColors.statusAmber,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),

                      // ── Formulaire (pré-rempli ou vide) ────
                      Text('Informations du bénéficiaire',
                          style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Vérifiez et complétez les informations ci-dessous',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 20),

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
                          if (v.trim().length > 5) {
                            return 'Maximum 5 chiffres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DateTextField(
                        label: 'Date de naissance',
                        selectedDate: _dateNaissance,
                        validator: (_) =>
                            Validators.dateNaissance(_dateNaissance),
                        onDateSelected: (d) =>
                            setState(() => _dateNaissance = d),
                      ),
                      const SizedBox(height: 20),

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
                          _departement = d;
                          _commune = c;
                        }),
                      ),
                      const SizedBox(height: 28),

                      // ── CNI obligatoire ─────────────────────
                      _SectionTitle(
                        title: 'Pièce d\'identité (CNI)',
                        badge: 'Obligatoire',
                        badgeColor: AppColors.statusRed,
                        badgeBg: AppColors.statusRedLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Les deux faces de la CNI sont requises.',
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;

  const _SectionTitle({
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
echo "  ✅ other_person_screen.dart — OCR sur upload extrait"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Fix Naissance V3 appliqué !"
echo ""
echo "Corrections :"
echo "  1. 'Pour moi' — profil chargé au splash + après login/OTP"
echo "  2. 'Pour une autre' — upload extrait → OCR mock → pré-remplissage"
echo "     formulaire (nom, registre, date naissance + message commune)"
echo ""
echo "  flutter run"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
