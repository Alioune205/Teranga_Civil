import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Bouton principal TERANGA CIVIL — dégradé navy + lueur + animation press.
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final IconData? leadingIcon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.leadingIcon,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  bool get _active =>
      widget.isEnabled && !widget.isLoading && widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.965).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (!_active) return;
    _ctrl.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(_) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _active ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: widget.width ?? double.infinity,
          height: 54,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: _active ? AppColors.primaryGradient : null,
              color: _active ? null : AppColors.buttonDisabledBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _active
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: -2,
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: Colors.white.withValues(alpha: 0.15),
                  highlightColor: Colors.transparent,
                  onTap: null,
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _active
                                    ? Colors.white
                                    : AppColors.buttonDisabledText,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.leadingIcon != null) ...[
                                Icon(widget.leadingIcon,
                                    size: 20,
                                    color: _active
                                        ? Colors.white
                                        : AppColors.buttonDisabledText),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.label,
                                style: AppTextStyles.buttonPrimary.copyWith(
                                  color: _active
                                      ? Colors.white
                                      : AppColors.buttonDisabledText,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton secondaire (outlined) — bordure navy + animation press.
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? leadingIcon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.leadingIcon,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  bool get _active =>
      widget.isEnabled && !widget.isLoading && widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (_active) _ctrl.forward();
      },
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      onTap: _active ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    _active ? AppColors.primary : AppColors.buttonDisabledBg,
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: AppColors.primary.withValues(alpha: 0.06),
                  highlightColor: Colors.transparent,
                  onTap: null,
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  _active
                                      ? AppColors.primary
                                      : AppColors.buttonDisabledText),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.leadingIcon != null) ...[
                                Icon(widget.leadingIcon,
                                    size: 20,
                                    color: _active
                                        ? AppColors.primary
                                        : AppColors.buttonDisabledText),
                                const SizedBox(width: 8),
                              ],
                              Text(widget.label,
                                  style: AppTextStyles.buttonPrimary.copyWith(
                                      color: _active
                                          ? AppColors.primary
                                          : AppColors.buttonDisabledText)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton texte simple (lien)
class LinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const LinkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColors.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: AppTextStyles.link.copyWith(color: color ?? AppColors.secondary),
      ),
    );
  }
}
