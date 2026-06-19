#!/bin/bash
# ============================================================
# TERANGA CIVIL — Étape 7 : PAYMENT + DOSSIERS + TESTS
# Usage : bash setup_etape7.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🚀 TERANGA CIVIL — Installation Étape 7 : PAYMENT + DOSSIERS + TESTS"
echo ""

mkdir -p test/core/utils
mkdir -p test/core/errors
mkdir -p test/features/auth
mkdir -p test/features/dossiers
mkdir -p test/features/payment

# ════════════════════════════════════════════════════════════
# FEATURE PAYMENT
# ════════════════════════════════════════════════════════════

cat > lib/features/payment/data/models/payment_model.dart << 'DART'
class PaymentModel {
  final bool success;
  final String? receipt;
  final String? transactionId;

  const PaymentModel({
    required this.success,
    this.receipt,
    this.transactionId,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        success: json['success'] as bool? ?? false,
        receipt: json['receipt'] as String?,
        transactionId: json['transaction_id'] as String?,
      );
}
DART
echo "  ✅ payment_model.dart"

cat > lib/features/payment/data/remote_datasource.dart << 'DART'
import '../../../core/network/dio_client.dart';
import '../../../core/errors/exceptions.dart';
import 'models/payment_model.dart';

class PaymentRemoteDatasource {
  final DioClient client;
  const PaymentRemoteDatasource({required this.client});

  Future<PaymentModel> initiatePayment({
    required String dossierId,
    required String method,
    required String phone,
  }) async {
    final res = await client.post('/payment/initiate', data: {
      'dossier_id': dossierId,
      'method': method,
      'phone': phone,
    });
    if ((res.statusCode == 200 || res.statusCode == 201) && res.data != null) {
      return PaymentModel.fromJson(res.data as Map<String, dynamic>);
    }
    throw ApiException(
      message: 'Le paiement a échoué. Vérifiez votre solde.',
      statusCode: res.statusCode,
    );
  }
}
DART
echo "  ✅ payment remote_datasource.dart"

cat > lib/features/payment/presentation/providers/payment_provider.dart << 'DART'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/remote_datasource.dart';

class PaymentState {
  final bool isLoading;
  final String? error;
  final bool success;
  final String? transactionId;

  const PaymentState({
    this.isLoading = false,
    this.error,
    this.success = false,
    this.transactionId,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    String? transactionId,
    bool clearError = false,
  }) =>
      PaymentState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        success: success ?? this.success,
        transactionId: transactionId ?? this.transactionId,
      );
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentRemoteDatasource _ds;
  PaymentNotifier(this._ds) : super(const PaymentState());

