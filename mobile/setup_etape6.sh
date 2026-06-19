#!/bin/bash
# ============================================================
# TERANGA CIVIL — Étape 6 : HOME + CERTIFICATES (S07 à S10A)
# Usage : bash setup_etape6.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🚀 TERANGA CIVIL — Installation Étape 6 : HOME + CERTIFICATES"
echo ""

# ════════════════════════════════════════════════════════════
# FEATURE HOME
# ════════════════════════════════════════════════════════════

cat > lib/features/home/presentation/providers/home_provider.dart << 'DART'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dossiers/data/remote_datasource.dart';
import '../../../dossiers/data/models/dossier_model.dart';
import '../../../../core/network/dio_client.dart';

final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  try {
    final client = ref.read(dioClientProvider);
    final ds = DossiersRemoteDatasource(client: client);
    final dossiers = await ds.getDossiers();
    final enCours = dossiers.where((d) =>
        d.status != 'pret' && d.status != 'rejete').length;
    return HomeStats(dossiersEnCours: enCours, totalDossiers: dossiers.length);
  } catch (_) {
    return const HomeStats(dossiersEnCours: 0, totalDossiers: 0);
  }
});

class HomeStats {
  final int dossiersEnCours;
  final int totalDossiers;
  const HomeStats({required this.dossiersEnCours, required this.totalDossiers});
}
DART
echo "  ✅ home_provider.dart"

cat > lib/features/home/presentation/screens/home_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/assets_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/home_provider.dart';

/// S07 — Dashboard / Accueil
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(homeStatsProvider);
    final user = ref.watch(authProvider).user;
    final prenom = user != null
        ? AppFormatters.titleCase(user.nom.split(' ').first)
        : 'Bienvenue';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar custom ──────────────────────────────
            SliverToBoxAdapter(
              child: _HomeHeader(prenom: prenom),
            ),

            // ── Bannière dossier en cours ───────────────────
            SliverToBoxAdapter(
              child: stats.when(
                data: (s) => s.dossiersEnCours > 0
                    ? _StatusBanner(count: s.dossiersEnCours)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // ── Titre section services ──────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Text('Mes services', style: AppTextStyles.headlineSmall),
              ),
            ),

            // ── Grille 2x2 services ─────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  _ServiceCard(
                    icon: Icons.article_outlined,
                    label: 'Certificat de\nnaissance',
                    color: const Color(0xFF3B82F6),
                    bgColor: const Color(0xFFDBEAFE),
                    onTap: () => context.push(AppRoutes.naissanceBeneficiary),
                  ),
                  _ServiceCard(
                    icon: Icons.favorite_border,
                    label: 'Certificat de\nmariage',
                    color: const Color(0xFFEC4899),
                    bgColor: const Color(0xFFFCE7F3),
                    onTap: () => context.push(AppRoutes.mariageForm),
                  ),
                  _ServiceCard(
                    icon: Icons.local_florist_outlined,
                    label: 'Certificat de\ndécès',
                    color: AppColors.textSecondary,
                    bgColor: AppColors.divider,
                    onTap: () => context.push(AppRoutes.decesForm),
                  ),
                  _ServiceCard(
                    icon: Icons.folder_outlined,
                    label: 'Mes\ndossiers',
                    color: AppColors.secondary,
                    bgColor: AppColors.statusGreenLight,
                    onTap: () => context.go(AppRoutes.dossiers),
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
              ),
            ),

            // ── Section infos ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                child: Text('Informations', style: AppTextStyles.headlineSmall),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: _InfoCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String prenom;
  const _HomeHeader({required this.prenom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          SvgPicture.asset(Assets.logoTeranga, width: 36, height: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $prenom 👋',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                Text(
                  AppConstants.appTagline,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textOnPrimary, size: 26),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final int count;
  const _StatusBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.dossiers),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.statusAmberLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.statusAmber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_empty_outlined,
                color: AppColors.statusAmber, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count dossier${count > 1 ? 's' : ''} en cours de traitement',
                style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.statusAmber),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.statusAmber, size: 14),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(height: 1.3),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Demander', style: AppTextStyles.caption.copyWith(
                    color: color)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 12, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Délais de traitement',
                  style: AppTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Certificat de naissance', value: '3 jours ouvrés'),
          _InfoRow(label: 'Certificat de décès', value: '3 jours ouvrés'),
          _InfoRow(label: 'Certificat de mariage', value: '5 jours ouvrés'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value,
              style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary)),
        ],
      ),
    );
  }
}
DART
echo "  ✅ home_screen.dart"

