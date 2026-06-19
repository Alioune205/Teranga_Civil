#!/bin/bash
# ============================================================
# TERANGA CIVIL — Étape 3 : Shared Widgets & Layout
# Usage : bash setup_etape3.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🚀 TERANGA CIVIL — Installation Étape 3 : Shared Widgets & Layout"
echo ""

# ── commune_model.dart ──────────────────────────────────────
cat > lib/shared/models/commune_model.dart << 'DART'
/// Modèles de données pour le select cascadé Région → Département → Commune.
/// Chargés depuis assets/data/senegal_communes.json

class CommuneModel {
  final String id;
  final String nom;

  const CommuneModel({required this.id, required this.nom});

  factory CommuneModel.fromJson(Map<String, dynamic> json) =>
      CommuneModel(id: json['id'] as String, nom: json['nom'] as String);

  @override
  String toString() => nom;
}

class DepartementModel {
  final String id;
  final String nom;
  final List<CommuneModel> communes;

  const DepartementModel({
    required this.id,
    required this.nom,
    required this.communes,
  });

  factory DepartementModel.fromJson(Map<String, dynamic> json) =>
      DepartementModel(
        id: json['id'] as String,
        nom: json['nom'] as String,
        communes: (json['communes'] as List)
            .map((c) => CommuneModel.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

class RegionModel {
  final String id;
  final String nom;
  final List<DepartementModel> departements;

  const RegionModel({
    required this.id,
    required this.nom,
    required this.departements,
  });

  factory RegionModel.fromJson(Map<String, dynamic> json) => RegionModel(
        id: json['id'] as String,
        nom: json['nom'] as String,
        departements: (json['departements'] as List)
            .map((d) => DepartementModel.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}
DART
echo "  ✅ commune_model.dart"

# ── primary_button.dart ─────────────────────────────────────
cat > lib/shared/widgets/primary_button.dart << 'DART'
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Bouton principal TERANGA CIVIL.
/// - Actif  : fond #1B2A6B, texte blanc, radius 12, hauteur 52px
/// - Désactivé : fond #D1D5DB, texte #9CA3AF
/// - Loading : CircularProgressIndicator mint green à la place du label
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final IconData? leadingIcon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.leadingIcon,
  });

  bool get _active => isEnabled && !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _active ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _active ? AppColors.primary : AppColors.buttonDisabledBg,
          foregroundColor: _active ? AppColors.textOnPrimary : AppColors.buttonDisabledText,
          disabledBackgroundColor: AppColors.buttonDisabledBg,
          disabledForegroundColor: AppColors.buttonDisabledText,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: AppTextStyles.buttonPrimary),
                ],
              ),
      ),
    );
  }
}

/// Bouton secondaire (outlined) — même logique de states
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? leadingIcon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.leadingIcon,
  });

  bool get _active => isEnabled && !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _active ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: _active ? AppColors.primary : AppColors.buttonDisabledText,
          side: BorderSide(
            color: _active ? AppColors.primary : AppColors.buttonDisabledBg,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.buttonPrimary.copyWith(
                      color: _active ? AppColors.primary : AppColors.buttonDisabledText,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Bouton texte simple (lien) — pour "Mot de passe oublié ?", "S'inscrire", etc.
class LinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const LinkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColors.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: AppTextStyles.link.copyWith(color: color ?? AppColors.secondary),
      ),
    );
  }
}
DART
echo "  ✅ primary_button.dart"

# ── app_text_field.dart ─────────────────────────────────────
cat > lib/shared/widgets/app_text_field.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Champ texte standard TERANGA CIVIL.
/// Gère : label flottant, validation inline (rouge sous le champ),
/// icône prefix/suffix, masquage mot de passe, inputFormatters.
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLength;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final String? initialValue;
  final AutovalidateMode autovalidateMode;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLength = null,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.initialValue,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _obscure,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      maxLength: widget.maxLength,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      inputFormatters: widget.inputFormatters,
      style: AppTextStyles.inputText,
      autovalidateMode: widget.autovalidateMode,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        counterText: '',
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffixIcon,
      ),
    );
  }
}

