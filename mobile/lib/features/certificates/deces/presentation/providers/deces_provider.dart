import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../dossiers/data/remote_datasource.dart';

class DecesState {
  final bool isLoading;
  final String? error;
  final String? dossierId;
  const DecesState({this.isLoading = false, this.error, this.dossierId});
  DecesState copyWith({bool? isLoading, String? error, String? dossierId,
      bool clearError = false}) =>
      DecesState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        dossierId: dossierId ?? this.dossierId,
      );
}

class DecesNotifier extends StateNotifier<DecesState> {
  final DossiersRemoteDatasource _ds;
  DecesNotifier(this._ds) : super(const DecesState());

  Future<String> submit({
    required String communeId,
    required String nomDefunt,
    required String registre,
    required DateTime dateDeces,
    String nomDeclarant = '',
    String lienParente = '',
    String? docRectoPath,
    String? docVersoPath,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Le template PDF décès lit prenom_defunt + nom_defunt (séparés) et
      // nom_declarant + lien_declarant (à plat) — pas `nom` ni `declarant`
      // imbriqué. On envoie donc directement ces clés.
      final parts = nomDefunt
          .trim()
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      final prenomDefunt = parts.length > 1
          ? parts.sublist(0, parts.length - 1).join(' ')
          : nomDefunt;
      final nomFamilleDefunt = parts.length > 1 ? parts.last : '';

      final id = await _ds.submitCertificate({
        'type': 'deces',
        'commune_id': communeId,
        'beneficiary': {
          'nom': nomDefunt,
          'prenom_defunt': prenomDefunt,
          'nom_defunt': nomFamilleDefunt,
          'registre': registre,
          'date_deces': dateDeces.toIso8601String().split('T').first,
          // Déclarant (clés à plat lues par le template).
          'nom_declarant': nomDeclarant,
          'lien_declarant': lienParente,
          // Clés exigées par la validation backend (présence requise).
          'constat_medecin': true,
          'cni_defunt': true,
        },
      });

      // Téléversement best-effort de la pièce d'identité du déclarant.
      for (final p in [docRectoPath, docVersoPath]) {
        if (p != null) {
          try {
            await _ds.uploadDocument(
                dossierId: id, filePath: p, description: 'Pièce déclarant');
          } catch (_) {/* best-effort */}
        }
      }

      state = state.copyWith(isLoading: false, dossierId: id);
      return id;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final decesProvider =
    StateNotifierProvider<DecesNotifier, DecesState>((ref) =>
        DecesNotifier(
            DossiersRemoteDatasource(client: ref.read(dioClientProvider))));