  Future<void> pay({
    required String dossierId,
    required String method,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _ds.initiatePayment(
        dossierId: dossierId,
        method: method,
        phone: phone,
      );
      state = state.copyWith(
        isLoading: false,
        success: result.success,
        transactionId: result.transactionId,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void reset() => state = const PaymentState();
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) =>
        PaymentNotifier(
          PaymentRemoteDatasource(client: ref.read(dioClientProvider)),
        ));
DART
echo "  ✅ payment_provider.dart"

cat > lib/features/payment/presentation/screens/payment_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/payment_provider.dart';

/// S11 — Écran paiement
class PaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> paymentData;
  const PaymentScreen({super.key, required this.paymentData});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedMethod = AppConstants.paymentWave;
  final _phoneCtr = TextEditingController();
  bool _phoneValid = false;

  @override
  void initState() {
    super.initState();
    _loadPhone();
  }

  Future<void> _loadPhone() async {
    const storage = FlutterSecureStorage();
    final phone = await storage.read(key: AppConstants.keyUserPhone);
    if (phone != null && mounted) {
      setState(() {
        _phoneCtr.text = phone;
        _phoneValid = true;
      });
    }
  }

  @override
  void dispose() {
    _phoneCtr.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    try {
      await ref.read(paymentProvider.notifier).pay(
            dossierId: widget.paymentData['dossier_id'] as String,
            method: _selectedMethod,
            phone: _phoneCtr.text.trim(),
          );
      if (!mounted) return;
      context.pushReplacement(
        AppRoutes.paymentSuccess,
        extra: widget.paymentData['dossier_id'] as String,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(paymentProvider).isLoading;
    final label = widget.paymentData['label'] as String? ?? 'Certificat';
    final montant = widget.paymentData['montant'] as int? ?? 500;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payer les frais'),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Résumé demande ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              color: AppColors.textOnPrimary, size: 32),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label,
                                    style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.textOnPrimary)),
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.amountFCFA(montant),
                                  style: AppTextStyles.amount.copyWith(
                                      color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Choix méthode paiement ──────────────
                    Text('Méthode de paiement',
                        style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 16),
                    ..._paymentMethods.map((m) => _PaymentMethodCard(
                          method: m,
                          isSelected: _selectedMethod == m.id,
                          onTap: () =>
                              setState(() => _selectedMethod = m.id),
                        )),
                    const SizedBox(height: 24),

                    // ── Numéro de téléphone ─────────────────
                    Text('Numéro de paiement',
                        style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 12),
                    PhoneTextField(
                      controller: _phoneCtr,
                      onChanged: (v) => setState(() =>
                          _phoneValid = v.replaceAll(' ', '').length == 9),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Un reçu vous sera envoyé par SMS après confirmation.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: 'Confirmer le paiement — '
                    '${AppFormatters.amountFCFA(montant)}',
                onPressed: _pay,
                isLoading: isLoading,
                isEnabled: _phoneValid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _paymentMethods = [
    _PaymentMethod(
      id: AppConstants.paymentWave,
      name: 'Wave',
      color: Color(0xFF1BA0E9),
      icon: Icons.waves_outlined,
    ),
    _PaymentMethod(
      id: AppConstants.paymentOrangeMoney,
      name: 'Orange Money',
      color: Color(0xFFFF6900),
      icon: Icons.account_balance_wallet_outlined,
    ),
    _PaymentMethod(
      id: AppConstants.paymentFreeMoney,
      name: 'Free Money',
      color: Color(0xFFE30613),
      icon: Icons.payments_outlined,
    ),
  ];
}

class _PaymentMethod {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  const _PaymentMethod({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });
}

class _PaymentMethodCard extends StatelessWidget {
  final _PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? method.color.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? method.color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: method.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(method.icon, color: method.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(method.name, style: AppTextStyles.labelLarge),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: method.color,
            ),
          ],
        ),
      ),
    );
  }
}
DART
echo "  ✅ payment_screen.dart"

cat > lib/features/payment/presentation/screens/payment_success_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/assets_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';

/// S11A — Succès paiement (animation Lottie)
class PaymentSuccessScreen extends StatefulWidget {
  final String dossierId;
  const PaymentSuccessScreen({super.key, required this.dossierId});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Animation Lottie succès
              Lottie.asset(
                Assets.lottieSuccess,
                controller: _ctrl,
                width: 200,
                height: 200,
                onLoaded: (comp) {
                  _ctrl
                    ..duration = comp.duration
                    ..forward();
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Paiement confirmé !',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Votre demande a été soumise avec succès.\n'
                'Vous recevrez un SMS de confirmation.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Carte info dossier
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.statusGreenLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.secondary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dossier créé',
                              style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.secondary)),
                          Text(
                            'Réf: ${widget.dossierId}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Suivre mon dossier',
                onPressed: () => context.go(AppRoutes.dossiers),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(
                  "Retour à l'accueil",
                  style: AppTextStyles.linkPrimary,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
DART
echo "  ✅ payment_success_screen.dart"

# ════════════════════════════════════════════════════════════
# FEATURE DOSSIERS
# ════════════════════════════════════════════════════════════

cat > lib/features/dossiers/presentation/providers/dossiers_provider.dart << 'DART'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/remote_datasource.dart';
import '../../data/models/dossier_model.dart';

final dossiersListProvider =
    FutureProvider.autoDispose<List<DossierModel>>((ref) async {
  final ds = DossiersRemoteDatasource(
      client: ref.read(dioClientProvider));
  return ds.getDossiers();
});

final dossierDetailProvider =
    FutureProvider.autoDispose.family<DossierModel, String>((ref, id) async {
  final ds = DossiersRemoteDatasource(
      client: ref.read(dioClientProvider));
  return ds.getDossierById(id);
});
DART
echo "  ✅ dossiers_provider.dart"

cat > lib/features/dossiers/presentation/screens/dossiers_list_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../data/models/dossier_model.dart';
import '../providers/dossiers_provider.dart';

/// S12 — Liste des dossiers
class DossiersListScreen extends ConsumerWidget {
  const DossiersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dossiers = ref.watch(dossiersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes dossiers'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(dossiersListProvider),
          ),
        ],
      ),
      body: dossiers.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: DossierListSkeleton(),
        ),
        error: (err, _) => _ErrorView(
          onRetry: () => ref.invalidate(dossiersListProvider),
        ),
        data: (list) => list.isEmpty
            ? const _EmptyView()
            : RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () async =>
                    ref.invalidate(dossiersListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _DossierCard(dossier: list[i]),
                ),
              ),
      ),
    );
  }
}

