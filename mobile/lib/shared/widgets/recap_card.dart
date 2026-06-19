import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Card de récapitulatif — design premium avec bordure accent colorée.
/// Utilisée sur S08A, S08C, S09A, S10A.
class RecapCard extends StatelessWidget {
  final String? title;
  final List<RecapField> fields;
  final Widget? trailing;
  final Color? borderColor;
  final Color? accentColor;
  final IconData? titleIcon;

  const RecapCard({
    super.key,
    this.title,
    required this.fields,
    this.trailing,
    this.borderColor,
    this.accentColor,
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Bordure accent gauche ──────────────────────────────
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // ── Contenu ───────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                        child: Row(
                          children: [
                            if (titleIcon != null) ...[
                              Icon(titleIcon, size: 15, color: accent),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              title!,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Divider(
                          height: 20,
                          color: accent.withValues(alpha: 0.15),
                          thickness: 1,
                        ),
                      ),
                    ],
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        title == null ? 14 : 0,
                        14,
                        14,
                      ),
                      child: Column(
                        children: [
                          ...fields.asMap().entries.map((entry) {
                            final isLast = entry.key == fields.length - 1;
                            return Column(
                              children: [
                                _RecapRow(field: entry.value),
                                if (!isLast)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Divider(
                                      height: 1,
                                      color: AppColors.divider,
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      Divider(
                          height: 1, color: accent.withValues(alpha: 0.15)),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: trailing!,
                      ),
                    ],
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

class _RecapRow extends StatelessWidget {
  final RecapField field;
  const _RecapRow({required this.field});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (field.icon != null) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(field.icon, size: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              field.label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              field.value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: field.valueColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ),
      ],
    );
  }
}

/// Modèle d'un champ du récapitulatif
class RecapField {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  const RecapField({
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });
}

/// Bannière d'information (note en bas des récaps)
class InfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.statusBlue;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 8),
          Expanded(
            child:
                Text(message, style: AppTextStyles.caption.copyWith(color: c)),
          ),
        ],
      ),
    );
  }
}
