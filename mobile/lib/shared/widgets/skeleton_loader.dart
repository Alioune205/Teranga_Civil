import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Skeleton loader animé — utilisé pendant le chargement des listes.
/// Animation shimmer en boucle entre deux niveaux de gris.
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  /// Variante rectangle pleine largeur (ex: placeholder de titre)
  const SkeletonLoader.title({super.key})
      : width = double.infinity,
        height = 20,
        borderRadius = 6;

  /// Variante ligne de texte courte
  const SkeletonLoader.text({super.key})
      : width = 200,
        height = 14,
        borderRadius = 6;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton pour une card de dossier
class DossierCardSkeleton extends StatelessWidget {
  const DossierCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SkeletonLoader(width: 160, height: 16),
              SkeletonLoader(width: 80, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 10),
          const SkeletonLoader(width: 120, height: 12),
          const SizedBox(height: 14),
          const SkeletonLoader(height: 6, borderRadius: 3),
        ],
      ),
    );
  }
}

/// Skeleton pour une liste de dossiers
class DossierListSkeleton extends StatelessWidget {
  final int count;
  const DossierListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const DossierCardSkeleton(),
    );
  }
}
