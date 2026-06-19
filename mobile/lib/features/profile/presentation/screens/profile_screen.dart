import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/region_commune_select.dart';
import '../../../../shared/models/commune_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';

/// S14 — Profil utilisateur
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final initials = user != null
        ? AppFormatters.initials(user.nomComplet)
        : '?';
    final nom = user != null ? user.nomComplet : '—';
    final phone = user != null
        ? AppFormatters.phoneNumber(user.phone ?? '')
        : '—';
    final commune = user?.communeNom ?? 'Non renseignée';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── En-tête pleine largeur (monte jusqu'en haut de l'écran,
            //    derrière la status bar) + avatar à cheval ──
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    left: 24,
                    right: 24,
                    bottom: 34,
                  ),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Mon Profil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: AppTextStyles.headlineLarge
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Column(
                children: [
                  Text(nom, style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Text(phone, style: AppTextStyles.bodySmall),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      commune,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Sections ────────────────────────────────────
              _SectionCard(
                children: [
                  _ProfileTile(
                    icon: Icons.person_outline,
                    label: 'Mes informations',
                    onTap: () => _showEditProfile(context, ref, nom),
                  ),
                  _ProfileTile(
                    icon: Icons.lock_outline,
                    label: 'Changer le mot de passe',
                    onTap: () => _showChangePassword(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Préférences ──────────────────────────────────
              Consumer(builder: (ctx, ref, _) {
                final lang = ref.watch(languageProvider);
                final notifs = ref.watch(notificationsProvider);
                return _SectionCard(
                  children: [
                    _ProfileTile(
                      icon: Icons.language_outlined,
                      label: 'Langue',
                      trailing: Text(
                        languageLabels[lang] ?? lang,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary),
                      ),
                      onTap: () => _showLanguagePicker(ctx, ref, lang),
                    ),
                    _ProfileTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      trailing: Switch(
                        value: notifs,
                        onChanged: (v) =>
                            ref.read(notificationsProvider.notifier).toggle(v),
                        activeThumbColor: AppColors.secondary,
                        activeTrackColor: AppColors.statusGreenLight,
                      ),
                      onTap: null,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  _ProfileTile(
                    icon: Icons.help_outline,
                    label: 'Aide & Support',
                    onTap: () {},
                  ),
                  _ProfileTile(
                    icon: Icons.info_outline,
                    label: 'À propos',
                    trailing: Text(
                      'v${AppConstants.appVersion}',
                      style: AppTextStyles.caption,
                    ),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Déconnexion ─────────────────────────────────
              _SectionCard(
                children: [
                  _ProfileTile(
                    icon: Icons.logout,
                    label: 'Déconnexion',
                    labelColor: AppColors.error,
                    iconColor: AppColors.error,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, String currentNom) {
    final user = ref.read(authProvider).user;
    final prenomCtr = TextEditingController(text: user?.prenom ?? '');
    final nomCtr    = TextEditingController(text: user?.nom ?? '');
    CommuneModel? commune;
    RegionModel? region;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── En-tête ──────────────────────────────
                Row(children: [
                  const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Mes informations', style: AppTextStyles.headlineSmall),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  'Modifiez vos informations personnelles (nom, prénom, région et commune).',
                  style: AppTextStyles.bodySmall,
                ),
                const Divider(height: 28),

                // ── Prénom ────────────────────────────────
                AppTextField(
                  label: 'Prénom',
                  controller: prenomCtr,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Le prénom est requis.' : null,
                ),
                const SizedBox(height: 12),

                // ── Nom ───────────────────────────────────
                AppTextField(
                  label: 'Nom de famille',
                  controller: nomCtr,
                  textInputAction: TextInputAction.next,
                  validator: Validators.fullName,
                ),
                const SizedBox(height: 12),

                // ── Téléphone (lecture seule) ─────────────
                AppTextField(
                  label: 'Téléphone',
                  hint: user?.phone ?? '',
                  controller: TextEditingController(
                      text: AppFormatters.phoneNumber(user?.phone ?? '')),
                  enabled: false,
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: AppColors.textHint, size: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Le numéro de téléphone ne peut pas être modifié.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                ),
                const SizedBox(height: 12),

                // ── Commune ───────────────────────────────
                Text('Commune de résidence', style: AppTextStyles.labelMedium),
                const SizedBox(height: 6),
                RegionCommuneSelect(
                  onChanged: (r, c) => setSheetState(() {
                    commune = c;
                    region = r;
                  }),
                  initialCommuneId: user?.communeId,
                ),
                const SizedBox(height: 24),

                // ── Bouton ────────────────────────────────
                Consumer(builder: (_, ref, __) {
                  final isLoading = ref.watch(profileProvider).isLoading;
                  return PrimaryButton(
                    label: 'Enregistrer les modifications',
                    isLoading: isLoading,
                    onPressed: () async {
                      if (nomCtr.text.trim().isEmpty) return;
                      try {
                        await ref.read(profileProvider.notifier).updateProfile(
                              prenom: prenomCtr.text.trim(),
                              nom: nomCtr.text.trim(),
                              communeId: commune?.id ?? user?.communeId,
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Informations mises à jour.'),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColors.error));
                        }
                      }
                    },
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final oldCtr     = TextEditingController();
    final newCtr     = TextEditingController();
    final confirmCtr = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Changer le mot de passe',
                    style: AppTextStyles.headlineSmall),
              ),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textSecondary),
              ),
            ]),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Mot de passe actuel',
              hint: '••••••••',
              controller: oldCtr,
              obscureText: true,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppColors.textSecondary, size: 18),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Nouveau mot de passe',
              hint: '••••••••',
              controller: newCtr,
              obscureText: true,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppColors.textSecondary, size: 18),
              validator: (v) {
                if (v == null || v.length < 6) {
                  return 'Minimum 6 caractères.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Confirmer le nouveau mot de passe',
              hint: '••••••••',
              controller: confirmCtr,
              obscureText: true,
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppColors.textSecondary, size: 18),
            ),
            const SizedBox(height: 20),
            Consumer(builder: (_, ref, __) {
              final isLoading = ref.watch(profileProvider).isLoading;
              return PrimaryButton(
                label: 'Confirmer',
                isLoading: isLoading,
                onPressed: () async {
                  if (newCtr.text != confirmCtr.text) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content:
                            Text('Les mots de passe ne correspondent pas.')));
                    return;
                  }
                  if (newCtr.text.length < 6) return;
                  try {
                    await ref.read(profileProvider.notifier).changePin(
                          oldPin: oldCtr.text,
                          newPin: newCtr.text,
                        );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Mot de passe modifié avec succès.'),
                        backgroundColor: AppColors.secondary,
                      ));
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppColors.error));
                    }
                  }
                },
              );
            }),
          ],
        ),
        ),
      ),
    );
  }

  void _showLanguagePicker(
      BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child:
                    Text('Choisir la langue', style: AppTextStyles.headlineSmall),
              ),
              ...languageLabels.entries.map((e) => RadioListTile<String>(
                    value: e.key,
                    groupValue: current,
                    activeColor: AppColors.primary,
                    title: Text(e.value, style: AppTextStyles.bodyMedium),
                    onChanged: (v) async {
                      if (v != null) {
                        await ref.read(languageProvider.notifier).setLanguage(v);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Déconnexion', style: AppTextStyles.headlineSmall),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: AppTextStyles.linkPrimary),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(profileProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: Text('Déconnexion',
                style: AppTextStyles.link.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast) const Divider(height: 1, indent: 52),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _ProfileTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: iconColor ?? AppColors.textSecondary, size: 22),
      title: Text(label,
          style: AppTextStyles.bodyMedium.copyWith(color: labelColor)),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.textHint)
              : null),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
