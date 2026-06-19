import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Indicateur de progression à 3 étapes — design premium.
enum CertStep { formulaire, recap, paiement }

class CertificateStepIndicator extends StatelessWidget {
  final CertStep currentStep;
  const CertificateStepIndicator(
      {super.key, required this.currentStep});

  static const _labels = ['Formulaire', 'Récapitulatif', 'Paiement'];
  static const _icons = [
    Icons.edit_note_rounded,
    Icons.checklist_rounded,
    Icons.payment_rounded,
  ];

  int get _current => currentStep.index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: List.generate(3, (i) {
          final done   = i < _current;
          final active = i == _current;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      // ── Cercle ──────────────────────────
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: done
                              ? AppColors.secondaryGradient
                              : active
                                  ? AppColors.primaryGradient
                                  : null,
                          color: (!done && !active)
                              ? AppColors.background
                              : null,
                          border: Border.all(
                            color: done
                                ? AppColors.secondary
                                : active
                                    ? AppColors.primaryLight
                                    : AppColors.border,
                            width: active ? 2 : 1,
                          ),
                          boxShadow: done || active
                              ? [
                                  BoxShadow(
                                    color: (done
                                            ? AppColors.secondary
                                            : AppColors.primary)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 18)
                              : Icon(
                                  _icons[i],
                                  color: active
                                      ? Colors.white
                                      : AppColors.textHint,
                                  size: 18,
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // ── Label ────────────────────────────
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: AppTextStyles.caption.copyWith(
                          color: done
                              ? AppColors.secondary
                              : active
                                  ? AppColors.primary
                                  : AppColors.textHint,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: active ? 11 : 10,
                        ),
                        child: Text(
                          _labels[i],
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Ligne de connexion ───────────────
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: i < _current
                            ? AppColors.secondaryGradient
                            : null,
                        color: i < _current ? null : AppColors.border,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