/// Champ téléphone sénégalais avec préfixe +221 fixe
class PhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;

  const PhoneTextField({
    super.key,
    this.controller,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Numéro de téléphone',
      hint: '77 123 45 67',
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      textInputAction: textInputAction,
      focusNode: focusNode,
      keyboardType: TextInputType.phone,
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Text(
          '+221',
          style: AppTextStyles.inputText.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
    );
  }
}

/// Champ date (readOnly — ouvre un date picker au tap)
class DateTextField extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelected;
  final String? Function(String?)? validator;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateTextField({
    super.key,
    required this.label,
    required this.onDateSelected,
    this.selectedDate,
    this.validator,
    this.firstDate,
    this.lastDate,
  });

  String get _displayValue {
    if (selectedDate == null) return '';
    final d = selectedDate!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: 'JJ/MM/AAAA',
      readOnly: true,
      controller: TextEditingController(text: _displayValue),
      validator: validator,
      suffixIcon: const Icon(Icons.calendar_today_outlined,
          color: AppColors.textSecondary, size: 20),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(1900),
          lastDate: lastDate ?? DateTime.now(),
          locale: const Locale('fr', 'FR'),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: AppColors.textOnPrimary,
                surface: AppColors.surface,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onDateSelected(picked);
      },
    );
  }
}
DART
echo "  ✅ app_text_field.dart"

# ── otp_input.dart ──────────────────────────────────────────
cat > lib/shared/widgets/otp_input.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Widget OTP 6 cases — utilisé sur S02B, S05
class OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final void Function(String)? onCompleted;
  final bool hasError;

  const OtpInput({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onCompleted,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return PinCodeTextField(
      appContext: context,
      length: 6,
      controller: controller,
      keyboardType: TextInputType.number,
      animationType: AnimationType.fade,
      autoFocus: true,
      enableActiveFill: true,
      obscureText: false,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(10),
        fieldHeight: 52,
        fieldWidth: 46,
        // État normal
        inactiveColor: AppColors.border,
        inactiveFillColor: AppColors.surface,
        // Focus
        selectedColor: AppColors.primary,
        selectedFillColor: AppColors.surface,
        // Rempli
        activeColor: hasError ? AppColors.error : AppColors.secondary,
        activeFillColor: hasError ? AppColors.errorLight : AppColors.successLight,
        // Erreur globale
        errorBorderColor: AppColors.error,
      ),
      textStyle: AppTextStyles.otpDigit,
      cursorColor: AppColors.primary,
      onChanged: onChanged,
      onCompleted: onCompleted,
      // Pas de message d'erreur intégré — géré par le parent
      errorAnimationController: null,
    );
  }
}

/// Ligne "Renvoyer le code" avec countdown 60s
class OtpResendRow extends StatefulWidget {
  final VoidCallback onResend;
  final int cooldownSeconds;

  const OtpResendRow({
    super.key,
    required this.onResend,
    this.cooldownSeconds = 60,
  });

  @override
  State<OtpResendRow> createState() => _OtpResendRowState();
}

class _OtpResendRowState extends State<OtpResendRow> {
  late int _remaining;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.cooldownSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          _remaining = 0;
          _canResend = true;
        }
      });
      return _remaining > 0;
    });
  }

  void _handleResend() {
    setState(() {
      _remaining = widget.cooldownSeconds;
      _canResend = false;
    });
    _startCountdown();
    widget.onResend();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Vous n\'avez pas reçu le code ? ',
          style: AppTextStyles.bodySmall,
        ),
        if (_canResend)
          GestureDetector(
            onTap: _handleResend,
            child: Text(
              'Renvoyer',
              style: AppTextStyles.link,
            ),
          )
        else
          Text(
            'Renvoyer (${_remaining}s)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
      ],
    );
  }
}
DART
echo "  ✅ otp_input.dart"

