import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../dossiers/data/remote_datasource.dart';

class RegularisationState {
  final bool isLoading;
  final String? error;
  final String? dossierId;
  const RegularisationState({this.isLoading = false, this.error, this.dossierId});
  RegularisationState copyWith({
    bool? isLoading,
    String? error,
    String? dossierId,
    bool clearError = false,
  }) =>
      RegularisationState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        dossierId: dossierId ?? this.dossierId,
      );
}

class RegularisationNotifier extends StateNotifier<RegularisationState> {
  final DossiersRemoteDatasource _ds;
  RegularisationNotifier(this._ds) : super(const RegularisationState());

  Future<String> submit({
    required String communeId,
    required String nomComplet,
    required String numeroCni,
    required String telephone,
    required String localisationTerrain,
    String? demandeMairePath,
    String? pieceIdentitePath,
    String? acteTerrainPath,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final id = await _ds.submitCertificate({
        'type': 'regularisation',
        'commune_id': communeId,
        'beneficiary': {
          'nom_complet_requerant': nomComplet,
          'numero_cni': numeroCni,
          'telephone': telephone,
          'localisation_terrain': localisationTerrain,
        },
      });

      if (demandeMairePath != null) {
        try {
          await _ds.uploadDocument(
            dossierId: id,
            filePath: demandeMairePath,
            description: 'Demande adressée au Maire',
          );
        } catch (_) {/* best-effort */}
      }
      if (pieceIdentitePath != null) {
        try {
          await _ds.uploadDocument(
            dossierId: id,
            filePath: pieceIdentitePath,
            description: 'Photocopie de la pièce d\'identité du requérant',
          );
        } catch (_) {/* best-effort */}
      }
      if (acteTerrainPath != null) {
        try {
          await _ds.uploadDocument(
            dossierId: id,
            filePath: acteTerrainPath,
            description: 'Acte original du terrain',
          );
        } catch (_) {/* best-effort */}
      }

      state = state.copyWith(isLoading: false, dossierId: id);
      return id;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final regularisationProvider =
    StateNotifierProvider<RegularisationNotifier, RegularisationState>((ref) =>
        RegularisationNotifier(
            DossiersRemoteDatasource(client: ref.read(dioClientProvider))));
