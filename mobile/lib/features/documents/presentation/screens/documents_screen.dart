import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../dossiers/presentation/providers/dossiers_provider.dart';
import '../../../dossiers/data/models/dossier_model.dart';

/// Une démarche. [route] null => formulaire pas encore disponible (« Bientôt »).
class _Demarche {
  final String title;
  final IconData icon;
  final String? route;
  const _Demarche(this.title, this.icon, {this.route});
}

class _Famille {
  final String name;
  final IconData icon;
  final Color color;
  final String desc;
  final List<_Demarche> items;
  const _Famille({
    required this.name,
    required this.icon,
    required this.color,
    required this.desc,
    required this.items,
  });
}

/// Écran « Documents » : toutes les démarches classées par famille + démarches
/// fréquentes du citoyen.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  static const _familles = <_Famille>[
    _Famille(
      name: 'Naissance',
      icon: Icons.child_care_rounded,
      color: Color(0xFF2563EB),
      desc: 'Naissance, identité',
      items: [
        _Demarche('Acte de naissance', Icons.edit_document),
        _Demarche('Extrait de naissance', Icons.file_copy_rounded,
            route: AppRoutes.naissanceBeneficiary),
        _Demarche('Copie littérale', Icons.file_present_rounded),
        _Demarche('Certificat de non-inscription', Icons.search_off_rounded),
      ],
    ),
    _Famille(
      name: 'Mariage & famille',
      icon: Icons.favorite_rounded,
      color: Color(0xFFDC2626),
      desc: 'Mariage, célibat, famille',
      items: [
        _Demarche('Certificat de mariage', Icons.favorite_border_rounded,
            route: AppRoutes.mariageForm),
        _Demarche('Certificat de célibat', Icons.person_outline_rounded),
        _Demarche('Certificat de non-divorce', Icons.link_rounded),
        _Demarche('Certificat de veuvage', Icons.volunteer_activism_rounded),
      ],
    ),
    _Famille(
      name: 'Décès',
      icon: Icons.local_florist_rounded,
      color: Color(0xFF475569),
      desc: 'Certificats et permis',
      items: [
        _Demarche('Certificat de décès', Icons.assignment_rounded,
            route: AppRoutes.decesForm),
        _Demarche("Permis d'inhumer", Icons.health_and_safety_rounded),
        _Demarche('Certificat de non-inscription', Icons.search_off_rounded),
      ],
    ),
    _Famille(
      name: 'Logement & Foncier',
      icon: Icons.home_work_rounded,
      color: Color(0xFFC026D3),
      desc: 'Résidence, terrain, permis',
      items: [
        _Demarche('Certificat de résidence', Icons.home_outlined,
            route: AppRoutes.residenceForm),
        _Demarche('Régularisation foncière', Icons.real_estate_agent_rounded,
            route: AppRoutes.foncierRegularisation),
        _Demarche('Autorisation de construire', Icons.architecture_rounded,
            route: AppRoutes.foncierAutorisation),
        _Demarche('Mutation de parcelle', Icons.swap_horiz_rounded,
            route: AppRoutes.foncierMutation),
        _Demarche("Permis d'occuper", Icons.vpn_key_outlined),
      ],
    ),
    _Famille(
      name: 'Moralité & papier',
      icon: Icons.verified_user_rounded,
      color: Color(0xFF059669),
      desc: 'Moralité, légalisation',
      items: [
        _Demarche('Certificat de bonne vie et mœurs', Icons.shield_outlined),
        _Demarche("Certificat d'indigence", Icons.handshake_outlined),
        _Demarche('Légalisation de documents', Icons.approval_rounded),
        _Demarche("Certificat de vie et d'entretien",
            Icons.family_restroom_rounded),
      ],
    ),
  ];

  static _Demarche? _demarcheForType(String type) {
    switch (type.toLowerCase()) {
      case 'naissance':
        return const _Demarche('Acte de naissance', Icons.child_care_rounded,
            route: AppRoutes.naissanceBeneficiary);
      case 'mariage':
        return const _Demarche(
            'Certificat de mariage', Icons.favorite_border_rounded,
            route: AppRoutes.mariageForm);
      case 'deces':
        return const _Demarche(
            'Certificat de décès', Icons.local_florist_rounded,
            route: AppRoutes.decesForm);
      case 'residence':
        return const _Demarche('Certificat de résidence', Icons.home_outlined,
            route: AppRoutes.residenceForm);
      default:
        return null;
    }
  }

  static List<_Demarche> _mostRequested(List<DossierModel> dossiers) {
    final counts = <String, int>{};
    for (final d in dossiers) {
      counts[d.type] = (counts[d.type] ?? 0) + 1;
    }
    final types = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final res = <_Demarche>[];
    for (final t in types) {
      final dem = _demarcheForType(t);
      if (dem != null) res.add(dem);
    }
    return res;
  }

  void _openFamille(BuildContext context, _Famille f) {
    context.push(AppRoutes.categoryDemarches, extra: {
      'category': f.name,
      'items': f.items
          .map((item) => {
                'title': item.title,
                'icon': item.icon,
                'route': item.route,
              })
          .toList(),
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mostRequested = ref.watch(dossiersListProvider).maybeWhen(
          data: (list) => _mostRequested(list),
          orElse: () => const <_Demarche>[],
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête bleu ──────────────────────────────────────
            Container(
              width: double.infinity,
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
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              child: const Text(
                'Documents',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // ── Vos démarches fréquentes (historique du citoyen) ──
            if (mostRequested.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Vos démarches fréquentes',
                    style: AppTextStyles.headlineSmall),
              ),
              ...mostRequested.map(
                (d) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _MostRequestedCard(item: d),
                ),
              ),
            ],

            // ── Catégories (familles) ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text('Catégories', style: AppTextStyles.headlineSmall),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.98,
              ),
              itemCount: _familles.length,
              itemBuilder: (context, index) {
                final f = _familles[index];
                return GestureDetector(
                  onTap: () => _openFamille(context, f),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: f.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(f.icon, color: f.color, size: 26),
                        ),
                        const SizedBox(height: 12),
                        Text(f.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge),
                        const SizedBox(height: 4),
                        Text(f.desc,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MostRequestedCard extends StatelessWidget {
  final _Demarche item;
  const _MostRequestedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(item.title, style: AppTextStyles.labelLarge),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: item.route == null
                ? null
                : () => context.push(item.route!),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Text(
                'Demander',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