# ── cascaded_commune_select.dart ────────────────────────────
cat > lib/shared/widgets/cascaded_commune_select.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/assets_constants.dart';
import '../models/commune_model.dart';

/// Select cascadé Région → Département → Commune.
/// Charge les données depuis assets/data/senegal_communes.json
/// Chaque niveau se déverrouille quand le précédent est sélectionné.
class CascadedCommuneSelect extends StatefulWidget {
  final void Function(RegionModel?, DepartementModel?, CommuneModel?) onChanged;
  final RegionModel? initialRegion;
  final DepartementModel? initialDepartement;
  final CommuneModel? initialCommune;
  final bool showLabels;

  const CascadedCommuneSelect({
    super.key,
    required this.onChanged,
    this.initialRegion,
    this.initialDepartement,
    this.initialCommune,
    this.showLabels = true,
  });

  @override
  State<CascadedCommuneSelect> createState() => _CascadedCommuneSelectState();
}

class _CascadedCommuneSelectState extends State<CascadedCommuneSelect> {
  List<RegionModel> _regions = [];
  bool _loading = true;

  RegionModel? _selectedRegion;
  DepartementModel? _selectedDepartement;
  CommuneModel? _selectedCommune;

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialRegion;
    _selectedDepartement = widget.initialDepartement;
    _selectedCommune = widget.initialCommune;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final jsonStr = await rootBundle.loadString(Assets.senegalCommunes);
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final regions = (data['regions'] as List)
          .map((r) => RegionModel.fromJson(r as Map<String, dynamic>))
          .toList();
      setState(() {
        _regions = regions;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _onRegionChanged(RegionModel? region) {
    setState(() {
      _selectedRegion = region;
      _selectedDepartement = null;
      _selectedCommune = null;
    });
    widget.onChanged(region, null, null);
  }

  void _onDepartementChanged(DepartementModel? dept) {
    setState(() {
      _selectedDepartement = dept;
      _selectedCommune = null;
    });
    widget.onChanged(_selectedRegion, dept, null);
  }

  void _onCommuneChanged(CommuneModel? commune) {
    setState(() => _selectedCommune = commune);
    widget.onChanged(_selectedRegion, _selectedDepartement, commune);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Région ──────────────────────────────────────────
        _SelectDropdown<RegionModel>(
          label: 'Région',
          hint: 'Sélectionner une région',
          value: _selectedRegion,
          items: _regions,
          itemLabel: (r) => r.nom,
          onChanged: _onRegionChanged,
          enabled: true,
        ),
        const SizedBox(height: 12),

        // ── Département ─────────────────────────────────────
        _SelectDropdown<DepartementModel>(
          label: 'Département',
          hint: _selectedRegion == null
              ? 'Choisissez d\'abord une région'
              : 'Sélectionner un département',
          value: _selectedDepartement,
          items: _selectedRegion?.departements ?? [],
          itemLabel: (d) => d.nom,
          onChanged: _onDepartementChanged,
          enabled: _selectedRegion != null,
        ),
        const SizedBox(height: 12),

        // ── Commune ─────────────────────────────────────────
        _SelectDropdown<CommuneModel>(
          label: 'Commune',
          hint: _selectedDepartement == null
              ? 'Choisissez d\'abord un département'
              : 'Sélectionner une commune',
          value: _selectedCommune,
          items: _selectedDepartement?.communes ?? [],
          itemLabel: (c) => c.nom,
          onChanged: _onCommuneChanged,
          enabled: _selectedDepartement != null,
        ),
      ],
    );
  }
}

class _SelectDropdown<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final bool enabled;

  const _SelectDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.inputLabel),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: AppTextStyles.inputHint),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: enabled ? AppColors.textSecondary : AppColors.buttonDisabledText,
          ),
          style: AppTextStyles.inputText,
          dropdownColor: AppColors.surface,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
          ),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabel(item),
                      style: AppTextStyles.inputText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
