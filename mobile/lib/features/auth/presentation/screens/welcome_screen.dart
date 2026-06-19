import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/assets_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _navy = Color(0xFF0A1F5C);
  static const _grey = Color(0xFF888888);
  static const _green = Color(0xFF1D9E75);

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  // ── Espace haut ──────────────────────────────
                  SizedBox(height: h * 0.12),

                  // ── Logo ─────────────────────────────────────
                  Image.asset(
                    Assets.logoTeranga,
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),

                  // ── Titre ────────────────────────────────────
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'TERANGA ',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.8,
                          ),
                        ),
                        TextSpan(
                          text: 'CIVIL',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Séparateur vert ───────────────────────────
                  Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Tagline ───────────────────────────────────
                  const Text(
                    "L'administration proche de vous",
                    style: TextStyle(
                      color: _grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  // ── Spacer ────────────────────────────────────
                  const Spacer(),

                  // ── Bouton Se connecter ───────────────────────
                  PrimaryButton(
                    label: 'Se connecter',
                    onPressed: () => context.go(AppRoutes.login),
                    isEnabled: true,
                  ),
                  const SizedBox(height: 16),

                  // ── Lien S'inscrire ───────────────────────────
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.registerStep1),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Pas encore de compte ?  ',
                            style: AppTextStyles.bodyMedium,
                          ),
                          TextSpan(
                            text: "S'inscrire",
                            style: AppTextStyles.link,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.06),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
