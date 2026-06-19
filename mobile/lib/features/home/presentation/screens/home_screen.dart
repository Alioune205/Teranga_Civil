import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dossiers/presentation/providers/dossiers_provider.dart';
import '../../../dossiers/data/models/dossier_model.dart';
import '../../../appointments/presentation/providers/appointments_provider.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../../core/utils/formatters.dart';
import '../../../notifications/notifications.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _greetingTimer;
  bool _isFrench = true;
  int _messageIndex = 0;

  final List<String> _civicMessages = [
    "Bienvenue sur votre espace personnel.",
    "L'état civil est le socle de vos droits citoyens.",
    "Déclarez vos naissances à temps pour l'avenir de vos enfants.",
    "Un citoyen à jour est un citoyen serein et protégé.",
    "La numérisation sécurise vos documents pour toute la vie.",
  ];

  @override
  void initState() {
    super.initState();
    _greetingTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _isFrench = !_isFrench;
          _messageIndex = (_messageIndex + 1) % _civicMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  void _showNotifications(BuildContext context) {
    context.push(AppRoutes.notifications);
  }

  @override
  Widget build(BuildContext context) {
    // Citoyen connecté (vrai utilisateur via authProvider)
    final user = ref.watch(authProvider).user;
    final prenom = user?.prenom ?? '';
    final commune = user?.communeNom ?? 'Non renseignée';
    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);

    final greetingText =
        _isFrench ? 'Bonjour, $prenom' : 'Dalal akk jamm, $prenom';
    final currentCivicMessage = _civicMessages[_messageIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── TOP HEADER (Avatar, Greeting, Localisation, Icons) ──────
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                gradient: LinearGradient(
                  colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 12.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.profile),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1),
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: Color(0xFF0B285D), size: 26),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 28,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 600),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        greetingText,
                                        key: ValueKey<String>(greetingText),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded,
                                        color: Color(0xFF93C5FD), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      commune,
                                      style: const TextStyle(
                                        color: Color(0xFF93C5FD),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Cloche notifications (branchée)
                          GestureDetector(
                            onTap: () => _showNotifications(context),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Colors.white,
                                      size: 22),
                                ),
                                if (unreadNotifs > 0)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      constraints: const BoxConstraints(
                                          minWidth: 18, minHeight: 18),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: const Color(0xFF0B285D),
                                            width: 1.5),
                                      ),
                                      child: Text(
                                        unreadNotifs > 9
                                            ? '9+'
                                            : '$unreadNotifs',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: SizedBox(
                        height: 72,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 800),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.2),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            currentCivicMessage,
                            key: ValueKey<int>(_messageIndex),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Consumer(
                  builder: (context, ref, _) {
                    // Ndiogoye Proactif : visible uniquement si le citoyen
                    // a déjà au moins une demande, et son contenu est généré
                    // à partir des dossiers réels de l'utilisateur connecté
                    // (pas de texte générique identique pour tout le monde).
                    final dossiers = ref.watch(dossiersListProvider).maybeWhen(
                          data: (d) => d,
                          orElse: () => const <DossierModel>[],
                        );
                    return Column(
                      children: [
                        const _MainActionCard(),
                        const SizedBox(height: 32),
                        if (dossiers.isNotEmpty) ...[
                          _ProactiveAlertCard(dossiers: dossiers),
                          const SizedBox(height: 32),
                        ],
                        const _QuickActionsGrid(),
                        const SizedBox(height: 32),
                        const _TimelineSection(),
                        const SizedBox(height: 32),
                        const _AppointmentsSection(),
                        const SizedBox(height: 32),
                        const _CityHallLocationCard(),
                        const SizedBox(height: 120),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── LA CARTE PRINCIPALE FLOTTANTE ───────────────────────────────────────
class _MainActionCard extends StatefulWidget {
  const _MainActionCard();

  @override
  State<_MainActionCard> createState() => _MainActionCardState();
}

class _MainActionCardState extends State<_MainActionCard> {
  int _currentIndex = 0;
  Timer? _timer;

  final List<String> _recommendations = [
    'Rechercher "Extrait de naissance"...',
    'Demander un "Certificat de mariage"...',
    'Suivre "Mon dossier en cours"...',
    'Rechercher "Certificat de résidence"...',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _recommendations.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B285D).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Que souhaitez-vous faire ?',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showDemarcheSearch(context),
              child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded,
                      color: Color(0xFF3B82F6), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.2),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        key: ValueKey<int>(_currentIndex),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _recommendations[_currentIndex],
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.mic_none_rounded,
                        color: Color(0xFF3B82F6), size: 18),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ── LES DÉMARCHES RAPIDES ───────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Démarches rapides',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSquareCard(
                context,
                'Naissance',
                Icons.person_add_alt_1_rounded,
                const Color(0xFFEFF6FF),
                const Color(0xFF2563EB),
                onTap: () => context.push(AppRoutes.categoryDemarches, extra: {
                  'category': 'Naissance',
                  'items': [
                    {
                      'title': 'Extrait de naissance',
                      'icon': Icons.file_copy_rounded,
                      'route': AppRoutes.naissanceBeneficiary,
                    },
                    {
                      'title': 'Acte de naissance',
                      'icon': Icons.edit_document,
                      'route': null,
                    },
                    {
                      'title': 'Copie littérale',
                      'icon': Icons.file_present_rounded,
                      'route': null,
                    },
                  ],
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSquareCard(
                context,
                'Mariage & famille',
                Icons.people_alt_rounded,
                const Color(0xFFFEF2F2),
                const Color(0xFFDC2626),
                onTap: () => context.push(AppRoutes.categoryDemarches, extra: {
                  'category': 'Mariage & famille',
                  'items': [
                    {
                      'title': 'Certificat de mariage',
                      'icon': Icons.favorite_border_rounded,
                      'route': AppRoutes.mariageForm,
                    },
                    {
                      'title': 'Certificat de célibat',
                      'icon': Icons.file_copy_rounded,
                      'route': null,
                    },
                  ],
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSquareCard(
                context,
                'Décès',
                Icons.folder_special_outlined,
                const Color(0xFFF8FAFC),
                const Color(0xFF475569),
                onTap: () => context.push(AppRoutes.categoryDemarches, extra: {
                  'category': 'Décès',
                  'items': [
                    {
                      'title': 'Certificat de décès',
                      'icon': Icons.assignment_rounded,
                      'route': AppRoutes.decesForm,
                    },
                    {
                      'title': "Permis d'inhumer",
                      'icon': Icons.health_and_safety_rounded,
                      'route': null,
                    },
                  ],
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSquareCard(
                context,
                'Logement & Foncier',
                Icons.home_work_rounded,
                const Color(0xFFFDF4FF),
                const Color(0xFFC026D3),
                onTap: () => context.push(AppRoutes.categoryDemarches, extra: {
                  'category': 'Logement & Foncier',
                  'items': [
                    {
                      'title': 'Certificat de résidence',
                      'icon': Icons.home_outlined,
                      'route': AppRoutes.residenceForm,
                    },
                    {
                      'title': 'Régularisation foncière',
                      'icon': Icons.real_estate_agent_rounded,
                      'route': AppRoutes.foncierRegularisation,
                    },
                    {
                      'title': 'Autorisation de construire',
                      'icon': Icons.architecture_outlined,
                      'route': AppRoutes.foncierAutorisation,
                    },
                    {
                      'title': 'Mutation de parcelle',
                      'icon': Icons.swap_horiz_rounded,
                      'route': AppRoutes.foncierMutation,
                    },
                    {
                      'title': "Permis d'occuper",
                      'icon': Icons.vpn_key_outlined,
                    },
                  ],
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSquareCard(BuildContext context, String title, IconData icon,
      Color bgColor, Color iconColor,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B285D).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── LA TIMELINE (Activité récente, branchée sur dossiersListProvider) ────
class _TimelineSection extends ConsumerWidget {
  const _TimelineSection();

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return "Aujourd'hui";
    if (difference.inDays == 1) return 'Hier';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getDisplayType(String type) {
    switch (type.toLowerCase()) {
      case 'naissance':
        return 'Déclaration de naissance';
      case 'mariage':
        return 'Certificat de mariage';
      case 'deces':
        return 'Certificat de décès';
      case 'residence':
        return 'Certificat de résidence';
      default:
        return 'Demande administrative';
    }
  }

  String _getDisplayStatus(String status) {
    switch (status.toLowerCase()) {
      case 'soumis':
        return 'Soumis';
      case 'en_cours':
        return 'En cours';
      case 'en_verification':
        return 'En vérification';
      case 'valide':
        return 'Validé';
      case 'pret':
        return 'Disponible';
      case 'rejete':
        return 'Rejeté';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B285D).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activité récente',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.go(AppRoutes.dossiers),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tout voir',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            color: Color(0xFF3B82F6), size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ref.watch(dossiersListProvider).when(
                  data: (dossiers) {
                    if (dossiers.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Text(
                            'Aucune activité récente.',
                            style: TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 14),
                          ),
                        ),
                      );
                    }

                    final sortedDossiers = List.of(dossiers)
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    final recentDossiers = sortedDossiers.take(3).toList();

                    return Column(
                      children: List.generate(recentDossiers.length, (index) {
                        final dossier = recentDossiers[index];
                        final isLast = index == recentDossiers.length - 1;
                        final status = dossier.status.toLowerCase();
                        final statusType =
                            (status == 'valide' || status == 'pret')
                                ? 'valide'
                                : (status == 'rejete' ? 'nouveau' : 'en_cours');
                        return _buildTimelineItem(
                          title: _getDisplayType(dossier.type),
                          status: _getDisplayStatus(dossier.status),
                          time: _formatDate(dossier.createdAt),
                          statusType: statusType,
                          isLast: isLast,
                          context: context,
                        );
                      }),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                      ),
                    ),
                  ),
                  error: (err, stack) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'Impossible de charger vos demandes.',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String status,
    required String time,
    required String statusType,
    required bool isLast,
    required BuildContext context,
    String? subtitle,
  }) {
    Color iconBgColor;
    Color iconColor;
    IconData icon;
    Color badgeBgColor;
    Color badgeTextColor;

    if (statusType == 'valide') {
      iconBgColor = const Color(0xFFD1FAE5);
      iconColor = const Color(0xFF059669);
      icon = Icons.check_circle_outline_rounded;
      badgeBgColor = const Color(0xFFD1FAE5);
      badgeTextColor = const Color(0xFF065F46);
    } else if (statusType == 'nouveau') {
      iconBgColor = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.cancel_outlined;
      badgeBgColor = const Color(0xFFFEE2E2);
      badgeTextColor = const Color(0xFF991B1B);
    } else {
      iconBgColor = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFD97706);
      icon = Icons.hourglass_bottom_rounded;
      badgeBgColor = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFF92400E);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── NDIOGOYE PROACTIF (carrousel) ───────────────────────────────────────
class _ProactiveAlertCard extends StatefulWidget {
  final List<DossierModel> dossiers;
  const _ProactiveAlertCard({required this.dossiers});

  @override
  State<_ProactiveAlertCard> createState() => _ProactiveAlertCardState();
}

class _ProactiveAlertCardState extends State<_ProactiveAlertCard> {
  int _currentIndex = 0;
  Timer? _timer;

  static String _typeLabel(String type) {
    switch (type) {
      case 'naissance':
        return 'acte de naissance';
      case 'mariage':
        return 'certificat de mariage';
      case 'deces':
        return 'certificat de décès';
      case 'residence':
        return 'certificat de résidence';
      default:
        return 'document';
    }
  }

  /// Construit une suggestion à partir d'un dossier réel de l'utilisateur
  /// connecté (type + statut réels), au lieu d'un texte générique fixe.
  static Map<String, dynamic> _suggestionFor(DossierModel d) {
    final label = _typeLabel(d.type);
    switch (d.status) {
      case 'pret':
      case 'valide':
        return {
          'icon': Icons.check_circle_outline_rounded,
          'color': const Color(0xFF10B981),
          'bgColor': const Color(0xFFECFDF5),
          'text': 'Votre $label est disponible. Souhaitez-vous le consulter ?',
          'actionText': 'Voir le dossier',
          'actionIcon': Icons.download_rounded,
          'dossierId': d.id,
        };
      case 'rejete':
        return {
          'icon': Icons.warning_amber_rounded,
          'color': const Color(0xFFF59E0B),
          'bgColor': const Color(0xFFFFFBEB),
          'text':
              'Votre demande de $label nécessite une action : pièce manquante ou incomplète.',
          'actionText': 'Corriger maintenant',
          'actionIcon': Icons.upload_file_rounded,
          'dossierId': d.id,
        };
      case 'en_verification':
        return {
          'icon': Icons.hourglass_top_rounded,
          'color': const Color(0xFF3B82F6),
          'bgColor': const Color(0xFFEFF6FF),
          'text': 'Votre demande de $label est en cours de vérification.',
          'actionText': 'Suivre',
          'actionIcon': Icons.arrow_forward_rounded,
          'dossierId': d.id,
        };
      case 'soumis':
        return {
          'icon': Icons.send_rounded,
          'color': const Color(0xFF3B82F6),
          'bgColor': const Color(0xFFEFF6FF),
          'text': 'Votre demande de $label a bien été soumise.',
          'actionText': 'Suivre',
          'actionIcon': Icons.arrow_forward_rounded,
          'dossierId': d.id,
        };
      default: // en_cours / draft
        return {
          'icon': Icons.edit_note_rounded,
          'color': const Color(0xFF94A3B8),
          'bgColor': const Color(0xFFF1F5F9),
          'text': 'Vous avez une demande de $label non terminée.',
          'actionText': 'Continuer',
          'actionIcon': Icons.arrow_forward_rounded,
          'dossierId': d.id,
        };
    }
  }

  /// Priorité d'affichage : pièce manquante (rejeté) > disponible (prêt /
  /// validé) > le reste, puis du plus récent au plus ancien.
  List<Map<String, dynamic>> _buildSuggestions() {
    const priority = {'rejete': 0, 'pret': 1, 'valide': 1};
    final sorted = [...widget.dossiers]
      ..sort((a, b) {
        final pa = priority[a.status] ?? 2;
        final pb = priority[b.status] ?? 2;
        if (pa != pb) return pa.compareTo(pb);
        return b.createdAt.compareTo(a.createdAt);
      });
    return sorted.take(4).map(_suggestionFor).toList();
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        setState(() {
          final count = widget.dossiers.length.clamp(1, 4);
          _currentIndex = (_currentIndex + 1) % count;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _buildSuggestions();
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final currentSuggestion = suggestions[_currentIndex % suggestions.length];

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B285D).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: Color(0xFFFCD34D), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Ndiogoye Proactif',
                          style: TextStyle(
                            color: Color(0xFFFCD34D),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: List.generate(suggestions.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(left: 4),
                          width: _currentIndex == index ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 125,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey<int>(_currentIndex),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: currentSuggestion['bgColor'] as Color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              currentSuggestion['icon'] as IconData,
                              color: currentSuggestion['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSuggestion['text'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () => context.push(
                                      AppRoutes.dossierDetailPath(
                                          currentSuggestion['dossierId']
                                              as String)),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          currentSuggestion['actionText']
                                              as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          currentSuggestion['actionIcon']
                                              as IconData,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push(
                                AppRoutes.dossierDetailPath(
                                    currentSuggestion['dossierId']
                                        as String)),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_forward_ios_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── RENDEZ-VOUS & AGENDA (même habillage de carte que « Activité récente ») ──
class _AppointmentsSection extends ConsumerWidget {
  const _AppointmentsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAppts = ref.watch(appointmentsListProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B285D).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vos rendez-vous',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.appointments),
                  child: const Row(
                    children: [
                      Text(
                        'Prendre RDV',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.add_circle_outline_rounded,
                          color: Color(0xFF3B82F6), size: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            asyncAppts.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))),
              ),
              error: (_, __) => const _AppointmentsEmpty(),
              data: (list) {
                if (list.isEmpty) return const _AppointmentsEmpty();
                final shown = list.take(2).toList();
                return Column(
                  children: [
                    ...shown.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => context.push(AppRoutes.appointments),
                            child: _HomeAppointmentTile(appt: a),
                          ),
                        )),
                    if (list.length > shown.length)
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.appointments),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Voir tous mes rendez-vous (${list.length})',
                            style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentsEmpty extends StatelessWidget {
  const _AppointmentsEmpty();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, color: Color(0xFF94A3B8), size: 32),
            SizedBox(height: 10),
            Text(
              'Aucun rendez-vous programmé',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAppointmentTile extends StatelessWidget {
  final AppointmentModel appt;
  const _HomeAppointmentTile({required this.appt});

  Color get _statusColor {
    switch (appt.status) {
      case 'scheduled':
        return const Color(0xFF2563EB);
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.event_rounded, color: _statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt.dossierReference ?? 'Rendez-vous',
                  style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  appt.scheduledDate != null
                      ? AppFormatters.dateWithTime(appt.scheduledDate!)
                      : 'Date à fixer par la mairie',
                  style: const TextStyle(
                      color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(appt.statusLabel,
                style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── MA MAIRIE LA PLUS PROCHE (statique) ─────────────────────────────────
class _CityHallLocationCard extends StatelessWidget {
  const _CityHallLocationCard();

  Widget _buildNewsItem({
    required String tag,
    required Color tagColor,
    required Color tagBg,
    required String title,
    required String commune,
    required String time,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag.toUpperCase(),
                        style: TextStyle(
                          color: tagColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$commune • $time',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Icon(icon, color: tagColor, size: 22),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ma mairie la plus proche',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B285D).withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.account_balance_rounded,
                        color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mairie de Dakar Plateau',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.directions_walk_rounded,
                                color: Color(0xFF64748B), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'À 450m (6 min à pied)',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                color: Color(0xFF059669), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Ouvert - Ferme à 16h30',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: const Text('Itinéraire'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF6FF),
                        foregroundColor: const Color(0xFF2563EB),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone_outlined, size: 18),
                      label: const Text('Appeler'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 20),
              const Text(
                'Actualités civiques',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              _buildNewsItem(
                tag: 'Alerte',
                tagColor: const Color(0xFFD97706),
                tagBg: const Color(0xFFFEF3C7),
                title:
                    'Fermeture exceptionnelle du guichet 3 ce vendredi matin.',
                commune: 'Dakar Plateau',
                time: 'Il y a 2h',
                icon: Icons.warning_amber_rounded,
              ),
              _buildNewsItem(
                tag: 'Info',
                tagColor: const Color(0xFF2563EB),
                tagBg: const Color(0xFFDBEAFE),
                title:
                    'Nouveaux tarifs applicables pour les copies littérales dès lundi.',
                commune: 'Dakar Plateau',
                time: 'Hier',
                icon: Icons.info_outline_rounded,
              ),
              _buildNewsItem(
                tag: 'Événement',
                tagColor: const Color(0xFF059669),
                tagBg: const Color(0xFFD1FAE5),
                title: "Journée de sensibilisation à l'état civil le 15 Juin.",
                commune: 'Dakar (Toutes)',
                time: '15 Juin',
                icon: Icons.event_available_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Recherche de démarche (barre de recherche de l'accueil) ──────────────
/// Ouvre une feuille de recherche : on tape une démarche (naissance, mariage,
/// décès, résidence…) et on lance la demande correspondante.
void _showDemarcheSearch(BuildContext context) async {
  final route = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DemarcheSearchSheet(),
  );
  if (route != null && context.mounted) context.push(route);
}

class _DemarcheSearchSheet extends StatefulWidget {
  const _DemarcheSearchSheet();
  @override
  State<_DemarcheSearchSheet> createState() => _DemarcheSearchSheetState();
}

class _DemarcheSearchSheetState extends State<_DemarcheSearchSheet> {
  final _ctrl = TextEditingController();
  String _q = '';

  // Démarches disponibles (mêmes routes que les cartes de l'accueil).
  // Les démarches « Bientôt disponible » sont volontairement exclues : elles
  // ne doivent pas apparaître du tout dans la recherche.
  static const List<Map<String, dynamic>> _all = [
    {'title': 'Extrait de naissance', 'icon': Icons.file_copy_rounded, 'route': AppRoutes.naissanceBeneficiary},
    {'title': 'Certificat de mariage', 'icon': Icons.favorite_border_rounded, 'route': AppRoutes.mariageForm},
    {'title': 'Certificat de décès', 'icon': Icons.assignment_rounded, 'route': AppRoutes.decesForm},
    {'title': 'Certificat de résidence', 'icon': Icons.home_outlined, 'route': AppRoutes.residenceForm},
    {'title': 'Demande de régularisation (foncier)', 'icon': Icons.assignment_outlined, 'route': AppRoutes.foncierRegularisation},
    {'title': 'Autorisation de construire', 'icon': Icons.architecture_outlined, 'route': AppRoutes.foncierAutorisation},
    {'title': 'Mutation de parcelle', 'icon': Icons.swap_horiz_rounded, 'route': AppRoutes.foncierMutation},
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final results = q.isEmpty
        ? _all
        : _all
            .where((d) => (d['title'] as String).toLowerCase().contains(q))
            .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: (v) => setState(() => _q = v.trim()),
              decoration: InputDecoration(
                hintText: 'Rechercher une démarche (naissance, mariage…)',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3B82F6)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text('Aucune démarche trouvée',
                    style: TextStyle(color: Color(0xFF94A3B8))),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: results.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (_, i) {
                    final d = results[i];
                    final route = d['route'] as String;
                    return ListTile(
                      leading: Icon(d['icon'] as IconData,
                          color: const Color(0xFF0B285D)),
                      title: Text(d['title'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1E293B))),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8)),
                      onTap: () => Navigator.of(context).pop(route),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

