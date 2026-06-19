#!/bin/bash
# ============================================================
# TERANGA CIVIL — Fix erreurs Auth V2
# Usage : bash fix_auth_v2_errors.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🔧 Fix erreurs Auth V2..."
echo ""

# ════════════════════════════════════════════════════════════
# FIX 1 — url_launcher : remplacer par un simple InAppWebView
# ou utiliser dart:html. Solution simple : ouvrir via un Dialog
# avec le lien plutôt que url_launcher non installé
# ════════════════════════════════════════════════════════════
python3 - << 'PY'
with open('lib/features/auth/presentation/screens/register_step1_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Supprimer l'import url_launcher
content = content.replace(
    "import 'package:url_launcher/url_launcher.dart';\n",
    ""
)

# Remplacer la méthode _openUrl par une version sans url_launcher
old_method = """  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }"""

new_method = """  void _openUrl(String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Lien', style: AppTextStyles.headlineSmall),
        content: SelectableText(
          url,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }"""

content = content.replace(old_method, new_method)

with open('lib/features/auth/presentation/screens/register_step1_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✅ FIX 1 — url_launcher supprimé, lien affiché dans Dialog")
PY

# Supprimer url_launcher du pubspec.yaml
python3 - << 'PY'
with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('  url_launcher: ^6.3.0\n', '')
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✅ FIX 1 — url_launcher supprimé du pubspec.yaml")
PY

# ════════════════════════════════════════════════════════════
# FIX 2 — UserModel : ajouter les champs manquants
# (communeId, communeNom, registre, dateNaissance)
# pour ne pas casser recap_self_screen et profile_screen
# ════════════════════════════════════════════════════════════
cat > lib/features/auth/domain/models/user_model.dart << 'DART'
class UserModel {
  final String id;
  final String prenom;
  final String nom;
  final String? phone;
  final String? email;
  final bool isVerified;
  // Champs optionnels pour compatibilité avec les certificats
  final String? communeId;
  final String? communeNom;
  final String? registre;
  final DateTime? dateNaissance;

  const UserModel({
    required this.id,
    required this.prenom,
    required this.nom,
    this.phone,
    this.email,
    this.isVerified = false,
    this.communeId,
    this.communeNom,
    this.registre,
    this.dateNaissance,
  });

  String get nomComplet => '$prenom $nom';

  UserModel copyWith({
    String? id,
    String? prenom,
    String? nom,
    String? phone,
    String? email,
    bool? isVerified,
    String? communeId,
    String? communeNom,
    String? registre,
    DateTime? dateNaissance,
  }) =>
      UserModel(
        id: id ?? this.id,
        prenom: prenom ?? this.prenom,
        nom: nom ?? this.nom,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        isVerified: isVerified ?? this.isVerified,
        communeId: communeId ?? this.communeId,
        communeNom: communeNom ?? this.communeNom,
        registre: registre ?? this.registre,
        dateNaissance: dateNaissance ?? this.dateNaissance,
      );
}
DART
echo "  ✅ FIX 2 — UserModel : champs optionnels ajoutés"

# ════════════════════════════════════════════════════════════
# FIX 3 — auth_response_model.dart : mapper les nouveaux champs
# ════════════════════════════════════════════════════════════
cat > lib/features/auth/data/models/auth_response_model.dart << 'DART'
import '../../domain/models/user_model.dart';

class LoginResponseModel {
  final String token;
  final String userId;
  final bool needsOtp;

  const LoginResponseModel({
    required this.token,
    required this.userId,
    required this.needsOtp,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        token: json['token'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        needsOtp: json['needs_otp'] as bool? ?? false,
      );
}

class UserResponseModel {
  final String id;
  final String prenom;
  final String nom;
  final String? phone;
  final String? email;
  final bool isVerified;
  final String? communeId;
  final String? communeNom;
  final String? registre;
  final String? dateNaissance;

  const UserResponseModel({
    required this.id,
    required this.prenom,
    required this.nom,
    this.phone,
    this.email,
    this.isVerified = false,
    this.communeId,
    this.communeNom,
    this.registre,
    this.dateNaissance,
  });

  factory UserResponseModel.fromJson(Map<String, dynamic> json) =>
      UserResponseModel(
        id: json['id'] as String? ?? '',
        prenom: json['prenom'] as String? ?? '',
        nom: json['nom'] as String? ?? '',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        communeId: json['commune_id'] as String?,
        communeNom: json['commune_nom'] as String?,
        registre: json['registre'] as String?,
        dateNaissance: json['date_naissance'] as String?,
      );

  UserModel toDomain() => UserModel(
        id: id,
        prenom: prenom,
        nom: nom,
        phone: phone,
        email: email,
        isVerified: isVerified,
        communeId: communeId,
        communeNom: communeNom,
        registre: registre,
        dateNaissance: dateNaissance != null
            ? DateTime.tryParse(dateNaissance!)
            : null,
      );
}
DART
echo "  ✅ FIX 3 — UserResponseModel : champs optionnels ajoutés"

# ════════════════════════════════════════════════════════════
# FIX 4 — recap_self_screen : gérer les champs nullable
# ════════════════════════════════════════════════════════════
cat > lib/features/certificates/naissance/presentation/screens/recap_self_screen.dart << 'DART'
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
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../providers/naissance_provider.dart';

/// S08A — Récapitulatif "Pour moi"
class RecapSelfScreen extends ConsumerWidget {
  const RecapSelfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final notifier = ref.read(naissanceProvider.notifier);
    final isLoading = ref.watch(naissanceProvider).isLoading;

    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    // Valeurs avec fallback si champs non renseignés
    final communeId = user.communeId ?? '';
    final communeNom = user.communeNom ?? 'Non renseignée';
    final registre = user.registre ?? 'Non renseigné';
    final dateNaissance = user.dateNaissance;

    Future<void> submit() async {
      if (communeId.isEmpty || dateNaissance == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Profil incomplet. Veuillez compléter vos informations.'),
            backgroundColor: AppColors.statusAmber,
          ),
        );
        return;
      }
      try {
        final id = await notifier.submit(
          communeId: communeId,
          nom: user.nomComplet,
          dateNaissance: dateNaissance,
          registre: registre,
          forSelf: true,
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vos informations',
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Text('Vérifiez vos données avant de continuer',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 24),
              RecapCard(
                title: 'Certificat de naissance',
                fields: [
                  RecapField(
                    label: 'Nom complet',
                    value: user.nomComplet,
                    icon: Icons.person_outline,
                  ),
                  RecapField(
                    label: 'Date de naissance',
                    value: dateNaissance != null
                        ? AppFormatters.dateToFrench(dateNaissance)
                        : 'Non renseignée',
                    icon: Icons.calendar_today_outlined,
                  ),
                  RecapField(
                    label: 'N° de registre',
                    value: registre,
                    icon: Icons.badge_outlined,
                  ),
                  RecapField(
                    label: 'Commune',
                    value: communeNom,
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
              const InfoBanner(
                  message:
                      'Ces informations proviennent de votre profil enregistré.'),
              const Spacer(),
              PrimaryButton(
                label: 'Confirmer et continuer →',
                onPressed: submit,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DART
echo "  ✅ FIX 4 — recap_self_screen : champs nullable gérés"

# ════════════════════════════════════════════════════════════
# FIX 5 — profile_screen : phone nullable + communeNom nullable
# ════════════════════════════════════════════════════════════
python3 - << 'PY'
with open('lib/features/profile/presentation/screens/profile_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix phone nullable
content = content.replace(
    "        ? AppFormatters.phoneNumber(user.phone)\n        : '—';",
    "        ? AppFormatters.phoneNumber(user.phone ?? '')\n        : '—';"
)

# Fix communeNom nullable
content = content.replace(
    "    final commune = user?.communeNom ?? '—';",
    "    final commune = user?.communeNom ?? 'Non renseignée';"
)

with open('lib/features/profile/presentation/screens/profile_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✅ FIX 5 — profile_screen : phone et communeNom nullable gérés")
PY

# ════════════════════════════════════════════════════════════
# FIX 6 — mock_interceptor.dart : anciens paramètres phone/registre
# remplacer par les nouveaux paramètres identifier
# ════════════════════════════════════════════════════════════
cat > lib/core/network/mock_interceptor.dart << 'DART'
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../mock/mock_service.dart';

class MockInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final path = options.path;
    final method = options.method.toUpperCase();
    final data = options.data as Map<String, dynamic>? ?? {};
    debugPrint('[MOCK] $method $path');

    try {
      final responseData = await _handle(method, path, data);
      handler.resolve(Response(
          requestOptions: options, statusCode: 200, data: responseData));
    } catch (e) {
      handler.reject(DioException(
        requestOptions: options,
        message: e.toString(),
        type: DioExceptionType.badResponse,
        response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {'message': e.toString()}),
      ));
    }
  }

  Future<dynamic> _handle(
      String method, String path, Map<String, dynamic> data) async {

    // ── Auth ──────────────────────────────────────────────
    if (path == '/auth/login') {
      return MockService.login(
        identifier: data['identifier'] as String? ?? '',
        password: data['password'] as String? ?? '',
      );
    }
    if (path == '/auth/register') {
      return MockService.register(
        prenom: data['prenom'] as String? ?? '',
        nom: data['nom'] as String? ?? '',
        password: data['password'] as String? ?? '',
        phone: data['phone'] as String?,
        email: data['email'] as String?,
      );
    }
    if (path == '/auth/verify-otp') {
      return MockService.verifyOtp(
        identifier: data['identifier'] as String? ?? '',
        code: data['code'] as String? ?? '',
      );
    }
    if (path == '/auth/resend-otp') {
      return MockService.resendOtp(
        identifier: data['identifier'] as String? ?? '',
      );
    }
    if (path == '/auth/me') return MockService.getMe();

    // ── Certificats ───────────────────────────────────────
    if (path == '/certificates/submit') {
      return MockService.submitCertificate(data);
    }

    // ── Dossiers ──────────────────────────────────────────
    if (path == '/dossiers' && method == 'GET') {
      return MockService.getDossiers();
    }
    if (path.startsWith('/dossiers/') && method == 'GET') {
      return MockService.getDossierById(
          path.replaceFirst('/dossiers/', ''));
    }

    // ── Paiement ──────────────────────────────────────────
    if (path == '/payment/initiate') {
      return MockService.initiatePayment(
        dossierId: data['dossier_id'] as String? ?? '',
        method: data['method'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
      );
    }

    // ── Profil ────────────────────────────────────────────
    if (path == '/profile/update') return MockService.updateProfile(data);
    if (path == '/profile/change-pin') {
      await MockService.changePin(
        oldPinHash: data['old_pin_hash'] as String? ?? '',
        newPin: data['new_pin'] as String? ?? '',
      );
      return {'success': true};
    }

    // ── Assistant ─────────────────────────────────────────
    if (path == '/assistant/chat') {
      return MockService.sendAssistantMessage(
        message: data['message'] as String? ?? '',
        language: data['language'] as String? ?? 'fr',
      );
    }

    debugPrint('[MOCK] Route non gérée: $method $path');
    return {'success': true};
  }
}
DART
echo "  ✅ FIX 6 — mock_interceptor.dart : paramètres corrigés"

# ════════════════════════════════════════════════════════════
# FIX 7 — register_step2_screen : supprimer le communeId résiduel
# ════════════════════════════════════════════════════════════
cat > lib/features/auth/presentation/screens/register_step2_screen.dart << 'DART'
// Écran supprimé — inscription simplifiée (voir register_step1_screen.dart)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterStep2Screen extends StatelessWidget {
  final Map<String, dynamic> registrationData;
  const RegisterStep2Screen({super.key, required this.registrationData});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
    return const SizedBox.shrink();
  }
}
DART
echo "  ✅ FIX 7 — register_step2_screen : résidu communeId supprimé"

# ════════════════════════════════════════════════════════════
# FIX 8 — mock_service : getMe retourne les champs complets
# ════════════════════════════════════════════════════════════
python3 - << 'PY'
with open('lib/core/mock/mock_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """  static Future<Map<String, dynamic>> getMe() async {
    await delay(400);
    return {
      'id': 'mock_user_001',
      'prenom': 'Amadou',
      'nom': 'Diallo',
      'phone': '771234567',
      'email': 'amadou@example.com',
      'is_verified': true,
    };
  }"""

new = """  static Future<Map<String, dynamic>> getMe() async {
    await delay(400);
    return {
      'id': 'mock_user_001',
      'prenom': 'Amadou',
      'nom': 'Diallo',
      'phone': '771234567',
      'email': 'amadou@example.com',
      'is_verified': true,
      'commune_id': 'DK-DK-01',
      'commune_nom': 'Dakar Plateau',
      'registre': 'SN-123456-A',
      'date_naissance': '1990-05-15',
    };
  }"""

content = content.replace(old, new)
with open('lib/core/mock/mock_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✅ FIX 8 — mock_service.getMe : champs complets ajoutés")
PY

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Toutes les erreurs corrigées !"
echo ""
echo "Exécutez :"
echo "  flutter pub get"
echo "  flutter run"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
