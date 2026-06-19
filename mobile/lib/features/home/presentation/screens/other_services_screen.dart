import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Écran listant les services « Autre » (au-delà de naissance/mariage/décès),
/// présentés en cartes carrées comme sur l'accueil. Extensible : on ajoute
/// simplement de nouvelles entrées dans [_services].
class OtherServicesScreen extends StatelessWidget {
  const OtherServicesScreen({super.key});

  static const _services = [
    (
      Icons.home_work_outlined,
      Color(0xFF14B8A6),
      'Résidence',
      'Validité 3 mois',
      AppRoutes.residenceForm,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Autres services'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 18,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: _services.length,
          itemBuilder: (_, i) {
            final (icon, color, title, subtitle, route) = _services[i];
            return GestureDetector(
              onTap: () => context.push(route),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: color.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: Icon(icon, color: color, size: 30),
                  ),
                  const SizedBox(height: 8),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