class _DossierCard extends StatelessWidget {
  final DossierModel dossier;
  const _DossierCard({required this.dossier});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
          AppRoutes.dossierDetailPath(dossier.id)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppFormatters.certTypeLabel(dossier.type),
                        style: AppTextStyles.labelLarge,
                      ),
                      if (dossier.beneficiaryNom != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          dossier.beneficiaryNom!,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                StatusBadge(status: dossier.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  AppFormatters.dateShort(dossier.createdAt),
                  style: AppTextStyles.caption,
                ),
                if (dossier.communeNom != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dossier.communeNom!,
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            DossierProgressStepper(currentStatus: dossier.status),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 72, color: AppColors.border),
            const SizedBox(height: 16),
            Text('Aucun dossier', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Vos demandes de certificats apparaîtront ici.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('Impossible de charger', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Vérifiez votre connexion et réessayez.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
DART
echo "  ✅ dossiers_list_screen.dart"

cat > lib/features/dossiers/presentation/screens/dossier_detail_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/recap_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../providers/dossiers_provider.dart';

/// S12A — Détail d'un dossier
class DossierDetailScreen extends ConsumerWidget {
  final String dossierId;
  const DossierDetailScreen({super.key, required this.dossierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dossier = ref.watch(dossierDetailProvider(dossierId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail du dossier'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: dossier.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              DossierCardSkeleton(),
              SizedBox(height: 16),
              DossierCardSkeleton(),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Dossier introuvable', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
        data: (d) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── En-tête statut ──────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppFormatters.certTypeLabel(d.type),
                        style: AppTextStyles.headlineMedium,
                      ),
                    ),
                    StatusBadge(status: d.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Réf: ${d.id}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 20),

                // ── Stepper progression ─────────────────────
                DossierProgressStepper(currentStatus: d.status),
                const SizedBox(height: 24),

                // ── Infos dossier ───────────────────────────
                RecapCard(
                  title: 'Informations',
                  fields: [
                    RecapField(
                      label: 'Type',
                      value: AppFormatters.certTypeLabel(d.type),
                      icon: Icons.article_outlined,
                    ),
                    RecapField(
                      label: 'Statut',
                      value: AppFormatters.statusLabel(d.status),
                      icon: Icons.info_outline,
                      valueColor: _statusColor(d.status),
                    ),
                    RecapField(
                      label: 'Date de demande',
                      value: AppFormatters.dateWithTime(d.createdAt),
                      icon: Icons.calendar_today_outlined,
                    ),
                    if (d.communeNom != null)
                      RecapField(
                        label: 'Commune',
                        value: d.communeNom!,
                        icon: Icons.location_on_outlined,
                      ),
                    if (d.beneficiaryNom != null)
                      RecapField(
                        label: 'Bénéficiaire',
                        value: d.beneficiaryNom!,
                        icon: Icons.person_outline,
                      ),
                    if (d.fraisFCFA != null)
                      RecapField(
                        label: 'Frais payés',
                        value: AppFormatters.amountFCFA(d.fraisFCFA!),
                        icon: Icons.receipt_outlined,
                        valueColor: AppColors.secondary,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Délai estimé si en cours ─────────────────
                if (d.status != 'pret' && d.status != 'rejete')
                  _DelayCard(type: d.type),

                // ── Bouton télécharger si prêt ───────────────
                if (d.status == 'pret') ...[
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Télécharger le certificat',
                    leadingIcon: Icons.download_outlined,
                    onPressed: () => _download(context, d.id),
                  ),
                ],

                // ── Message rejet ────────────────────────────
                if (d.status == 'rejete')
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.statusRedLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.statusRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_outlined,
                            color: AppColors.statusRed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Votre demande a été rejetée. '
                            'Contactez votre commune pour plus d\'informations.',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.statusRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pret':
      case 'valide':
        return AppColors.statusGreen;
      case 'rejete':
        return AppColors.statusRed;
      case 'en_verification':
        return AppColors.statusAmber;
      default:
        return AppColors.statusBlue;
    }
  }

  void _download(BuildContext context, String id) {
    // TODO Étape 8 : téléchargement PDF via dio
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Téléchargement en cours...')),
    );
  }
}

class _DelayCard extends StatelessWidget {
  final String type;
  const _DelayCard({required this.type});

  int get _days {
    switch (type) {
      case 'mariage': return 5;
      default: return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusBlueLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.statusBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined,
              color: AppColors.statusBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Délai estimé : $_days jours ouvrés',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.statusBlue),
            ),
          ),
        ],
      ),
    );
  }
}
DART
echo "  ✅ dossier_detail_screen.dart"