DART
echo "  ✅ cascaded_commune_select.dart"

# ── status_badge.dart ───────────────────────────────────────
cat > lib/shared/widgets/status_badge.dart << 'DART'
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';

/// Badge de statut coloré pour les dossiers.
/// Statuts : soumis | en_verification | valide | pret | rejete | en_cours
class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  _BadgeConfig get _config {
    switch (status) {
      case 'soumis':
        return _BadgeConfig(
          color: AppColors.statusBlue,
          bgColor: AppColors.statusBlueLight,
          icon: Icons.upload_outlined,
        );
      case 'en_verification':
        return _BadgeConfig(
          color: AppColors.statusAmber,
          bgColor: AppColors.statusAmberLight,
          icon: Icons.search_outlined,
        );
      case 'valide':
        return _BadgeConfig(
          color: AppColors.statusGreen,
          bgColor: AppColors.statusGreenLight,
          icon: Icons.check_circle_outline,
        );
      case 'pret':
        return _BadgeConfig(
          color: AppColors.statusGreen,
          bgColor: AppColors.statusGreenLight,
          icon: Icons.download_outlined,
        );
      case 'rejete':
        return _BadgeConfig(
          color: AppColors.statusRed,
          bgColor: AppColors.statusRedLight,
          icon: Icons.cancel_outlined,
        );
      case 'en_cours':
      default:
        return _BadgeConfig(
          color: AppColors.statusAmber,
          bgColor: AppColors.statusAmberLight,
          icon: Icons.hourglass_empty_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: cfg.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, size: compact ? 12 : 14, color: cfg.color),
          const SizedBox(width: 4),
          Text(
            AppFormatters.statusLabel(status),
            style: AppTextStyles.badgeText.copyWith(color: cfg.color),
          ),
        ],
      ),
    );
  }
}

/// Stepper horizontal de progression du dossier
class DossierProgressStepper extends StatelessWidget {
  final String currentStatus;

  const DossierProgressStepper({super.key, required this.currentStatus});

  static const _steps = ['soumis', 'en_verification', 'valide', 'pret'];

  int get _currentIndex {
    final idx = _steps.indexOf(currentStatus);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Ligne de connexion
          final stepIdx = i ~/ 2;
          final active = stepIdx < _currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: active ? AppColors.secondary : AppColors.border,
            ),
          );
        }
        // Point de step
        final stepIdx = i ~/ 2;
        final done = stepIdx < _currentIndex;
        final current = stepIdx == _currentIndex;
        return _StepDot(
          done: done,
          current: current,
          label: AppFormatters.statusLabel(_steps[stepIdx]),
        );
      }),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool done;
  final bool current;
  final String label;

  const _StepDot({required this.done, required this.current, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = done || current ? AppColors.secondary : AppColors.border;
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.secondary : AppColors.surface,
            border: Border.all(color: color, width: 2),
          ),
          child: done
              ? const Icon(Icons.check, size: 10, color: AppColors.textOnPrimary)
              : current
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary,
                        ),
                      ),
                    )
                  : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: done || current ? AppColors.secondary : AppColors.textHint,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _BadgeConfig {
  final Color color;
  final Color bgColor;
  final IconData icon;
  const _BadgeConfig({required this.color, required this.bgColor, required this.icon});
}
DART
echo "  ✅ status_badge.dart"

# ── recap_card.dart ─────────────────────────────────────────
cat > lib/shared/widgets/recap_card.dart << 'DART'
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Card de récapitulatif — utilisée sur S08A, S08C, S09A, S10A.
/// Affiche une liste de paires label/valeur dans un container card.
class RecapCard extends StatelessWidget {
  final String? title;
  final List<RecapField> fields;
  final Widget? trailing;
  final Color? borderColor;

