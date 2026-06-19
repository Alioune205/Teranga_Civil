import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../../../dossiers/data/remote_datasource.dart';

/// État d'une soumission de demande foncière.
class FoncierState {
  final bool isLoading;
  final String? error;
  final String? dossierId;
  const FoncierState({this.isLoading = false, this.error, this.dossierId});
  FoncierState copyWith({
    bool? isLoading,
    String? error,
    String? dossierId,
    bool clearError = false,
  }) =>
      FoncierState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        dossierId: dossierId ?? this.dossierId,
      );
}

class FoncierNotifier extends StateNotifier<FoncierState> {
  final DossiersRemoteDatasource _ds;
  FoncierNotifier(this._ds) : super(const FoncierState());

  /// Soumet une demande foncière (régularisation, autorisation de construire,
  /// mutation de parcelle).
  ///
  /// Le backend lit dans `metadata` : `localisation_terrain`,
  /// `quartier_village`, `superficie`, `reference_cadastrale` (les infos du
  /// requérant — nom, CNI… — sont reprises du profil si non fournies).
  /// `type` est déjà le type backend (`regularisation`,
  /// `autorisation_construire`, `mutation_parcelle`) : pas de mapping.
  Future<String> submit({
    required String type,
    required String communeId,
    required String localisationTerrain,
    required String quartierVillage,
    required String superficie,
    required String referenceCadastrale,
    List<({String path, String description})> documents = const [],
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // 1) Création SEULE (brouillon) — le backend exige les pièces AVANT la
      //    soumission pour les demandes foncières, donc autoSubmit=false.
      final id = await _ds.submitCertificate(
        {
          'type': type,
          'commune_id': communeId,
          // submitCertificate fusionne `beneficiary` dans `metadata`.
          'beneficiary': {
            'localisation_terrain': localisationTerrain,
            'quartier_village': quartierVillage,
            'superficie': superficie,
            'reference_cadastrale': referenceCadastrale,
          },
        },
        autoSubmit: false,
      );

      // 2) Téléversement des pièces (requises avant la soumission). Le backend
      //    rejette les fichiers identiques (doublon) : on compte ces cas pour
      //    prévenir clairement l'utilisateur (sinon la soumission échouerait
      //    sur un nombre de pièces insuffisant, avec un message obscur).
      var doublons = 0;
      for (final doc in documents) {
        final created = await _ds.uploadDocument(
          dossierId: id,
          filePath: doc.path,
          description: doc.description,
        );
        if (!created) doublons++;
      }
      if (doublons > 0) {
        throw ApiException(
          message:
              'Chaque pièce doit être un fichier différent : $doublons document(s) '
              'identique(s) détecté(s). Reprenez des photos/fichiers distincts.',
        );
      }

      // 3) Soumission (le backend vérifie le nombre de pièces requis).
      await _ds.submitDossier(id);

      state = state.copyWith(isLoading: false, dossierId: id);
      return id;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final foncierProvider =
    StateNotifierProvider<FoncierNotifier, FoncierState>((ref) =>
        FoncierNotifier(
            DossiersRemoteDatasource(client: ref.read(dioClientProvider))));