# ════════════════════════════════════════════════════════════
# TESTS
# ════════════════════════════════════════════════════════════

cat > test/core/utils/validators_test.dart << 'DART'
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/core/utils/validators.dart';

void main() {
  group('Validators.phone', () {
    test('accepte un numéro valide sans indicatif', () {
      expect(Validators.phone('771234567'), isNull);
    });

    test('accepte un numéro avec +221', () {
      expect(Validators.phone('+221771234567'), isNull);
    });

    test('refuse un numéro trop court', () {
      expect(Validators.phone('7712345'), isNotNull);
    });

    test('refuse un préfixe invalide', () {
      expect(Validators.phone('991234567'), isNotNull);
    });

    test('refuse une valeur vide', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone(null), isNotNull);
    });
  });

  group('Validators.pin', () {
    test('accepte un PIN valide', () {
      expect(Validators.pin('248631'), isNull);
    });

    test('refuse un PIN trop court', () {
      expect(Validators.pin('1234'), isNotNull);
    });

    test('refuse un PIN trivial 123456', () {
      expect(Validators.pin('123456'), isNotNull);
    });

    test('refuse un PIN trivial 000000', () {
      expect(Validators.pin('000000'), isNotNull);
    });

    test('refuse un PIN avec des lettres', () {
      expect(Validators.pin('12345a'), isNotNull);
    });
  });

  group('Validators.pinConfirmation', () {
    test('valide quand les deux PIN correspondent', () {
      expect(Validators.pinConfirmation('248631', '248631'), isNull);
    });

    test('invalide quand les PIN ne correspondent pas', () {
      expect(Validators.pinConfirmation('248631', '987654'), isNotNull);
    });
  });

  group('Validators.otp', () {
    test('accepte un OTP valide', () {
      expect(Validators.otp('123456'), isNull);
    });

    test('refuse un OTP incomplet', () {
      expect(Validators.otp('12345'), isNotNull);
    });

    test('refuse un OTP avec lettres', () {
      expect(Validators.otp('12345a'), isNotNull);
    });
  });

  group('Validators.fullName', () {
    test('accepte un nom valide', () {
      expect(Validators.fullName('Amadou Diallo'), isNull);
    });

    test('accepte un nom avec apostrophe', () {
      expect(Validators.fullName("N'Diaye Fatou"), isNull);
    });

    test('refuse un nom trop court', () {
      expect(Validators.fullName('Al'), isNotNull);
    });

    test('refuse un nom vide', () {
      expect(Validators.fullName(''), isNotNull);
      expect(Validators.fullName(null), isNotNull);
    });

    test('refuse un nom avec chiffres', () {
      expect(Validators.fullName('Amadou123'), isNotNull);
    });
  });

  group('Validators.registreNumber', () {
    test('accepte un registre valide', () {
      expect(Validators.registreNumber('SN-123456-A'), isNull);
    });

    test('refuse un registre trop court', () {
      expect(Validators.registreNumber('AB'), isNotNull);
    });

    test('refuse une valeur vide', () {
      expect(Validators.registreNumber(''), isNotNull);
    });
  });

  group('Validators.dateNaissance', () {
    test('accepte une date valide dans le passé', () {
      expect(
        Validators.dateNaissance(DateTime(1990, 5, 15)),
        isNull,
      );
    });

    test('refuse une date dans le futur', () {
      expect(
        Validators.dateNaissance(DateTime.now().add(const Duration(days: 1))),
        isNotNull,
      );
    });

    test('refuse null', () {
      expect(Validators.dateNaissance(null), isNotNull);
    });
  });

  group('Validators.anneeMarriage', () {
    test('accepte une année valide', () {
      expect(Validators.anneeMarriage(2015), isNull);
    });

    test('refuse une année future', () {
      expect(Validators.anneeMarriage(DateTime.now().year + 1), isNotNull);
    });

    test('refuse une année avant 1900', () {
      expect(Validators.anneeMarriage(1850), isNotNull);
    });

    test('refuse null', () {
      expect(Validators.anneeMarriage(null), isNotNull);
    });
  });

  group('Validators.commune', () {
    test('accepte une commune sélectionnée', () {
      expect(Validators.commune('DK-DK-01'), isNull);
    });

    test('refuse une valeur vide', () {
      expect(Validators.commune(''), isNotNull);
      expect(Validators.commune(null), isNotNull);
    });
  });
}
DART
echo "  ✅ validators_test.dart"

