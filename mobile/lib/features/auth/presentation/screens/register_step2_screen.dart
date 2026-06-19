// Écran supprimé — inscription simplifiée (voir register_step1_screen.dart)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterStep2Screen extends StatelessWidget {
  final Map<String, dynamic> registrationData;
  const RegisterStep2Screen({super.key, required this.registrationData});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
    return const SizedBox.shrink();
  }
}