# ════════════════════════════════════════════════════════════
# CERTIFICATES — SHARED MODEL
# ════════════════════════════════════════════════════════════

cat > lib/features/dossiers/data/models/dossier_model.dart << 'DART'
class DossierModel {
  final String id;
  final String type;
  final String status;
  final DateTime createdAt;
  final String? communeNom;
  final String? beneficiaryNom;
  final int? fraisFCFA;

  const DossierModel({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    this.communeNom,
    this.beneficiaryNom,
    this.fraisFCFA,
  });

  factory DossierModel.fromJson(Map<String, dynamic> json) => DossierModel(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? '',
        status: json['status'] as String? ?? 'soumis',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        communeNom: json['commune_nom'] as String?,
        beneficiaryNom: json['beneficiary_nom'] as String?,
        fraisFCFA: json['frais'] as int?,
      );
}
DART
echo "  ✅ dossier_model.dart"

cat > lib/features/dossiers/data/remote_datasource.dart << 'DART'
import '../../../core/network/dio_client.dart';
import '../../../core/errors/exceptions.dart';
import 'models/dossier_model.dart';

class DossiersRemoteDatasource {
  final DioClient client;
  const DossiersRemoteDatasource({required this.client});

  Future<List<DossierModel>> getDossiers() async {
    final res = await client.get('/dossiers');
    if (res.statusCode == 200 && res.data != null) {
      final list = res.data as List;
      return list
          .map((e) => DossierModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw const ApiException(message: 'Impossible de charger les dossiers');
  }

  Future<DossierModel> getDossierById(String id) async {
    final res = await client.get('/dossiers/$id');
    if (res.statusCode == 200 && res.data != null) {
      return DossierModel.fromJson(res.data as Map<String, dynamic>);
    }
    throw const NotFoundException();
  }

  Future<String> submitCertificate(Map<String, dynamic> payload) async {
    final res = await client.post('/certificates/submit', data: payload);
    if ((res.statusCode == 200 || res.statusCode == 201) && res.data != null) {
      return (res.data as Map<String, dynamic>)['dossier_id'] as String;
    }
    throw ApiException(
        message: 'Erreur lors de la soumission', statusCode: res.statusCode);
  }
}
DART
echo "  ✅ dossiers remote_datasource.dart"

# ════════════════════════════════════════════════════════════
# CERTIFICATES — NAISSANCE
# ════════════════════════════════════════════════════════════

cat > lib/features/certificates/naissance/presentation/providers/naissance_provider.dart << 'DART'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../dossiers/data/remote_datasource.dart';

class NaissanceState {
  final bool isLoading;
  final String? error;
  final String? dossierId;

  const NaissanceState({
    this.isLoading = false,
    this.error,
    this.dossierId,
  });

  NaissanceState copyWith({
    bool? isLoading, String? error, String? dossierId, bool clearError = false,
  }) => NaissanceState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        dossierId: dossierId ?? this.dossierId,
      );
}

class NaissanceNotifier extends StateNotifier<NaissanceState> {
  final DossiersRemoteDatasource _ds;
  NaissanceNotifier(this._ds) : super(const NaissanceState());