cat > test/core/utils/formatters_test.dart << 'DART'
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/core/utils/formatters.dart';

void main() {
  group('AppFormatters.amountFCFA', () {
    test('formate 500 FCFA correctement', () {
      final result = AppFormatters.amountFCFA(500);
      expect(result, contains('500'));
      expect(result, contains('FCFA'));
    });

    test('formate 1000 FCFA avec espace', () {
      final result = AppFormatters.amountFCFA(1000);
      expect(result, contains('1'));
      expect(result, contains('000'));
      expect(result, contains('FCFA'));
    });
  });

  group('AppFormatters.phoneNumber', () {
    test('formate un numéro 9 chiffres sans indicatif', () {
      final result = AppFormatters.phoneNumber('771234567');
      expect(result, equals('+221 77 123 45 67'));
    });

    test('formate un numéro avec +221', () {
      final result = AppFormatters.phoneNumber('+221771234567');
      expect(result, contains('+221'));
    });
  });

  group('AppFormatters.initials', () {
    test('retourne deux initiales pour un nom complet', () {
      expect(AppFormatters.initials('Amadou Diallo'), equals('AD'));
    });

    test('retourne deux lettres pour un nom unique', () {
      final result = AppFormatters.initials('Fatou');
      expect(result.length, equals(2));
    });

    test('gère un nom avec plusieurs mots', () {
      expect(AppFormatters.initials('Moussa Ba Diop'), equals('MD'));
    });
  });

  group('AppFormatters.titleCase', () {
    test('capitalise correctement', () {
      expect(AppFormatters.titleCase('amadou diallo'), equals('Amadou Diallo'));
    });

    test('gère un mot unique', () {
      expect(AppFormatters.titleCase('dakar'), equals('Dakar'));
    });
  });

  group('AppFormatters.statusLabel', () {
    test('retourne le bon libellé pour chaque statut', () {
      expect(AppFormatters.statusLabel('soumis'), equals('Soumis'));
      expect(AppFormatters.statusLabel('en_verification'), equals('En vérification'));
      expect(AppFormatters.statusLabel('valide'), equals('Validé'));
      expect(AppFormatters.statusLabel('pret'), equals('Prêt'));
      expect(AppFormatters.statusLabel('rejete'), equals('Rejeté'));
      expect(AppFormatters.statusLabel('en_cours'), equals('En cours'));
    });
  });

  group('AppFormatters.certTypeLabel', () {
    test('retourne le bon libellé pour chaque type', () {
      expect(AppFormatters.certTypeLabel('naissance'),
          equals('Certificat de naissance'));
      expect(AppFormatters.certTypeLabel('deces'),
          equals('Certificat de décès'));
      expect(AppFormatters.certTypeLabel('mariage'),
          equals('Certificat de mariage'));
    });
  });

  group('AppFormatters.truncate', () {
    test('ne tronque pas si texte assez court', () {
      expect(AppFormatters.truncate('Bonjour', 20), equals('Bonjour'));
    });

    test('tronque et ajoute ... si trop long', () {
      final result = AppFormatters.truncate('Texte très long qui dépasse', 10);
      expect(result.length, equals(10));
      expect(result, endsWith('...'));
    });
  });

  group('AppFormatters.timeAgo', () {
    test("retourne à l'instant pour moins d'une minute", () {
      final now = DateTime.now().subtract(const Duration(seconds: 30));
      expect(AppFormatters.timeAgo(now), equals("à l'instant"));
    });

    test('retourne hier pour une date hier', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(AppFormatters.timeAgo(yesterday), equals('hier'));
    });
  });
}
DART
echo "  ✅ formatters_test.dart"

