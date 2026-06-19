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