  Future<String> submit({
    required String communeId,
    required String nom,
    required DateTime dateNaissance,
    required String registre,
    bool forSelf = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final id = await _ds.submitCertificate({
        'type': 'naissance',
        'commune_id': communeId,
        'beneficiary': {
          'nom': nom,
          'date_naissance': dateNaissance.toIso8601String().split('T').first,
          'registre': registre,
        },
        'for_self': forSelf,
      });
      state = state.copyWith(isLoading: false, dossierId: id);
      return id;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final naissanceProvider =
    StateNotifierProvider<NaissanceNotifier, NaissanceState>((ref) =>
        NaissanceNotifier(
            DossiersRemoteDatasource(client: ref.read(dioClientProvider))));
DART
echo "  ✅ naissance_provider.dart"

cat > lib/features/certificates/naissance/presentation/screens/beneficiary_choice_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/document_scanner.dart';

/// S08 — Choix bénéficiaire certificat de naissance
class BeneficiaryChoiceScreen extends ConsumerWidget {
  const BeneficiaryChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              DocumentScannerCard(
                title: 'Pour moi',
                subtitle: 'Utiliser mes informations enregistrées',
                icon: Icons.person_outlined,
                onTap: () => context.push(AppRoutes.naissanceRecapSelf),
              ),
              const SizedBox(height: 12),
              DocumentScannerCard(
                title: 'Pour une autre personne',
                subtitle: 'Scanner un document ou saisir manuellement',
                icon: Icons.group_outlined,
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
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondary),
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
DART
echo "  ✅ beneficiary_choice_screen.dart"

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    Future<void> submit() async {
      try {
        final id = await notifier.submit(
          communeId: user.communeId,
          nom: user.nom,
          dateNaissance: user.dateNaissance,
          registre: user.registre,
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
          SnackBar(content: Text(e.toString()),
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
              Text('Vos informations', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Text('Vérifiez vos données avant de continuer',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 24),
              RecapCard(
                title: 'Certificat de naissance',
                fields: [
                  RecapField(
                    label: 'Nom complet',
                    value: user.nom,
                    icon: Icons.person_outline,
                  ),
                  RecapField(
                    label: 'Date de naissance',
                    value: AppFormatters.dateToFrench(user.dateNaissance),
                    icon: Icons.calendar_today_outlined,
                  ),
                  RecapField(
                    label: 'N° de registre',
                    value: user.registre,
                    icon: Icons.badge_outlined,
                  ),
                  RecapField(
                    label: 'Commune',
                    value: user.communeNom,
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
echo "  ✅ recap_self_screen.dart"

cat > lib/features/certificates/naissance/presentation/screens/other_person_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/cascaded_commune_select.dart';
import '../../../../../shared/widgets/document_scanner.dart';
import '../../../../../shared/models/commune_model.dart';

/// S08B — Saisie "Pour une autre personne"
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
  bool _scanSelected = false;
  bool _manualSelected = true;

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
      _commune != null;

  void _next() {
    if (!_formKey.currentState!.validate() || _commune == null) return;
    context.push(AppRoutes.naissanceRecapOther, extra: {
      'nom': _nomCtr.text.trim(),
      'registre': _registreCtr.text.trim().toUpperCase(),
      'date_naissance': _dateNaissance!.toIso8601String(),
      'commune_id': _commune!.id,
      'commune_nom': _commune!.nom,
      'region_id': _region?.id ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Autre personne'),
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
                      DocumentScannerCard(
                        title: 'Scanner le certificat',
                        subtitle: 'OCR — extraction automatique',
                        icon: Icons.document_scanner_outlined,
                        isSelected: _scanSelected,
                        onTap: () async {
                          final path = await ImagePickerHelper.showSourcePicker(context);
                          if (path != null) setState(() {
                            _scanSelected = true;
                            _manualSelected = false;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DocumentScannerCard(
                        title: 'Saisir manuellement',
                        subtitle: 'Remplir le formulaire',
                        icon: Icons.edit_outlined,
                        isSelected: _manualSelected,
                        onTap: () => setState(() {
                          _manualSelected = true;
                          _scanSelected = false;
                        }),
                      ),
                      const SizedBox(height: 24),
                      CascadedCommuneSelect(
                        onChanged: (r, d, c) => setState(() {
                          _region = r;
                          _commune = c;
                        }),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Nom complet',
                        hint: 'Ex: Fatou Sow',
                        controller: _nomCtr,
                        validator: Validators.fullName,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      DateTextField(
                        label: 'Date de naissance',
                        selectedDate: _dateNaissance,
                        validator: (_) => Validators.dateNaissance(_dateNaissance),
                        onDateSelected: (d) => setState(() => _dateNaissance = d),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Numéro de registre',
                        hint: 'Ex: SN-654321-B',
                        controller: _registreCtr,
                        validator: Validators.registreNumber,
                        textInputAction: TextInputAction.done,
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
                label: 'Suivant →',
                onPressed: _next,
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

cat > lib/features/certificates/naissance/presentation/screens/recap_other_screen.dart << 'DART'
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

/// S08C — Récapitulatif "Pour une autre personne"
class RecapOtherScreen extends ConsumerWidget {
  final Map<String, dynamic> formData;
  const RecapOtherScreen({super.key, required this.formData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(naissanceProvider).isLoading;
    final dateNaissance = DateTime.tryParse(
        formData['date_naissance'] as String? ?? '') ?? DateTime(1990);

    Future<void> submit() async {
      try {
        final id = await ref.read(naissanceProvider.notifier).submit(
              communeId: formData['commune_id'] as String,
              nom: formData['nom'] as String,
              dateNaissance: dateNaissance,
              registre: formData['registre'] as String,
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
          SnackBar(content: Text(e.toString()),
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
              Text('Vérifiez les informations',
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Text('Assurez-vous que tout est correct avant de payer',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 24),
              RecapCard(
                title: 'Certificat de naissance',
                fields: [
                  RecapField(label: 'Nom complet',
                      value: formData['nom'] as String,
                      icon: Icons.person_outline),
                  RecapField(label: 'Date de naissance',
                      value: AppFormatters.dateToFrench(dateNaissance),
                      icon: Icons.calendar_today_outlined),
                  RecapField(label: 'N° de registre',
                      value: formData['registre'] as String,
                      icon: Icons.badge_outlined),
                  RecapField(label: 'Commune',
                      value: formData['commune_nom'] as String,
                      icon: Icons.location_on_outlined),
                  RecapField(label: 'Frais',
                      value: AppFormatters.amountFCFA(
                          AppConstants.naissanceFeesFCFA),
                      icon: Icons.payment_outlined,
                      valueColor: AppColors.secondary),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Confirmer et payer →',
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
echo "  ✅ recap_other_screen.dart"

# ════════════════════════════════════════════════════════════
# CERTIFICATES — DECES
# ════════════════════════════════════════════════════════════

cat > lib/features/certificates/deces/presentation/providers/deces_provider.dart << 'DART'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../dossiers/data/remote_datasource.dart';

class DecesState {
  final bool isLoading;
  final String? error;
  final String? dossierId;
  const DecesState({this.isLoading = false, this.error, this.dossierId});
  DecesState copyWith({bool? isLoading, String? error, String? dossierId,
      bool clearError = false}) =>
      DecesState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        dossierId: dossierId ?? this.dossierId,
      );
}

class DecesNotifier extends StateNotifier<DecesState> {
  final DossiersRemoteDatasource _ds;
  DecesNotifier(this._ds) : super(const DecesState());

  Future<String> submit({
    required String communeId,
    required String nomDefunt,
    required String registre,
    required DateTime dateDeces,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final id = await _ds.submitCertificate({
        'type': 'deces',
        'commune_id': communeId,
        'beneficiary': {
          'nom': nomDefunt,
          'registre': registre,
          'date_deces': dateDeces.toIso8601String().split('T').first,
        },
      });
      state = state.copyWith(isLoading: false, dossierId: id);
      return id;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final decesProvider =
    StateNotifierProvider<DecesNotifier, DecesState>((ref) =>
        DecesNotifier(
            DossiersRemoteDatasource(client: ref.read(dioClientProvider))));
DART
echo "  ✅ deces_provider.dart"

cat > lib/features/certificates/deces/presentation/screens/deces_form_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/cascaded_commune_select.dart';
import '../../../../../shared/models/commune_model.dart';

/// S09 — Formulaire certificat de décès
class DecesFormScreen extends ConsumerStatefulWidget {
  const DecesFormScreen({super.key});

  @override
  ConsumerState<DecesFormScreen> createState() => _DecesFormScreenState();
}

class _DecesFormScreenState extends ConsumerState<DecesFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtr = TextEditingController();
  final _registreCtr = TextEditingController();
  DateTime? _dateDeces;
  CommuneModel? _commune;

  @override
  void dispose() {
    _nomCtr.dispose();
    _registreCtr.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nomCtr.text.trim().isNotEmpty &&
      _registreCtr.text.trim().isNotEmpty &&
      _dateDeces != null &&
      _commune != null;

  void _next() {
    if (!_formKey.currentState!.validate() || _commune == null) return;
    context.push(AppRoutes.decesRecap, extra: {
      'nom': _nomCtr.text.trim(),
      'registre': _registreCtr.text.trim().toUpperCase(),
      'date_deces': _dateDeces!.toIso8601String(),
      'commune_id': _commune!.id,
      'commune_nom': _commune!.nom,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Certificat de décès'),
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
                      Text('Informations du défunt',
                          style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 20),
                      CascadedCommuneSelect(
                        onChanged: (r, d, c) =>
                            setState(() => _commune = c),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Nom complet du défunt',
                        hint: 'Ex: Mamadou Ba',
                        controller: _nomCtr,
                        validator: Validators.fullName,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Numéro de registre',
                        hint: 'Ex: SN-789012-C',
                        controller: _registreCtr,
                        validator: Validators.registreNumber,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 16),
                      DateTextField(
                        label: 'Date de décès',
                        selectedDate: _dateDeces,
                        validator: (_) => Validators.dateDeces(_dateDeces),
                        onDateSelected: (d) =>
                            setState(() => _dateDeces = d),
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
                label: 'Suivant →',
                onPressed: _next,
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
echo "  ✅ deces_form_screen.dart"

cat > lib/features/certificates/deces/presentation/screens/deces_recap_screen.dart << 'DART'
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
import '../providers/deces_provider.dart';

/// S09A — Récapitulatif décès
class DecesRecapScreen extends ConsumerWidget {
  final Map<String, dynamic> formData;
  const DecesRecapScreen({super.key, required this.formData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(decesProvider).isLoading;
    final dateDeces = DateTime.tryParse(
        formData['date_deces'] as String? ?? '') ?? DateTime.now();

    Future<void> submit() async {
      try {
        final id = await ref.read(decesProvider.notifier).submit(
              communeId: formData['commune_id'] as String,
              nomDefunt: formData['nom'] as String,
              registre: formData['registre'] as String,
              dateDeces: dateDeces,
            );
        if (!context.mounted) return;
        context.push(AppRoutes.payment, extra: {
          'dossier_id': id,
          'type': 'deces',
          'montant': AppConstants.decesFeesFCFA,
          'label': 'Certificat de décès',
        });
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
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
              Text('Vérifiez les informations',
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Text('Assurez-vous que tout est correct avant de payer',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 24),
              RecapCard(
                title: 'Certificat de décès',
                fields: [
                  RecapField(label: 'Nom du défunt',
                      value: formData['nom'] as String,
                      icon: Icons.person_outline),
                  RecapField(label: 'N° de registre',
                      value: formData['registre'] as String,
                      icon: Icons.badge_outlined),
                  RecapField(label: 'Date de décès',
                      value: AppFormatters.dateToFrench(dateDeces),
                      icon: Icons.calendar_today_outlined),
                  RecapField(label: 'Commune',
                      value: formData['commune_nom'] as String,
                      icon: Icons.location_on_outlined),
                  RecapField(label: 'Frais',
                      value: AppFormatters.amountFCFA(
                          AppConstants.decesFeesFCFA),
                      icon: Icons.payment_outlined,
                      valueColor: AppColors.secondary),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Confirmer et payer →',
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
echo "  ✅ deces_recap_screen.dart"

# ════════════════════════════════════════════════════════════
# CERTIFICATES — MARIAGE
# ════════════════════════════════════════════════════════════

cat > lib/features/certificates/mariage/presentation/providers/mariage_provider.dart << 'DART'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../dossiers/data/remote_datasource.dart';

class MariageState {
  final bool isLoading;
  final String? error;
  final String? dossierId;
  const MariageState({this.isLoading = false, this.error, this.dossierId});
  MariageState copyWith({bool? isLoading, String? error, String? dossierId,
      bool clearError = false}) =>
      MariageState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        dossierId: dossierId ?? this.dossierId,
      );
}

class MariageNotifier extends StateNotifier<MariageState> {
  final DossiersRemoteDatasource _ds;
  MariageNotifier(this._ds) : super(const MariageState());

  Future<String> submit({
    required String communeId,
    required String registreMarriage,
    required int anneeMarriage,
    required String nomEpoux,
    required String nomEpouse,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final id = await _ds.submitCertificate({
        'type': 'mariage',
        'commune_id': communeId,
        'beneficiary': {
          'registre_marriage': registreMarriage,
          'annee_marriage': anneeMarriage,
          'nom_epoux': nomEpoux,
          'nom_epouse': nomEpouse,
        },
      });
      state = state.copyWith(isLoading: false, dossierId: id);
      return id;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final mariageProvider =
    StateNotifierProvider<MariageNotifier, MariageState>((ref) =>
        MariageNotifier(
            DossiersRemoteDatasource(client: ref.read(dioClientProvider))));
DART
echo "  ✅ mariage_provider.dart"

cat > lib/features/certificates/mariage/presentation/screens/mariage_form_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/cascaded_commune_select.dart';
import '../../../../../shared/models/commune_model.dart';

/// S10 — Formulaire certificat de mariage
class MariageFormScreen extends ConsumerStatefulWidget {
  const MariageFormScreen({super.key});

  @override
  ConsumerState<MariageFormScreen> createState() => _MariageFormScreenState();
}

class _MariageFormScreenState extends ConsumerState<MariageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registreCtr = TextEditingController();
  final _epouxCtr = TextEditingController();
  final _epouseCtr = TextEditingController();
  int? _anneeMarriage;
  CommuneModel? _commune;

  @override
  void dispose() {
    _registreCtr.dispose();
    _epouxCtr.dispose();
    _epouseCtr.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _registreCtr.text.trim().isNotEmpty &&
      _epouxCtr.text.trim().isNotEmpty &&
      _epouseCtr.text.trim().isNotEmpty &&
      _anneeMarriage != null &&
      _commune != null;

  void _next() {
    if (!_formKey.currentState!.validate() || _commune == null) return;
    context.push(AppRoutes.mariageRecap, extra: {
      'registre': _registreCtr.text.trim(),
      'annee_marriage': _anneeMarriage,
      'nom_epoux': _epouxCtr.text.trim(),
      'nom_epouse': _epouseCtr.text.trim(),
      'commune_id': _commune!.id,
      'commune_nom': _commune!.nom,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Certificat de mariage'),
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
                      Text('Informations du mariage',
                          style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 20),
                      CascadedCommuneSelect(
                        onChanged: (r, d, c) =>
                            setState(() => _commune = c),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Numéro de registre du mariage',
                        hint: 'Ex: MR-2020-001',
                        controller: _registreCtr,
                        validator: Validators.mariageRegistre,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      _YearPickerField(
                        selectedYear: _anneeMarriage,
                        onYearSelected: (y) =>
                            setState(() => _anneeMarriage = y),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: "Nom complet de l'époux",
                        hint: 'Ex: Oumar Diop',
                        controller: _epouxCtr,
                        validator: Validators.fullName,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: "Nom complet de l'épouse",
                        hint: 'Ex: Aïssatou Fall',
                        controller: _epouseCtr,
                        validator: Validators.fullName,
                        textInputAction: TextInputAction.done,
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
                label: 'Suivant →',
                onPressed: _next,
                isEnabled: _isValid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sélecteur d'année (year picker)
class _YearPickerField extends StatelessWidget {
  final int? selectedYear;
  final void Function(int) onYearSelected;

  const _YearPickerField({required this.selectedYear, required this.onYearSelected});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Année de mariage',
      hint: 'Ex: 2020',
      readOnly: true,
      controller: TextEditingController(
          text: selectedYear?.toString() ?? ''),
      suffixIcon: const Icon(Icons.calendar_today_outlined,
          color: AppColors.textSecondary, size: 20),
      onTap: () => _showYearPicker(context),
    );
  }

  void _showYearPicker(BuildContext context) {
    final now = DateTime.now().year;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: 250,
        child: Column(
          children: [
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
                onSelectedItemChanged: (i) => onYearSelected(now - i),
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, i) {
                    final year = now - i;
                    if (year < 1900) return null;
                    return Center(
                      child: Text(year.toString(),
                          style: year == (selectedYear ?? now)
                              ? AppTextStyles.headlineMedium
                              : AppTextStyles.bodyLarge),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Confirmer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DART
echo "  ✅ mariage_form_screen.dart"

cat > lib/features/certificates/mariage/presentation/screens/mariage_recap_screen.dart << 'DART'
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
import '../providers/mariage_provider.dart';

/// S10A — Récapitulatif mariage
class MariageRecapScreen extends ConsumerWidget {
  final Map<String, dynamic> formData;
  const MariageRecapScreen({super.key, required this.formData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(mariageProvider).isLoading;

    Future<void> submit() async {
      try {
        final id = await ref.read(mariageProvider.notifier).submit(
              communeId: formData['commune_id'] as String,
              registreMarriage: formData['registre'] as String,
              anneeMarriage: formData['annee_marriage'] as int,
              nomEpoux: formData['nom_epoux'] as String,
              nomEpouse: formData['nom_epouse'] as String,
            );
        if (!context.mounted) return;
        context.push(AppRoutes.payment, extra: {
          'dossier_id': id,
          'type': 'mariage',
          'montant': AppConstants.mariageFeesFCFA,
          'label': 'Certificat de mariage',
        });
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
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
              Text('Vérifiez les informations',
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Text('Assurez-vous que tout est correct avant de payer',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 24),
              RecapCard(
                title: 'Certificat de mariage',
                fields: [
                  RecapField(label: 'Époux',
                      value: formData['nom_epoux'] as String,
                      icon: Icons.person_outline),
                  RecapField(label: 'Épouse',
                      value: formData['nom_epouse'] as String,
                      icon: Icons.person_outline),
                  RecapField(label: 'Année',
                      value: formData['annee_marriage'].toString(),
                      icon: Icons.calendar_today_outlined),
                  RecapField(label: 'N° registre',
                      value: formData['registre'] as String,
                      icon: Icons.badge_outlined),
                  RecapField(label: 'Commune',
                      value: formData['commune_nom'] as String,
                      icon: Icons.location_on_outlined),
                  RecapField(label: 'Frais',
                      value: AppFormatters.amountFCFA(
                          AppConstants.mariageFeesFCFA),
                      icon: Icons.payment_outlined,
                      valueColor: AppColors.secondary),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Confirmer et payer →',
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
echo "  ✅ mariage_recap_screen.dart"

echo ""
echo "✅ Étape 6 terminée — 17 fichiers créés"
echo ""
echo "Fichiers générés :"
echo "  lib/features/home/presentation/providers/home_provider.dart"
echo "  lib/features/home/presentation/screens/home_screen.dart"
echo "  lib/features/dossiers/data/models/dossier_model.dart"
echo "  lib/features/dossiers/data/remote_datasource.dart"
echo "  lib/features/certificates/naissance/presentation/providers/naissance_provider.dart"
echo "  lib/features/certificates/naissance/presentation/screens/beneficiary_choice_screen.dart"
echo "  lib/features/certificates/naissance/presentation/screens/recap_self_screen.dart"
echo "  lib/features/certificates/naissance/presentation/screens/other_person_screen.dart"
echo "  lib/features/certificates/naissance/presentation/screens/recap_other_screen.dart"
echo "  lib/features/certificates/deces/presentation/providers/deces_provider.dart"
echo "  lib/features/certificates/deces/presentation/screens/deces_form_screen.dart"
echo "  lib/features/certificates/deces/presentation/screens/deces_recap_screen.dart"
echo "  lib/features/certificates/mariage/presentation/providers/mariage_provider.dart"
echo "  lib/features/certificates/mariage/presentation/screens/mariage_form_screen.dart"
echo "  lib/features/certificates/mariage/presentation/screens/mariage_recap_screen.dart"