cat > test/features/auth/auth_models_test.dart << 'DART'
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/features/auth/data/models/auth_response_model.dart';
import 'package:teranga_civil/features/auth/domain/models/user_model.dart';

void main() {
  group('LoginResponseModel.fromJson', () {
    test('parse correctement une réponse valide', () {
      final json = {
        'token': 'abc123',
        'user_id': 'user_001',
        'needs_otp': false,
      };
      final model = LoginResponseModel.fromJson(json);
      expect(model.token, equals('abc123'));
      expect(model.userId, equals('user_001'));
      expect(model.needsOtp, isFalse);
    });

    test('gère les champs manquants avec des valeurs par défaut', () {
      final model = LoginResponseModel.fromJson({});
      expect(model.token, equals(''));
      expect(model.userId, equals(''));
      expect(model.needsOtp, isFalse);
    });

    test('parse needs_otp = true', () {
      final model = LoginResponseModel.fromJson({
        'token': 'tok',
        'user_id': 'u1',
        'needs_otp': true,
      });
      expect(model.needsOtp, isTrue);
    });
  });

  group('UserResponseModel.fromJson', () {
    test('parse correctement et convertit en domaine', () {
      final json = {
        'id': 'u_001',
        'phone': '771234567',
        'nom': 'Amadou Diallo',
        'registre': 'SN-123456-A',
        'date_naissance': '1990-05-15',
        'commune_id': 'DK-DK-01',
        'commune_nom': 'Dakar Plateau',
      };
      final model = UserResponseModel.fromJson(json);
      expect(model.nom, equals('Amadou Diallo'));

      final domain = model.toDomain();
      expect(domain, isA<UserModel>());
      expect(domain.nom, equals('Amadou Diallo'));
      expect(domain.communeNom, equals('Dakar Plateau'));
      expect(domain.dateNaissance, equals(DateTime(1990, 5, 15)));
    });

    test('gère une date invalide sans crash', () {
      final json = {
        'id': 'u1', 'phone': '77', 'nom': 'Test',
        'registre': 'SN', 'date_naissance': 'invalid',
        'commune_id': 'c1', 'commune_nom': 'Test',
      };
      final domain = UserResponseModel.fromJson(json).toDomain();
      expect(domain.dateNaissance, equals(DateTime(1990)));
    });
  });

  group('UserModel.copyWith', () {
    test('copie en modifiant uniquement les champs spécifiés', () {
      final user = UserModel(
        id: '1', phone: '77', nom: 'Amadou',
        registre: 'SN-1', dateNaissance: DateTime(1990),
        communeId: 'c1', communeNom: 'Dakar',
      );
      final updated = user.copyWith(nom: 'Fatou');
      expect(updated.nom, equals('Fatou'));
      expect(updated.id, equals('1')); // inchangé
      expect(updated.communeNom, equals('Dakar')); // inchangé
    });
  });
}
DART
echo "  ✅ auth_models_test.dart"

