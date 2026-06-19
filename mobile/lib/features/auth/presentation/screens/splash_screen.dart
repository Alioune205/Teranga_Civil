import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

/// Écran blanc invisible — vérifie le token local et navigue immédiatement.
/// Aucun appel réseau au démarrage.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.microtask(() {});
    if (!mounted) return;
    try {
      final token = await ref.read(authRepositoryProvider).getToken();
      if (!mounted) return;
      if (token != null && token.isNotEmpty) {
        context.go(AppRoutes.home);
        return;
      }
    } catch (_) {}
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Colors.white);
  }
}