  const RecapCard({
    super.key,
    this.title,
    required this.fields,
    this.trailing,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(title!, style: AppTextStyles.labelLarge),
            ),
            const Divider(height: 20),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                ...fields.asMap().entries.map((entry) {
                  final isLast = entry.key == fields.length - 1;
                  return Column(
                    children: [
                      _RecapRow(field: entry.value),
                      if (!isLast)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
          if (trailing != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final RecapField field;
  const _RecapRow({required this.field});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (field.icon != null) ...[
          Icon(field.icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: 4,
          child: Text(field.label, style: AppTextStyles.labelMedium),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            field.value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: field.valueColor ?? AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

/// Modèle d'un champ du récapitulatif
class RecapField {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  const RecapField({
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });
}

/// Bannière d'information (note en bas des récaps)
class InfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.statusBlue;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusBlueLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppTextStyles.caption.copyWith(color: c)),
          ),
        ],
      ),
    );
  }
}
DART
echo "  ✅ recap_card.dart"

# ── skeleton_loader.dart ────────────────────────────────────
cat > lib/shared/widgets/skeleton_loader.dart << 'DART'
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
DART
echo "  ✅ skeleton_loader.dart"

# ── document_scanner.dart ───────────────────────────────────
cat > lib/shared/widgets/document_scanner.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Widget de sélection de document (scan CNI ou certificat).
/// Propose : Caméra ou Galerie. Retourne le chemin du fichier sélectionné.
class DocumentScannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  const DocumentScannerCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            else
              const Icon(Icons.arrow_forward_ios, color: AppColors.textHint, size: 14),
          ],
        ),
      ),
    );
  }
}

/// Utilitaire pour ouvrir la caméra ou la galerie
class ImagePickerHelper {
  static final _picker = ImagePicker();

  static Future<String?> fromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
    );
    return file?.path;
  }

  static Future<String?> fromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    return file?.path;
  }

  /// Affiche un bottom sheet pour choisir la source
  static Future<String?> showSourcePicker(BuildContext context) async {
    return showModalBottomSheet<String?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choisir une source', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: Text('Prendre une photo', style: AppTextStyles.bodyLarge),
                onTap: () async {
                  Navigator.pop(ctx);
                  Navigator.pop(ctx, await fromCamera());
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text('Choisir depuis la galerie', style: AppTextStyles.bodyLarge),
                onTap: () async {
                  Navigator.pop(ctx);
                  Navigator.pop(ctx, await fromGallery());
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DART
echo "  ✅ document_scanner.dart"

# ── main_scaffold.dart ──────────────────────────────────────
cat > lib/shared/layout/main_scaffold.dart << 'DART'
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Scaffold principal avec BottomNavigationBar (3 onglets) et FAB micro centré.
/// Utilisé comme shell par GoRouter à partir de l'Étape 4.
class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  static const _tabs = [
    _NavTab(label: 'Accueil',  icon: Icons.home_outlined,    activeIcon: Icons.home,         route: '/home'),
    _NavTab(label: 'Dossiers', icon: Icons.folder_outlined,  activeIcon: Icons.folder,       route: '/dossiers'),
    _NavTab(label: 'Profil',   icon: Icons.person_outlined,  activeIcon: Icons.person,       route: '/profile'),
  ];

  void _onTabTapped(BuildContext context, int index) {
    if (index == currentIndex) return;
    context.go(_tabs[index].route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: _AssistantFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _TerangaBottomNav(
        currentIndex: currentIndex,
        onTap: (i) => _onTabTapped(context, i),
      ),
    );
  }
}

class _TerangaBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _TerangaBottomNav({required this.currentIndex, required this.onTap});

  // Les tabs "réels" : on en affiche 2 à gauche du FAB et 1 à droite
  static const _leftTabs = [0, 1]; // Accueil, Dossiers
  static const _rightTabs = [2];   // Profil

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.surface,
      elevation: 8,
      notchMargin: 8,
      shape: const CircularNotchThapShape(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Gauche : Accueil + Dossiers
            ..._leftTabs.map((i) => _NavItem(
                  tab: MainScaffold._tabs[i],
                  isActive: i == currentIndex,
                  onTap: () => onTap(i),
                )),
            // Espace central pour le FAB
            const SizedBox(width: 64),
            // Droite : Profil
            ..._rightTabs.map((i) => _NavItem(
                  tab: MainScaffold._tabs[i],
                  isActive: i == currentIndex,
                  onTap: () => onTap(i),
                )),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.tab, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? tab.activeIcon : tab.icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: AppTextStyles.navLabel.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// FAB micro assistant IA — centré au-dessus de la bottom nav
class _AssistantFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // TODO Étape 8 : ouvrir AssistantSheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _AssistantPlaceholder(),
        );
      },
      backgroundColor: AppColors.secondary,
      elevation: 4,
      tooltip: 'Assistant IA',
      child: const Icon(Icons.mic, color: AppColors.textOnPrimary, size: 26),
    );
  }
}