cat > test/features/dossiers/dossier_model_test.dart << 'DART'
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/features/dossiers/data/models/dossier_model.dart';

void main() {
  group('DossierModel.fromJson', () {
    test('parse correctement un dossier valide', () {
      final json = {
        'id': 'd_001',
        'type': 'naissance',
        'status': 'en_verification',
        'created_at': '2024-03-15T10:30:00.000Z',
        'commune_nom': 'Dakar Plateau',
        'beneficiary_nom': 'Amadou Diallo',
        'frais': 500,
      };
      final model = DossierModel.fromJson(json);
      expect(model.id, equals('d_001'));
      expect(model.type, equals('naissance'));
      expect(model.status, equals('en_verification'));
      expect(model.communeNom, equals('Dakar Plateau'));
      expect(model.fraisFCFA, equals(500));
    });

    test('gère les champs optionnels null', () {
      final json = {
        'id': 'd_002',
        'type': 'deces',
        'status': 'soumis',
        'created_at': '2024-03-15T10:30:00.000Z',
      };
      final model = DossierModel.fromJson(json);
      expect(model.communeNom, isNull);
      expect(model.beneficiaryNom, isNull);
      expect(model.fraisFCFA, isNull);
    });

    test('utilise DateTime.now() si created_at invalide', () {
      final json = {
        'id': 'd_003',
        'type': 'mariage',
        'status': 'pret',
        'created_at': 'date-invalide',
      };
      final model = DossierModel.fromJson(json);
      final diff = DateTime.now().difference(model.createdAt);
      expect(diff.inSeconds.abs(), lessThan(5));
    });

    test('statut par défaut = soumis si absent', () {
      final json = {
        'id': 'd_004',
        'type': 'naissance',
        'created_at': '2024-01-01T00:00:00.000Z',
      };
      final model = DossierModel.fromJson(json);
      expect(model.status, equals('soumis'));
    });
  });
}
DART
echo "  ✅ dossier_model_test.dart"

cat > test/features/payment/payment_model_test.dart << 'DART'
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/features/payment/data/models/payment_model.dart';

void main() {
  group('PaymentModel.fromJson', () {
    test('parse un paiement réussi', () {
      final json = {
        'success': true,
        'receipt': 'REC-2024-001',
        'transaction_id': 'TXN-ABC123',
      };
      final model = PaymentModel.fromJson(json);
      expect(model.success, isTrue);
      expect(model.receipt, equals('REC-2024-001'));
      expect(model.transactionId, equals('TXN-ABC123'));
    });

    test('parse un paiement échoué', () {
      final json = {'success': false};
      final model = PaymentModel.fromJson(json);
      expect(model.success, isFalse);
      expect(model.receipt, isNull);
      expect(model.transactionId, isNull);
    });

    test('gère les champs manquants', () {
      final model = PaymentModel.fromJson({});
      expect(model.success, isFalse);
    });
  });
}
DART
echo "  ✅ payment_model_test.dart"

echo ""
echo "✅ Étape 7 terminée — 12 fichiers créés"
echo ""
echo "Fichiers générés :"
echo "  lib/features/payment/data/models/payment_model.dart"
echo "  lib/features/payment/data/remote_datasource.dart"
echo "  lib/features/payment/presentation/providers/payment_provider.dart"
echo "  lib/features/payment/presentation/screens/payment_screen.dart"
echo "  lib/features/payment/presentation/screens/payment_success_screen.dart"
echo "  lib/features/dossiers/presentation/providers/dossiers_provider.dart"
echo "  lib/features/dossiers/presentation/screens/dossiers_list_screen.dart"
echo "  lib/features/dossiers/presentation/screens/dossier_detail_screen.dart"
echo "  test/core/utils/validators_test.dart"
echo "  test/core/utils/formatters_test.dart"
echo "  test/features/auth/auth_models_test.dart"
echo "  test/features/dossiers/dossier_model_test.dart"
echo "  test/features/payment/payment_model_test.dart"
echo ""
echo "Lancer les tests :"
echo "  flutter test"
