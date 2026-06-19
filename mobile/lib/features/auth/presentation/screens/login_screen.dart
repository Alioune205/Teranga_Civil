import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/assets_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

/// S02 — Connexion (téléphone ou email + mot de passe)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtr = TextEditingController();
  final _passwordCtr = TextEditingController();
  bool _usePhone = true;
  bool _formValid = false;

  @override
  void dispose() {
    _identifierCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  void _checkValidity() {
    setState(() {
      _formValid = _identifierCtr.text.trim().isNotEmpty &&
          _passwordCtr.text.length >= 6;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final result = await ref.read(authProvider.notifier).login(
            identifier: _identifierCtr.text.trim(),
            password: _passwordCtr.text,
          );
      if (!mounted) return;
      if (result.needsOtp) {
        context.push(AppRoutes.otpVerification,
            extra: _identifierCtr.text.trim());
      } else {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  void _showError(Object e) {
    String msg = 'Une erreur est survenue.';
    if (e is InvalidCredentialsFailure)
      msg = e.message;
    else if (e is NetworkFailure)
      msg = e.message;
    else if (e is TooManyAttemptsFailure)
      msg = e.message;
    else if (e is Failure) msg = e.message;

    // Affichage différé après la frame en cours : si le SnackBar est
    // déclenché pendant une reconstruction (ex. juste après la mise à
    // jour de l'état isLoading), l'appel peut être silencieusement
    // ignoré. addPostFrameCallback garantit qu'il s'affiche bien.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            onChanged: _checkValidity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Devise + trait tricolore centré ──────────

                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'REPUBLIQUE DU SENEGAL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF0A1F5C),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Un peuple - un but - une foi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF0A1F5C),
                        fontSize: 8,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Poppins',
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 30,
                            height: 5,
                            color: const Color(0xFF00853F)),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                                width: 30,
                                height: 5,
                                color: const Color(0xFFFCDD09)),
                            const Text('★',
                                style: TextStyle(
                                  color: Color(0xFF00853F),
                                  fontSize: 6,
                                  height: 1,
                                )),
                          ],
                        ),
                        Container(
                            width: 30,
                            height: 5,
                            color: const Color(0xFFE31B23)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Logo posé directement sur le fond blanc (sans cadre)
                Image.asset(Assets.logoTeranga,
                    width: 148, height: 148, fit: BoxFit.contain),
                const SizedBox(height: 22),
                Text('Se connecter',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'UTILISEZ VOTRE TÉLÉPHONE OU VOTRE EMAIL',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Toggle Téléphone / Email ────────────────
                _IdentifierToggle(
                  usePhone: _usePhone,
                  onChanged: (v) => setState(() {
                    _usePhone = v;
                    _identifierCtr.clear();
                    _formValid = false;
                  }),
                ),
                const SizedBox(height: 16),

                // ── Champ identifiant ───────────────────────
                if (_usePhone)
                  AppTextField(
                    label: 'Numéro de téléphone',
                    hint: '77 123 45 67',
                    controller: _identifierCtr,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: Validators.phone,
                    onChanged: (_) => _checkValidity(),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      child: Text('+221',
                          style: AppTextStyles.inputText.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                  )
                else
                  AppTextField(
                    label: 'Adresse email',
                    hint: 'nom@exemple.com',
                    controller: _identifierCtr,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _checkValidity(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'L\'email est requis.';
                      }
                      if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$')
                          .hasMatch(v.trim())) {
                        return 'Adresse email invalide.';
                      }
                      return null;
                    },
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: AppColors.textSecondary, size: 20),
                  ),
                const SizedBox(height: 16),

                // ── Mot de passe ────────────────────────────
                AppTextField(
                  label: 'Mot de passe',
                  hint: '••••••••',
                  controller: _passwordCtr,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _checkValidity(),
                  onSubmitted: (_) => _formValid ? _submit() : null,
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Mot de passe trop court (6 caractères min).';
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textSecondary, size: 20),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Se connecter',
                  onPressed: _submit,
                  isLoading: isLoading,
                  isEnabled: _formValid,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Pas encore de compte ? ',
                        style: AppTextStyles.bodyMedium),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.registerStep1),
                      child: Text("S'inscrire", style: AppTextStyles.link),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Toggle Téléphone / Email ──────────────────────────────────
class _IdentifierToggle extends StatelessWidget {
  final bool usePhone;
  final void Function(bool) onChanged;
  const _IdentifierToggle({required this.usePhone, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleBtn(
            label: 'Téléphone',
            selected: usePhone,
            onTap: () => onChanged(true),
          ),
          _ToggleBtn(
            label: 'Email',
            selected: !usePhone,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected ? null : AppColors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