class _AssistantPlaceholder extends StatelessWidget {
  const _AssistantPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, color: AppColors.secondary, size: 40),
            const SizedBox(height: 12),
            Text('Assistant TERANGA CIVIL', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 4),
            Text('Disponible à l\'Étape 8', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _NavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

// BottomAppBar notch shape personnalisée pour le FAB centré
class CircularNotchThapShape extends NotchedShape {
  const CircularNotchThapShape();

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null || !host.overlaps(guest)) return Path()..addRect(host);
    const notchRadius = 32.0;
    final s1 = notchRadius * 1.0;
    final s2 = notchRadius * 1.0;
    final r = notchRadius;
    final a = -1.0 * r - s2;
    final b = host.top - guest.center.dy;
    final n2 = math.sqrt(b * b * r * r * (a * a + b * b - r * r));
    final p2xA = ((a * r * r) - n2) / (a * a + b * b);
    final p2xB = ((a * r * r) + n2) / (a * a + b * b);
    final p2yA = math.sqrt(r * r - p2xA * p2xA);
    final p2yB = math.sqrt(r * r - p2xB * p2xB);
    final p = [
      Offset(guest.center.dx + p2xA, host.top - p2yA),
      Offset(guest.center.dx + p2xB, host.top - p2yB),
    ];
    final leftPoint = p[0].dx < p[1].dx ? p[0] : p[1];
    final rightPoint = p[0].dx < p[1].dx ? p[1] : p[0];
    return Path()
      ..moveTo(host.left, host.top)
      ..lineTo(leftPoint.dx - s1, host.top)
      ..quadraticBezierTo(leftPoint.dx, host.top, leftPoint.dx, leftPoint.dy)
      ..arcToPoint(rightPoint, radius: Radius.circular(r), clockwise: false)
      ..quadraticBezierTo(rightPoint.dx, host.top, rightPoint.dx + s1, host.top)
      ..lineTo(host.right, host.top)
      ..lineTo(host.right, host.bottom)
      ..lineTo(host.left, host.bottom)
      ..close();
  }
}

DART
echo "  ✅ main_scaffold.dart"

echo ""
echo "✅ Étape 3 terminée — 9 fichiers créés"
echo ""
echo "Fichiers générés :"
echo "  lib/shared/models/commune_model.dart"
echo "  lib/shared/widgets/primary_button.dart"
echo "  lib/shared/widgets/app_text_field.dart"
echo "  lib/shared/widgets/otp_input.dart"
echo "  lib/shared/widgets/cascaded_commune_select.dart"
echo "  lib/shared/widgets/status_badge.dart"
echo "  lib/shared/widgets/recap_card.dart"
echo "  lib/shared/widgets/skeleton_loader.dart"
echo "  lib/shared/widgets/document_scanner.dart"
echo "  lib/shared/layout/main_scaffold.dart"
