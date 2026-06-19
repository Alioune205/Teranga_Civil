import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/assets_constants.dart';
import '../models/commune_model.dart';

/// Select à 2 niveaux : Région → toutes les communes de cette région
/// (sans étape département)
class RegionCommuneSelect extends StatefulWidget {
  final void Function(RegionModel? region, CommuneModel? commune) onChanged;
  final String? errorText;

  /// IDs issus de l'OCR — le widget sélectionne automatiquement la région
  /// et la commune correspondantes dès que les données sont chargées.
  final String? initialRegionId;
  final String? initialCommuneId;

  const RegionCommuneSelect({
    super.key,
    required this.onChanged,
    this.errorText,
    this.initialRegionId,
    this.initialCommuneId,
  });

  @override
  State<RegionCommuneSelect> createState() => _RegionCommuneSelectState();
}

class _RegionCommuneSelectState extends State<RegionCommuneSelect> {
  List<RegionModel> _regions = [];
  bool _loading = true;

  RegionModel? _selectedRegion;
  CommuneModel? _selectedCommune;

  /// Toutes les communes de la région sélectionnée
  /// (fusion de tous les départements)
  List<CommuneModel> get _communes {
    if (_selectedRegion == null) return [];
    final all = <CommuneModel>[];
    for (final dept in _selectedRegion!.departements) {
      all.addAll(dept.communes);
    }
    // Trier par nom
    all.sort((a, b) => a.nom.compareTo(b.nom));
    return all;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final jsonStr =
          await rootBundle.loadString(Assets.senegalCommunes);
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final regions = (data['regions'] as List)
          .map((r) => RegionModel.fromJson(r as Map<String, dynamic>))
          .toList();
      setState(() {
        _regions = regions;
        _loading = false;
      });
      // Appliquer les valeurs initiales issues de l'OCR après le chargement
      _scheduleApplyInitial(widget.initialRegionId, widget.initialCommuneId);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  /// Sélectionne automatiquement la région et la commune par leurs IDs.
  /// Toujours appelée via [_scheduleApplyInitial] pour éviter setState()
  /// pendant la phase de build.
  void _applyInitial(String? regionId, String? communeId) {
    if (regionId == null || regionId.isEmpty) return;
    RegionModel? region;
    try {
      region = _regions.firstWhere((r) => r.id == regionId);
    } catch (_) {
      return;
    }
    CommuneModel? commune;
    if (communeId != null && communeId.isNotEmpty) {
      for (final dept in region.departements) {
        try {
          commune = dept.communes.firstWhere((c) => c.id == communeId);
          break;
        } catch (_) {}
      }
    }
    if (!mounted) return;
    setState(() {
      _selectedRegion = region;
      _selectedCommune = commune;
    });
    widget.onChanged(region, commune);
  }

  /// Diffère l'application des valeurs initiales après la fin du frame courant
  /// pour éviter "setState() called during build".
  void _scheduleApplyInitial(String? regionId, String? communeId) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyInitial(regionId, communeId);
    });
  }

  @override
  void didUpdateWidget(RegionCommuneSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    final regionChanged = widget.initialRegionId != oldWidget.initialRegionId;
    final communeChanged =
        widget.initialCommuneId != oldWidget.initialCommuneId;
    if (!_loading && (regionChanged || communeChanged)) {
      _scheduleApplyInitial(widget.initialRegionId, widget.initialCommuneId);
    }
  }

  void _onRegionChanged(RegionModel? region) {
    setState(() {
      _selectedRegion = region;
      _selectedCommune = null;
    });
    widget.onChanged(region, null);
  }

  void _onCommuneChanged(CommuneModel? commune) {
    setState(() => _selectedCommune = commune);
    widget.onChanged(_selectedRegion, commune);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.secondary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Région ──────────────────────────────────────
        _DropdownField<RegionModel>(
          label: 'Région',
          hint: 'Sélectionner une région',
          value: _selectedRegion,
          items: _regions,
          itemLabel: (r) => r.nom,
          onChanged: _onRegionChanged,
          enabled: true,
        ),
        const SizedBox(height: 12),

        // ── Commune (toutes les communes de la région) ──
        _DropdownField<CommuneModel>(
          label: 'Commune',
          hint: _selectedRegion == null
              ? 'Choisissez d\'abord une région'
              : 'Sélectionner une commune (${_communes.length})',
          value: _selectedCommune,
          items: _communes,
          itemLabel: (c) => c.nom,
          onChanged: _onCommuneChanged,
          enabled: _selectedRegion != null,
          errorText: widget.errorText,
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final bool enabled;
  final String? errorText;

  const _DropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.enabled,
    this.errorText,
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
            color: enabled
                ? AppColors.textSecondary
                : AppColors.buttonDisabledText,
          ),
          style: AppTextStyles.inputText,
          dropdownColor: AppColors.surface,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            errorText: errorText,
            errorStyle: AppTextStyles.inputError,
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
