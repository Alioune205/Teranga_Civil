import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/assets_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterStep1Screen extends ConsumerStatefulWidget {
  const RegisterStep1Screen({super.key});

  @override
  ConsumerState<RegisterStep1Screen> createState() =>
      _RegisterStep1ScreenState();
}

class _RegisterStep1ScreenState extends ConsumerState<RegisterStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomCtr = TextEditingController();
  final _nomCtr = TextEditingController();
  final _identifierCtr = TextEditingController();
  final _passwordCtr = TextEditingController();
  final _confirmCtr = TextEditingController();

  bool _usePhone = true;
  bool _acceptCgu = false;
  bool _acceptPolitique = false;

  @override
  void dispose() {
    _prenomCtr.dispose();
    _nomCtr.dispose();
    _identifierCtr.dispose();
    _passwordCtr.dispose();
    _confirmCtr.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _prenomCtr.text.trim().isNotEmpty &&
      _nomCtr.text.trim().isNotEmpty &&
      _identifierCtr.text.trim().isNotEmpty &&
      _passwordCtr.text.length >= 8 &&
      _confirmCtr.text == _passwordCtr.text &&
      _acceptCgu &&
      _acceptPolitique;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptCgu || !_acceptPolitique) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter les conditions et la politique.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ref.read(registrationDataProvider.notifier).update((d) => d.copyWith(
          prenom: _prenomCtr.text.trim(),
          nom: _nomCtr.text.trim(),
          password: _passwordCtr.text,
          phone: _usePhone ? _identifierCtr.text.trim() : null,
          email: !_usePhone ? _identifierCtr.text.trim() : null,
          usePhone: _usePhone,
        ));

    try {
      final result = await ref.read(authProvider.notifier).register(
            prenom: _prenomCtr.text.trim(),
            nom: _nomCtr.text.trim(),
            password: _passwordCtr.text,
            phone: _usePhone ? _identifierCtr.text.trim() : null,
            email: !_usePhone ? _identifierCtr.text.trim() : null,
          );
      if (!mounted) return;
      if (result.needsOtp) {
        // Le backend demande une vérification OTP.
        context.push(AppRoutes.registerStep3, extra: {
          'identifier': result.identifier,
          'otpDebug': result.otpDebug,
        });
      } else {
        // Le backend a créé et connecté le compte directement → accueil.
        ref.read(registrationDataProvider.notifier).reset();
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (!mounted) return;
      String msg = 'Une erreur est survenue.';
      if (e is PhoneAlreadyExistsFailure) {
        msg = _usePhone
            ? 'Ce numéro est déjà associé à un compte.'
            : 'Cette adresse email est déjà associée à un compte.';
      } else if (e is NetworkFailure) {
        msg = e.message;
      } else if (e is ValidationFailure) {
        msg = e.message;
      } else if (e is Failure) {
        msg = e.message;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Impossible d\'ouvrir : $url'),
            backgroundColor: AppColors.error),
      );
    }
  }

  static const _navy = Color(0xFF0A1F5C);
  static const _green = Color(0xFF1D9E75);

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: _navy),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),

            // ── Contenu scrollable ───────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Form(
                  key: _formKey,
                  onChanged: () => setState(() {}),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Logo ─────────────────────────────────
                      Image.asset(Assets.logoTeranga,
                          width: 100, height: 100, fit: BoxFit.contain),
                      const SizedBox(height: 0),

                      // ── Titre ─────────────────────────────────
                      const Text(
                        'Créer un compte',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 36,
                        height: 3,
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Remplissez le formulaire pour vous inscrire',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 28),

                      // ── Toggle Téléphone / Email ──────────────
                      _buildToggle(),
                      const SizedBox(height: 16),

                      // ── Champ identifiant ─────────────────────
                      if (_usePhone)
                        AppTextField(
                          label: 'Numéro de téléphone',
                          hint: '77 123 45 67',
                          controller: _identifierCtr,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: Validators.phone,
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
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'L\'email est requis.';
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

                      // ── Prénom & Nom ──────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Prénom',
                              hint: 'Amadou',
                              controller: _prenomCtr,
                              validator: Validators.fullName,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'Nom',
                              hint: 'Diallo',
                              controller: _nomCtr,
                              validator: Validators.fullName,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Mot de passe ──────────────────────────
                      AppTextField(
                        label: 'Mot de passe',
                        hint: '••••••••',
                        controller: _passwordCtr,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.length < 8)
                            return '8 caractères minimum.';
                          return null;
                        },
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(height: 16),

                      // ── Confirmer mot de passe ────────────────
                      AppTextField(
                        label: 'Confirmer le mot de passe',
                        hint: '••••••••',
                        controller: _confirmCtr,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          if (v != _passwordCtr.text)
                            return 'Les mots de passe ne correspondent pas.';
                          return null;
                        },
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(height: 24),

                      // ── CGU ───────────────────────────────────
                      _CheckboxLink(
                        value: _acceptCgu,
                        onChanged: (v) =>
                            setState(() => _acceptCgu = v ?? false),
                        prefix: 'J\'accepte les ',
                        linkText: 'conditions générales d\'utilisation',
                        onLinkTap: () => _openUrl(
                            'https://e-senegal.sn/#/conditions-generales-utilisation'),
                      ),
                      const SizedBox(height: 10),
                      _CheckboxLink(
                        value: _acceptPolitique,
                        onChanged: (v) =>
                            setState(() => _acceptPolitique = v ?? false),
                        prefix: 'J\'accepte la ',
                        linkText: 'politique de confidentialité',
                        onLinkTap: () =>
                            _openUrl('https://e-senegal.sn/#/mentions-legales'),
                      ),
                      const SizedBox(height: 28),

                      // ── Bouton ────────────────────────────────
                      PrimaryButton(
                        label: 'Envoyer le code de vérification',
                        onPressed: _submit,
                        isLoading: isLoading,
                        isEnabled: _isValid,
                      ),
                      const SizedBox(height: 20),

                      // ── Lien connexion ────────────────────────
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Déjà un compte ?  ',
                                style: AppTextStyles.bodyMedium,
                              ),
                              TextSpan(
                                text: 'Se connecter',
                                style: AppTextStyles.link,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
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
            selected: _usePhone,
            onTap: () => setState(() {
              _usePhone = true;
              _identifierCtr.clear();
            }),
          ),
          _ToggleBtn(
            label: 'Email',
            selected: !_usePhone,
            onTap: () => setState(() {
              _usePhone = false;
              _identifierCtr.clear();
            }),
          ),
        ],
      ),
    );
  }
}

// ── Toggle btn ────────────────────────────────────────────────
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
            color: selected ? null : Colors.transparent,
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

// ── Checkbox avec lien ────────────────────────────────────────
class _CheckboxLink extends StatelessWidget {
  final bool value;
  final void Function(bool?) onChanged;
  final String prefix;
  final String linkText;
  final VoidCallback onLinkTap;

  const _CheckboxLink({
    required this.value,
    required this.onChanged,
    required this.prefix,
    required this.linkText,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall,
                children: [
                  TextSpan(text: prefix),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: onLinkTap,
                      child: Text(
                        linkText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
