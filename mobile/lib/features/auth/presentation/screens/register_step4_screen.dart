import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

final _secureStorageProvider =
    Provider<FlutterSecureStorage>((_) => const FlutterSecureStorage());

/// S06 — Inscription Étape 4/4 : Création code PIN
class RegisterStep4Screen extends ConsumerStatefulWidget {
  final Map<String, dynamic> registrationData;
  const RegisterStep4Screen({super.key, required this.registrationData});

  @override
  ConsumerState<RegisterStep4Screen> createState() =>
      _RegisterStep4ScreenState();
}

class _RegisterStep4ScreenState extends ConsumerState<RegisterStep4Screen> {
  final List<String> _pin = [];
  final List<String> _confirm = [];
  bool _confirming = false;
  String? _error;

  void _onKeyTap(String digit) {
    setState(() {
      _error = null;
      final current = _confirming ? _confirm : _pin;
      if (current.length < 6) current.add(digit);

      // Premier PIN complet → passer à la confirmation
      if (!_confirming && _pin.length == 6) {
        final err = Validators.pin(_pin.join());
        if (err != null) {
          _error = err;
          _pin.clear();
        } else {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) setState(() => _confirming = true);
          });
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = null;
      final current = _confirming ? _confirm : _pin;
      if (current.isNotEmpty) current.removeLast();
    });
  }

  Future<void> _submit() async {
    final pinStr = _pin.join();
    final confirmStr = _confirm.join();
    if (pinStr != confirmStr) {
      setState(() {
        _error = 'Les deux codes PIN ne correspondent pas.';
        _confirm.clear();
        _confirming = true;
      });
      return;
    }
    // Sauvegarder le PIN localement puis aller au dashboard
    final storage = ref.read(_secureStorageProvider);
    await storage.write(key: AppConstants.keyUserPin, value: pinStr);
    ref.read(registrationDataProvider.notifier).reset();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final displayPin = _confirming ? _confirm : _pin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Créer mon compte'),
        leading: _confirming
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => setState(() {
                  _confirming = false;
                  _confirm.clear();
                  _error = null;
                }),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => context.pop(),
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(step: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      _confirming
                          ? 'Confirmez votre code PIN'
                          : 'Choisissez votre code PIN',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _confirming
                          ? 'Ressaisissez le même code pour confirmer'
                          : 'Ce code vous servira à vous connecter à chaque session',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Points PIN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (i) => _PinDot(filled: i < displayPin.length)),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: AppTextStyles.inputError),
                    ],
                    const SizedBox(height: 32),
                    // Clavier numérique
                    _NumericKeypad(
                      onDigit: _onKeyTap,
                      onDelete: _onDelete,
                    ),
                    const Spacer(),
                    if (_confirming && _confirm.length == 6)
                      PrimaryButton(
                        label: 'Confirmer et accéder à mon compte',
                        onPressed: _submit,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinDot extends StatelessWidget {
  final bool filled;
  const _PinDot({required this.filled});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.primary : AppColors.transparent,
        border: Border.all(
          color: filled ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _NumericKeypad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: keys.map((row) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: row.map((key) {
          if (key.isEmpty) return const SizedBox(width: 80, height: 64);
          return _KeyButton(
            label: key,
            onTap: () => key == '⌫' ? onDelete() : onDigit(key),
            isDelete: key == '⌫',
          );
        }).toList(),
      )).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDelete;

  const _KeyButton({
    required this.label,
    required this.onTap,
    this.isDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 64,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: isDelete
              ? const Icon(Icons.backspace_outlined,
                  color: AppColors.textSecondary, size: 22)
              : Text(
                  label,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});
  @override
  Widget build(BuildContext context) => Container(
        height: 4,
        color: AppColors.border,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: step / 4,
          child: Container(color: AppColors.secondary),
        ),
      );
}
