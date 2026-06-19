import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';

/// Badge de statut coloré pour les dossiers.
/// Statuts : soumis | en_verification | valide | pret | rejete | en_cours
class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  _BadgeConfig get _config {
    switch (status) {
      case 'soumis':
        return _BadgeConfig(
          color: AppColors.statusBlue,
          bgColor: AppColors.statusBlueLight,
          icon: Icons.upload_outlined,
        );
      case 'en_verification':
        return _BadgeConfig(
          color: AppColors.statusAmber,
          bgColor: AppColors.statusAmberLight,
          icon: Icons.search_outlined,
        );
      case 'valide':
        return _BadgeConfig(
          color: AppColors.statusGreen,
          bgColor: AppColors.statusGreenLight,
          icon: Icons.check_circle_outline,
        );
      case 'pret':
        return _BadgeConfig(
          color: AppColors.statusGreen,
          bgColor: AppColors.statusGreenLight,
          icon: Icons.download_outlined,
        );
      case 'rejete':
        return _BadgeConfig(
          color: AppColors.statusRed,
          bgColor: AppColors.statusRedLight,
          icon: Icons.cancel_outlined,
        );
      case 'en_cours':
      default:
        return _BadgeConfig(
          color: AppColors.statusAmber,
          bgColor: AppColors.statusAmberLight,
          icon: Icons.hourglass_empty_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: cfg.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, size: compact ? 12 : 14, color: cfg.color),
          const SizedBox(width: 4),
          Text(
            AppFormatters.statusLabel(status),
            style: AppTextStyles.badgeText.copyWith(color: cfg.color),
          ),
        ],
      ),
    );
  }
}

/// Stepper horizontal de progression du dossier
class DossierProgressStepper extends StatelessWidget {
  final String currentStatus;

  const DossierProgressStepper({super.key, required this.currentStatus});

  static const _steps = ['soumis', 'en_verification', 'valide', 'pret'];

  int get _currentIndex {
    final idx = _steps.indexOf(currentStatus);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Ligne de connexion
          final stepIdx = i ~/ 2;
          final active = stepIdx < _currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: active ? AppColors.secondary : AppColors.border,
            ),
          );
        }
        // Point de step
        final stepIdx = i ~/ 2;
        final done = stepIdx < _currentIndex;
        final current = stepIdx == _currentIndex;
        return _StepDot(
          done: done,
          current: current,
          label: AppFormatters.statusLabel(_steps[stepIdx]),
        );
      }),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool done;
  final bool current;
  final String label;

  const _StepDot({required this.done, required this.current, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = done || current ? AppColors.secondary : AppColors.border;
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.secondary : AppColors.surface,
            border: Border.all(color: color, width: 2),
          ),
          child: done
              ? const Icon(Icons.check, size: 10, color: AppColors.textOnPrimary)
              : current
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary,
                        ),
                      ),
                    )
                  : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: done || current ? AppColors.secondary : AppColors.textHint,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _BadgeConfig {
  final Color color;
  final Color bgColor;
  final IconData icon;
  const _BadgeConfig({required this.color, required this.bgColor, required this.icon});
}
