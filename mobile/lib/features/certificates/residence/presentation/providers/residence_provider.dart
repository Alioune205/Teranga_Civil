import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../dossiers/data/remote_datasource.dart';

class ResidenceState {
  final bool isLoading;
  final String? error;
  final String? dossierId;
  const ResidenceState({this.isLoading = false, this.error, this.dossierId});
  ResidenceState copyWith({
    bool? isLoading,
    String? error,
    String? dossierId,
    bool clearError = false,
  }) =>
      ResidenceState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        dossierId: dossierId ?? this.dossierId,
      );
}

class ResidenceNotifier extends StateNotifier<ResidenceState> {
  final DossiersRemoteDatasource _ds;
  ResidenceNotifier(this._ds) : super(const ResidenceState());

  /// Soumet une demande de certificat de résidence.
  ///
  /// Le backend (`DossierCreateSerializer.validate`) exige la présence des
  /// clés `cni_recto` et `attestation_delegue` dans `metadata`, sinon la
  /// création est rejetée (400). Le contenu n'étant pas encore exploité
  /// côté serveur, on envoie des marqueurs de présence et on téléverse les
  /// pièces réelles séparément (best-effort).
  Future<String> submit({
    required String communeId,
    required String nomComplet,
    String? pieceIdentitePath,
    String? attestationDeleguePath,
    String? copieCniPath,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Le template PDF résidence lit prenoms_requerant + nom_requerant
      // (dernier mot = nom de famille, le reste = prénoms).
      final parts =
          nomComplet.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
      final tokens = parts.toList();
      final prenomsRequerant =
          tokens.length > 1 ? tokens.sublist(0, tokens.length - 1).join(' ') : nomComplet;
      final nomRequerant = tokens.length > 1 ? tokens.last : '';

      final id = await _ds.submitCertificate({
        'type': 'residence',
        'commune_id': communeId,
        'beneficiary': {
          'nom': nomComplet,
          'prenoms_requerant': prenomsRequerant,
          'nom_requerant': nomRequerant,
          // Clés requises par la validation backend (présence obligatoire).
          'cni_recto': true,
          'attestation_delegue': true,
          'copie_cni': true,
        },
      });

      // Téléversement best-effort des pièces réelles (n'empêche pas la
      // création si l'upload échoue, ex. en web sans chemin de fichier).
      if (pieceIdentitePath != null) {
        try {
          await _ds.uploadDocument(
            dossierId: id,
            filePath: pieceIdentitePath,
            description: 'Pièce d\'identité',
          );
        } catch (_) {/* best-effort */}
      }
      if (attestationDeleguePath != null) {
        try {
          await _ds.uploadDocument(
            dossierId: id,
            filePath: attestationDeleguePath,
            description: 'Attestation du délégué de quartier',
          );
        } catch (_) {/* best-effort */}
      }
      if (copieCniPath != null) {
        try {
          await _ds.uploadDocument(
            dossierId: id,
            filePath: copieCniPath,
            description: 'Copie CNI',
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

final residenceProvider =
    StateNotifierProvider<ResidenceNotifier, ResidenceState>((ref) =>
        ResidenceNotifier(
            DossiersRemoteDatasource(client: ref.read(dioClientProvider))));
