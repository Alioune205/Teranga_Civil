import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Widget OTP 6 cases — utilisé sur S02B, S05.
///
/// Implémentation : un [TextField] invisible capture la saisie (fiable sur
/// toutes les plateformes, y compris le web où `pin_code_fields` ne
/// synchronisait ni son contrôleur ni `onChanged`), surmonté de 6 cases
/// purement visuelles qui affichent chaque chiffre.
class OtpInput extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final void Function(String)? onCompleted;
  final bool hasError;

  const OtpInput({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onCompleted,
    this.hasError = false,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  static const int _length = 6;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;

    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Cases visuelles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_length, (i) {
              final filled = i < text.length;
              final isCurrent = i == text.length && _focus.hasFocus;

              final Color borderColor = widget.hasError
                  ? AppColors.error
                  : filled
                      ? AppColors.secondary
                      : isCurrent
                          ? AppColors.primary
                          : AppColors.border;
              final Color fillColor = widget.hasError
                  ? AppColors.errorLight
                  : filled
                      ? AppColors.successLight
                      : AppColors.surface;

              return Container(
                width: 46,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: borderColor,
                    width: (isCurrent || filled) ? 2 : 1,
                  ),
                ),
                child: Text(
                  filled ? text[i] : '',
                  style: AppTextStyles.otpDigit,
                ),
              );
            }),
          ),
          // Champ invisible qui capture réellement la saisie
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_length),
                ],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                  widget.onChanged(v);
                  if (v.length == _length) widget.onCompleted?.call(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne "Renvoyer le code" avec countdown 60s
class OtpResendRow extends StatefulWidget {
  final VoidCallback onResend;
  final int cooldownSeconds;

  const OtpResendRow({
    super.key,
    required this.onResend,
    this.cooldownSeconds = 60,
  });

  @override
  State<OtpResendRow> createState() => _OtpResendRowState();
}

class _OtpResendRowState extends State<OtpResendRow> {
  late int _remaining;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.cooldownSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          _remaining = 0;
          _canResend = true;
        }
      });
      return _remaining > 0;
    });
  }

  void _handleResend() {
    setState(() {
      _remaining = widget.cooldownSeconds;
      _canResend = false;
    });
    _startCountdown();
    widget.onResend();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Vous n\'avez pas reçu le code ? ',
          style: AppTextStyles.bodySmall,
        ),
        if (_canResend)
          GestureDetector(
            onTap: _handleResend,
            child: Text(
              'Renvoyer',
              style: AppTextStyles.link,
            ),
          )
        else
          Text(
            'Renvoyer (${_remaining}s)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
      ],
    );
  }
}
