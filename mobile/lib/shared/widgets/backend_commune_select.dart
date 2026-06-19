import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/network/dio_client.dart';
import '../data/communes_remote_datasource.dart';
import '../models/commune_model.dart';

/// Provider listant les communes côté backend (`GET /communes/`).
final backendCommunesProvider = FutureProvider<List<BackendCommuneModel>>((ref) async {
  final ds = CommunesRemoteDatasource(client: ref.read(dioClientProvider));
  return ds.getCommunes();
});

/// Select à 2 niveaux : Région (texte) → Commune, basé sur les communes
/// renvoyées par le backend (`/api/communes/`).
///
/// À utiliser à la place de [RegionCommuneSelect] partout où l'identifiant
/// de commune envoyé au serveur doit correspondre à l'UUID `Commune` du
/// backend (ex: dossiers liés au Registre Civil).
class BackendCommuneSelect extends ConsumerStatefulWidget {
  /// Appelé à chaque changement avec la région (nom) et la commune
  /// sélectionnées.
  final void Function(String? region, BackendCommuneModel? commune) onChanged;
  final String? errorText;

  /// ID backend (UUID) ou code de commune à pré-sélectionner (ex: depuis un
  /// brouillon restauré).
  final String? initialCommuneId;

  const BackendCommuneSelect({
    super.key,
    required this.onChanged,
    this.errorText,
    this.initialCommuneId,
  });

  @override
  ConsumerState<BackendCommuneSelect> createState() => _BackendCommuneSelectState();
}

class _BackendCommuneSelectState extends ConsumerState<BackendCommuneSelect> {
  String? _selectedRegion;
  BackendCommuneModel? _selectedCommune;
  bool _initialApplied = false;

  List<String> _regions(List<BackendCommuneModel> communes) {
    final regions = communes.map((c) => c.region).toSet().toList();
    regions.sort();
    return regions;
  }

  List<BackendCommuneModel> _communesForRegion(
      List<BackendCommuneModel> communes, String? region) {
    if (region == null) return [];
    final list = communes.where((c) => c.region == region).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  void _applyInitial(List<BackendCommuneModel> communes) {
    final initialId = widget.initialCommuneId;
    if (initialId == null || initialId.isEmpty) return;
    BackendCommuneModel? commune;
    try {
      commune = communes.firstWhere(
        (c) => c.id == initialId || c.code == initialId,
      );
    } catch (_) {
      return;
    }
    final region = commune.region;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedRegion = region;
        _selectedCommune = commune;
      });
      widget.onChanged(region, commune);
    });
  }

  void _onRegionChanged(String? region, List<BackendCommuneModel> communes) {
    setState(() {
      _selectedRegion = region;
      _selectedCommune = null;
    });
    widget.onChanged(region, null);
  }

  void _onCommuneChanged(BackendCommuneModel? commune) {
    setState(() => _selectedCommune = commune);
    widget.onChanged(_selectedRegion, commune);
  }

  @override
  Widget build(BuildContext context) {
    final communesAsync = ref.watch(backendCommunesProvider);

    return communesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
          ),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.statusAmberLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.statusAmber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_outlined,
                color: AppColors.statusAmber, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Impossible de charger la liste des communes. '
                'Vérifiez votre connexion et réessayez.',
                style: AppTextStyles.caption.copyWith(color: AppColors.statusAmber),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.statusAmber, size: 18),
              onPressed: () => ref.invalidate(backendCommunesProvider),
            ),
          ],
        ),
      ),
      data: (communes) {
        if (!_initialApplied) {
          _initialApplied = true;
          _applyInitial(communes);
        }
        final regions = _regions(communes);
        final communesInRegion = _communesForRegion(communes, _selectedRegion);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Région ──────────────────────────────────────
            _DropdownField<String>(
              label: 'Région',
              hint: 'Sélectionner une région',
              value: _selectedRegion,
              items: regions,
              itemLabel: (r) => r,
              onChanged: (r) => _onRegionChanged(r, communes),
              enabled: true,
            ),
            const SizedBox(height: 12),

            // ── Commune ───────────────────────────────────
            _DropdownField<BackendCommuneModel>(
              label: 'Commune',
              hint: _selectedRegion == null
                  ? 'Choisissez d\'abord une région'
                  : 'Sélectionner une commune (${communesInRegion.length})',
              value: _selectedCommune,
              items: communesInRegion,
              itemLabel: (c) => c.name,
              onChanged: _onCommuneChanged,
              enabled: _selectedRegion != null,
              errorText: widget.errorText,
            ),
          ],
        );
      },
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
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
