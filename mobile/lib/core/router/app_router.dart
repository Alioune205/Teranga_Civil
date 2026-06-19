import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../shared/layout/main_scaffold.dart';

// ── Auth screens
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/register_step1_screen.dart';
import '../../features/auth/presentation/screens/register_step2_screen.dart';
import '../../features/auth/presentation/screens/register_step3_screen.dart';
import '../../features/auth/presentation/screens/register_step4_screen.dart';

// ── Home
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/category_demarches_screen.dart';
import '../../features/documents/presentation/screens/documents_screen.dart';

// ── Notifications
import '../../features/notifications/presentation/screens/notifications_screen.dart';

// ── Certificates — Naissance
import '../../features/certificates/naissance/presentation/screens/beneficiary_choice_screen.dart';
import '../../features/certificates/naissance/presentation/screens/recap_self_screen.dart';
import '../../features/certificates/naissance/presentation/screens/other_person_screen.dart';
import '../../features/certificates/naissance/presentation/screens/recap_other_screen.dart';

// ── Certificates — Décès
import '../../features/certificates/deces/presentation/screens/deces_form_screen.dart';
import '../../features/certificates/deces/presentation/screens/deces_recap_screen.dart';

// ── Certificates — Mariage
import '../../features/certificates/mariage/presentation/screens/mariage_form_screen.dart';
import '../../features/certificates/mariage/presentation/screens/mariage_recap_screen.dart';
import '../../features/certificates/residence/presentation/screens/residence_form_screen.dart';
import '../../features/certificates/foncier/presentation/screens/foncier_form_screen.dart';

// ── Payment
import '../../features/payment/presentation/screens/payment_screen.dart';
import '../../features/payment/presentation/screens/payment_success_screen.dart';

// ── Agent IA
import '../../features/assistant/presentation/screens/agent_chat_screen.dart';

// ── Dossiers
import '../../features/dossiers/presentation/screens/dossiers_list_screen.dart';
import '../../features/dossiers/presentation/screens/dossier_detail_screen.dart';
import '../../features/appointments/presentation/screens/appointments_screen.dart';

// ── Profile
import '../../features/profile/presentation/screens/profile_screen.dart';

/// Noms de routes — utiliser ces constantes partout (jamais de chaînes en dur)
abstract class AppRoutes {
  // Auth
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const otpVerification = '/otp-verification';
  static const registerStep1 = '/register/step1';
  static const registerStep2 = '/register/step2';
  static const registerStep3 = '/register/step3';
  static const registerStep4 = '/register/step4';

  // Shell (bottom nav)
  static const home = '/home';
  static const dossiers = '/dossiers';
  static const documents = '/documents';
  static const profile = '/profile';

  // Agent IA
  static const agentChat = '/agent-chat';

  // Notifications
  static const notifications = '/notifications';

  // Démarches par catégorie (page pleine écran)
  static const categoryDemarches = '/category-demarches';

  // Naissance
  static const naissanceBeneficiary = '/certificates/naissance/beneficiary';
  static const naissanceRecapSelf = '/certificates/naissance/recap-self';
  static const naissanceOtherPerson = '/certificates/naissance/other-person';
  static const naissanceRecapOther = '/certificates/naissance/recap-other';

  // Décès
  static const decesForm = '/certificates/deces/form';
  static const decesRecap = '/certificates/deces/recap';

  // Mariage
  static const mariageForm = '/certificates/mariage/form';
  static const mariageRecap = '/certificates/mariage/recap';

  // Résidence
  static const residenceForm = '/certificates/residence/form';

  // Foncier (récépissé) — une route par type
  static const foncierRegularisation = '/certificates/foncier/regularisation';
  static const foncierAutorisation = '/certificates/foncier/autorisation';
  static const foncierMutation = '/certificates/foncier/mutation';

  // Paiement
  static const payment = '/payment';
  static const paymentSuccess = '/payment/success';

  // Dossier détail
  static const dossierDetail = '/dossiers/:id';
  static String dossierDetailPath(String id) => '/dossiers/$id';

  // Rendez-vous
  static const appointments = '/appointments';
}

