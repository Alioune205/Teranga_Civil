import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/otp_input.dart';
import '../providers/auth_provider.dart';

/// S02B — Vérification OTP lors de la reconnexion
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpVerificationScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _otpCtr = TextEditingController();
  // En web, pin_code_fields ne synchronise pas toujours le contrôleur externe :
  // on lit donc directement la valeur fournie par onChanged.
  String _otpCode = '';
  bool _otpComplete = false;
  bool _hasError = false;

  bool get _isEmail => widget.phone.contains('@');

  @override
  void dispose() {
    _otpCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _hasError = false);
    try {
      final code = _otpCode.isNotEmpty ? _otpCode : _otpCtr.text;
      await ref.read(authProvider.notifier).verifyOtp(
            identifier: widget.phone,
            code: code,
          );
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
      setState(() => _hasError = true);
      if (!mounted) return;
      String msg = 'Code invalide.';
      if (e is InvalidOtpFailure) msg = e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _resend() async {
    try {
      await ref
          .read(authProvider.notifier)
          .resendOtp(identifier: widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code renvoyé avec succès.')),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final display = _isEmail
        ? widget.phone
        : AppFormatters.phoneNumber(widget.phone);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vérification de sécurité'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Code envoyé', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Un code à 6 chiffres a été envoyé\n'
                '${_isEmail ? "à l\'adresse" : "au numéro"} $display',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 36),
              Center(
                child: OtpInput(
                  controller: _otpCtr,
                  hasError: _hasError,
                  onChanged: (v) => setState(() {
                    _otpCode = v;
                    _otpComplete = v.length == 6;
                    if (_hasError) _hasError = false;
                  }),
                  onCompleted: (v) {
                    _otpCode = v;
                    _submit();
                  },
                ),
              ),
              if (_hasError) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text('Code incorrect. Veuillez réessayer.',
                      style: AppTextStyles.inputError),
                ),
              ],
              const SizedBox(height: 24),
              Center(child: OtpResendRow(onResend: _resend)),
              const SizedBox(height: 40),
              PrimaryButton(
                label: 'Confirmer et accéder',
                onPressed: _submit,
                isLoading: isLoading,
                isEnabled: _otpComplete,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
