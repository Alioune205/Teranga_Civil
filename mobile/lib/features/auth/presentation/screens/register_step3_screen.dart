import 'package:flutter/foundation.dart';
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

/// S05 — Validation OTP (SMS ou email) → dashboard direct
class RegisterStep3Screen extends ConsumerStatefulWidget {
  final Map<String, dynamic> registrationData;
  const RegisterStep3Screen({super.key, required this.registrationData});

  @override
  ConsumerState<RegisterStep3Screen> createState() =>
      _RegisterStep3ScreenState();
}

class _RegisterStep3ScreenState
    extends ConsumerState<RegisterStep3Screen> {
  final _otpCtr = TextEditingController();
  // En web, pin_code_fields ne synchronise pas toujours le contrôleur externe :
  // on lit donc la valeur fournie par onChanged.
  String _otpCode = '';
  bool _otpComplete = false;
  bool _hasError = false;

  String get _identifier =>
      widget.registrationData['identifier'] as String? ?? '';

  String? _otpDebug;

  bool get _isEmail => _identifier.contains('@');

  @override
  void initState() {
    super.initState();
    _otpDebug = widget.registrationData['otpDebug'] as String?;
  }

  @override
  void dispose() {
    _otpCtr.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _hasError = false);
    try {
      final code = _otpCode.isNotEmpty ? _otpCode : _otpCtr.text;
      await ref.read(authProvider.notifier).verifyOtp(
            identifier: _identifier,
            code: code,
          );
      if (!mounted) return;
      // Inscription terminée → accéder directement au dashboard
      ref.read(registrationDataProvider.notifier).reset();
      context.go(AppRoutes.home);
    } catch (e) {
      setState(() => _hasError = true);
      if (!mounted) return;
      String msg = 'Code incorrect.';
      if (e is InvalidOtpFailure) msg = e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _resend() async {
    try {
      final newOtpDebug = await ref
          .read(authProvider.notifier)
          .resendOtp(identifier: _identifier);
      if (!mounted) return;
      if (newOtpDebug != null) {
        setState(() => _otpDebug = newOtpDebug);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Code renvoyé sur ${_isEmail ? "votre email" : "votre téléphone"}.'),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final displayId = _isEmail
        ? _identifier
        : AppFormatters.phoneNumber(_identifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vérification'),
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
              const SizedBox(height: 16),
              // Icône selon le type
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.statusGreenLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _isEmail
                        ? Icons.email_outlined
                        : Icons.sms_outlined,
                    color: AppColors.secondary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text('Code de vérification',
                    style: AppTextStyles.headlineMedium),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Un code à 6 chiffres a été envoyé\n'
                  '${_isEmail ? "à l\'adresse" : "au numéro"} $displayId',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              if (kDebugMode && _otpDebug != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.statusGreenLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '[DEBUG] Code : $_otpDebug',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
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
                    _verify();
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
              const Spacer(),
              PrimaryButton(
                label: 'Valider et accéder à mon compte',
                onPressed: _verify,
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