/// Provider du router — consommé dans MaterialApp.router
final appRouterProvider = Provider.family<GoRouter, String>((ref, initialRoute) {
  return GoRouter(
    initialLocation: initialRoute,
    debugLogDiagnostics: true,
    redirect: _globalRedirect,
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
    routes: [
      // ── Splash ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const SplashScreen(),
        ),
      ),

      // ── Welcome ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const WelcomeScreen(),
        ),
      ),

      // ── Auth ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        pageBuilder: (context, state) {
          final phone = state.extra as String? ?? '';
          return _slidePage(
            state: state,
            child: OtpVerificationScreen(phone: phone),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.registerStep1,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const RegisterStep1Screen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.registerStep2,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: RegisterStep2Screen(registrationData: data),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.registerStep3,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: RegisterStep3Screen(registrationData: data),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.registerStep4,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: RegisterStep4Screen(registrationData: data),
          );
        },
      ),

      // ── Shell (Bottom Nav) ──────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          final index = _shellIndex(state.matchedLocation);
          return MainScaffold(currentIndex: index, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => _noTransitionPage(
              state: state,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.dossiers,
            pageBuilder: (context, state) => _noTransitionPage(
              state: state,
              child: const DossiersListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.documents,
            pageBuilder: (context, state) => _noTransitionPage(
              state: state,
              child: const DocumentsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => _noTransitionPage(
              state: state,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),

      // ── Certificat de naissance ─────────────────────────────
      GoRoute(
        path: AppRoutes.naissanceBeneficiary,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const BeneficiaryChoiceScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.naissanceRecapSelf,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const RecapSelfScreen(),
        ),
        routes: [
          GoRoute(
            path: 'recap',
            pageBuilder: (context, state) {
              final data = state.extra as Map<String, dynamic>? ?? {};
              return _slidePage(
                state: state,
                child: RecapOtherScreen(formData: data),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.naissanceOtherPerson,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const OtherPersonScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.naissanceRecapOther,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: RecapOtherScreen(formData: data),
          );
        },
      ),

      // ── Certificat de décès ─────────────────────────────────
      GoRoute(
        path: AppRoutes.decesForm,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const DecesFormScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.decesRecap,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: DecesRecapScreen(formData: data),
          );
        },
      ),

      // ── Certificat de mariage ───────────────────────────────
      GoRoute(
        path: AppRoutes.mariageForm,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const MariageFormScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.mariageRecap,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: MariageRecapScreen(formData: data),
          );
        },
      ),

      // ── Certificat de résidence ─────────────────────────────
      GoRoute(
        path: AppRoutes.residenceForm,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const ResidenceFormScreen(),
        ),
      ),

      // ── Demandes foncières (récépissé) ──────────────────────
      GoRoute(
        path: AppRoutes.foncierRegularisation,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const FoncierFormScreen(config: FoncierConfig.regularisation),
        ),
      ),
      GoRoute(
        path: AppRoutes.foncierAutorisation,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const FoncierFormScreen(
              config: FoncierConfig.autorisationConstruire),
        ),
      ),
      GoRoute(
        path: AppRoutes.foncierMutation,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const FoncierFormScreen(config: FoncierConfig.mutationParcelle),
        ),
      ),

      // ── Paiement ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.payment,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: PaymentScreen(paymentData: data),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        pageBuilder: (context, state) {
          final dossierId = state.extra as String? ?? '';
          return _slidePage(
            state: state,
            child: PaymentSuccessScreen(dossierId: dossierId),
          );
        },
      ),

      // ── Détail dossier (hors shell : poussable depuis liste, accueil,
      //    notifications, rendez-vous… sans recréer le shell) ──
      GoRoute(
        path: AppRoutes.dossierDetail, // '/dossiers/:id'
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _slidePage(
            state: state,
            child: DossierDetailScreen(dossierId: id),
          );
        },
      ),

      // ── Rendez-vous ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.appointments,
        pageBuilder: (context, state) {
          final dossierId = state.extra as String?;
          return _slidePage(
            state: state,
            child: AppointmentsScreen(preselectedDossierId: dossierId),
          );
        },
      ),

      // ── Agent IA ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.agentChat,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const AgentChatScreen(),
        ),
      ),

      // ── Notifications ───────────────────────────────────────
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const NotificationsScreen(),
        ),
      ),

      // ── Démarches par catégorie ─────────────────────────────
      GoRoute(
        path: AppRoutes.categoryDemarches,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: CategoryDemarchesScreen(
              category: data['category'] as String? ?? '',
              items: (data['items'] as List?)
                      ?.cast<Map<String, dynamic>>() ??
                  const [],
            ),
          );
        },
      ),
    ],
  );
});

// ── Redirect global ────────────────────────────────────────────────────────────
// Pas de vérification async ici (lente) — la navigation auth est gérée
// par SplashScreen (token local) et par chaque écran protégé.
Future<String?> _globalRedirect(BuildContext context, GoRouterState state) async {
  return null;
}

// ── Index shell selon la route active ─────────────────────────────────────────
int _shellIndex(String location) {
  if (location.startsWith('/dossiers')) return 1;
  if (location.startsWith('/documents')) return 3;
  if (location.startsWith('/profile')) return 4;
  return 0; // /home par défaut
}

// ── Builders de pages ──────────────────────────────────────────────────────────

/// Page avec transition slide horizontal (standard TERANGA)
CustomTransitionPage<void> _slidePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

/// Page sans transition (tabs bottom nav)
NoTransitionPage<void> _noTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

// ── Écran d'erreur ─────────────────────────────────────────────────────────────
class _ErrorScreen extends StatelessWidget {
  final Exception? error;
  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              const Text(
                'Page introuvable',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? 'Une erreur est survenue.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
