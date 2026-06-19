import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/certificate_step_indicator.dart';
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
    // Validation du numéro avant tout appel réseau : si le bouton est
    // tapé sans numéro valide, on l'informe au lieu de ne rien faire.
    final phone = _phoneCtr.text.replaceAll(' ', '');
    if (phone.length != 9) {
      setState(() => _phoneValid = false);
      _showSnack('Veuillez saisir un numéro de paiement valide (9 chiffres).');
      return;
    }

    final dossierId = widget.paymentData['dossier_id'] as String?;
    if (dossierId == null || dossierId.isEmpty) {
      _showSnack(
          'Dossier introuvable. Veuillez recommencer votre demande.');
      return;
    }

    try {
      await ref.read(paymentProvider.notifier).pay(
            dossierId: dossierId,
            method: _selectedMethod,
            phone: _phoneCtr.text.trim(),
          );
      if (!mounted) return;
      context.pushReplacement(
        AppRoutes.paymentSuccess,
        extra: dossierId,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(_paymentErrorMessage(e));
    }
  }

  /// Affichage différé après la frame en cours : si le SnackBar est
  /// déclenché juste après une mise à jour d'état (isLoading), l'appel
  /// peut être silencieusement ignoré. addPostFrameCallback garantit
  /// qu'il s'affiche bien (même fix que sur l'écran de connexion).
  void _showSnack(String msg) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
    });
  }

  /// Traduit les erreurs techniques (Dio, API) en message lisible.
  String _paymentErrorMessage(Object e) {
    if (e is ApiException) return e.message;
    if (e is PaymentException) return e.message;
    if (e is DioException) {
      // Le NetworkInterceptor encapsule l'exception métier (ApiException,
      // ForbiddenException, etc.) dans le champ `error` du DioException.
      final inner = e.error;
      if (inner is ApiException) return inner.message;
      if (inner is PaymentException) return inner.message;
      if (inner is UnauthorizedException) return inner.message;
      if (inner is ForbiddenException) return inner.message;
      if (inner is NotFoundException) return inner.message;
      if (inner is ServerException) return inner.message;
      if (inner is NetworkException) return inner.message;
      if (inner is TimeoutException) return inner.message;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'La requête a expiré. Vérifiez votre connexion.';
        case DioExceptionType.connectionError:
          return 'Pas de connexion internet.';
        default:
          return 'Le paiement a échoué. Veuillez réessayer.';
      }
    }
    return 'Le paiement a échoué. Veuillez réessayer.';
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
            // ── Stepper progression ──────────────────────
            const CertificateStepIndicator(currentStep: CertStep.paiement),
            const SizedBox(height: 8),
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? method.color : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: method.color,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
