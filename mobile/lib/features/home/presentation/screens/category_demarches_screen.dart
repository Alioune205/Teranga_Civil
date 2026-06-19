import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Page pleine écran listant les démarches d'une catégorie (Naissance,
/// Mariage & famille, Décès, Logement…). Les démarches disponibles sont
/// affichées en premier, les démarches « Bientôt disponible » en dessous,
/// grisées et désactivées.
class CategoryDemarchesScreen extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> items;

  const CategoryDemarchesScreen({
    super.key,
    required this.category,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]..sort((a, b) {
        final aAvailable = (a['route'] as String?) != null;
        final bAvailable = (b['route'] as String?) != null;
        if (aAvailable == bAvailable) return 0;
        return aAvailable ? -1 : 1;
      });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 24),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Démarches : $category',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = sorted[i];
                  final route = item['route'] as String?;
                  final available = route != null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () {
                        if (!available) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bientôt disponible'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        context.push(route);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item['icon'] as IconData,
                                  color: available
                                      ? const Color(0xFF3B82F6)
                                      : const Color(0xFF94A3B8),
                                  size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item['title'] as String,
                                style: TextStyle(
                                  color: available
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFF94A3B8),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (available)
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  color: Color(0xFFCBD5E1), size: 16)
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Bientôt',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: sorted.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
