import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/mock/mock_config.dart';
import '../../../core/mock/mock_service.dart';
import '../../../core/utils/pdf_saver.dart';
import '../../../shared/widgets/upload_document_card.dart' show DocumentUploadHelper;
import 'models/dossier_model.dart';

class DossiersRemoteDatasource {
  final DioClient client;
  const DossiersRemoteDatasource({required this.client});

  Future<List<DossierModel>> getDossiers() async {
    final res = await client.get('/dossiers/');
    if (res.statusCode == 200 && res.data != null) {
      final body = res.data;
      // Réponse paginée standard : {success, message, data: {results: [...]}, errors}
      final data = (body is Map<String, dynamic>) ? body['data'] : null;
      final list = (data is Map<String, dynamic>) ? data['results'] : body;
      if (list is List) {
        return list
            .map((e) => DossierModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw const ApiException(message: 'Impossible de charger les dossiers');
  }

  Future<DossierModel> getDossierById(String id) async {
    final res = await client.get('/dossiers/$id/');
    if (res.statusCode == 200 && res.data != null) {
      final body = res.data;
      final inner = (body is Map<String, dynamic>) ? body['data'] : null;
      if (inner is Map<String, dynamic>) {
        return DossierModel.fromJson(inner);
      }
      if (body is Map<String, dynamic>) {
        return DossierModel.fromJson(body);
      }
    }
    throw const NotFoundException();
  }

  /// Vérifie qu'un acte existe dans le Registre Civil de la commune avant
  /// de créer la demande (`POST /dossiers/verify-registry/`).
  ///
  /// Ne renvoie rien si l'acte est trouvé ; lève une [ApiException] avec le
  /// message du backend sinon (« acte introuvable », « les noms ne
  /// correspondent pas », CNI requise pour un tiers…).
  Future<void> verifyRegistry({
    required String numeroRegistre,
    required int anneeRegistre,
    required String communeCode,
    required String typeActe,
    bool isForThirdParty = false,
  }) async {
    try {
      await client.post('/dossiers/verify-registry/', data: {
        'numero_registre': numeroRegistre,
        'annee_registre': anneeRegistre,
        'commune': communeCode,
        'type_acte': typeActe,
        'is_for_third_party': isForThirdParty,
      });
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map<String, dynamic>)
          ? (data['message'] as String? ??
              'Acte introuvable dans le Registre Civil.')
          : 'Acte introuvable dans le Registre Civil.';
      throw ApiException(message: msg, statusCode: e.response?.statusCode);
    }
  }

  /// Crée un dossier (brouillon) puis le soumet immédiatement.
  ///
  /// [payload] est construit par les providers de certificats
  /// (naissance/mariage/décès) avec les clés :
  /// - `type` : code UI français (`naissance`, `mariage`, `deces`, ...)
  /// - `commune_id` : identifiant de la commune (UUID backend)
  /// - `beneficiary` : informations bénéficiaire (Map) — historique, ignoré
  ///   par le backend (non couvert par `DossierCreateSerializer`).
  /// - `for_self` (optionnel) : booléen — historique, ignoré par le backend.
  /// - `declarant` (optionnel) : informations déclarant (Map) — historique,
  ///   ignoré par le backend.
  /// - `numero_registre` / `annee_registre` / `date_naissance` (optionnels) :
  ///   transmis tels quels — le backend retrouve l'enregistrement
  ///   `RegistreCivil` correspondant et remplit lui-même `metadata`.
  /// - `is_for_third_party` / `third_party_relation` / `third_party_cni`
  ///   (optionnels) : transmis tels quels.
  ///
  /// Retourne l'identifiant du dossier créé.
  /// Crée le dossier puis le soumet.
  ///
  /// [autoSubmit] : si `false`, le dossier est seulement créé (statut
  /// brouillon) et l'id renvoyé — utile quand des pièces doivent être
  /// téléversées AVANT la soumission (ex. demandes foncières, dont le backend
  /// exige les justificatifs avant `submit`). Appeler ensuite [submitDossier].
  Future<String> submitCertificate(
    Map<String, dynamic> payload, {
    bool autoSubmit = true,
  }) async {
    final uiType = payload['type'] as String? ?? '';
    final backendType = kTypeUiToBackend[uiType] ?? uiType;

    final createPayload = <String, dynamic>{
      'type': backendType,
      'commune': payload['commune_id'],
      'notes': payload['notes'] ?? '',
    };
    if (payload['beneficiary'] != null) {
      createPayload['beneficiary'] = payload['beneficiary'];
    }
    if (payload.containsKey('for_self')) {
      createPayload['for_self'] = payload['for_self'];
    }
    if (payload['declarant'] != null) {
      createPayload['declarant'] = payload['declarant'];
    }
    for (final key in [
      'numero_registre',
      'annee_registre',
      'date_naissance',
      'is_for_third_party',
      'third_party_relation',
      'third_party_cni',
    ]) {
      if (payload.containsKey(key)) {
        createPayload[key] = payload[key];
      }
    }

    // Le backend (DossierCreateSerializer) ne persiste QUE le champ `metadata`
    // (JSONField). On y consolide donc toutes les infos saisies (registre,
    // dates, noms) avec les clés lues par le détail web et le générateur PDF,
    // sinon elles s'affichent en « — » côté guichet.
    final metadata = <String, dynamic>{};
    final beneficiary = payload['beneficiary'];
    if (beneficiary is Map) {
      metadata.addAll(Map<String, dynamic>.from(beneficiary));
    }
    final declarant = payload['declarant'];
    if (declarant is Map) {
      metadata['declarant'] = Map<String, dynamic>.from(declarant);
    }
    for (final key in ['numero_registre', 'annee_registre', 'date_naissance', 'nom', 'registre']) {
      if (payload[key] != null) metadata[key] = payload[key];
    }
    // Normalisation vers les clés attendues par le web.
    final reg = metadata['numero_registre'] ?? metadata['registre'] ?? metadata['registre_marriage'];
    if (reg != null) {
      metadata['numero_registre'] = reg.toString();
      metadata['registre'] = reg.toString();
    }
    final annee = metadata['annee_registre'] ?? metadata['annee_marriage'];
    if (annee != null) metadata['annee_registre'] = annee;
    final dateN = metadata['date_naissance'] ?? metadata['date_deces'];
    if (dateN != null) {
      metadata['date_naissance_personne'] = dateN;
      metadata['date_naissance'] = dateN;
    }
    final nomComplet =
        (metadata['nom'] ?? metadata['nom_epoux'] ?? metadata['nom_enfant'])
            ?.toString()
            .trim();
    if (nomComplet != null && nomComplet.isNotEmpty) {
      metadata['nom'] = nomComplet;
      // Le générateur PDF backend lit prenoms_enfant + nom_enfant séparément.
      // Convention : dernier mot = nom de famille, le reste = prénoms.
      final parts =
          nomComplet.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length > 1) {
        metadata['nom_enfant'] = parts.last;
        metadata['prenoms_enfant'] = parts.sublist(0, parts.length - 1).join(' ');
      } else {
        metadata['nom_enfant'] = nomComplet;
      }
    }
    if (metadata.isNotEmpty) createPayload['metadata'] = metadata;

    // 1) Création du dossier (statut "brouillon").
    final createRes = await client.post('/dossiers/', data: createPayload);
    if (createRes.statusCode != 200 && createRes.statusCode != 201) {
      throw ApiException(
        message: _extractError(createRes.data) ??
            'Erreur lors de la création du dossier',
        statusCode: createRes.statusCode,
      );
    }
    final createBody = createRes.data;
    final created =
        (createBody is Map<String, dynamic>) ? createBody['data'] : null;
    final dossierId =
        (created is Map<String, dynamic>) ? created['id'] as String? : null;
    if (dossierId == null) {
      throw const ApiException(
          message: 'Réponse invalide lors de la création du dossier');
    }

    // 2) Soumission du dossier (passage au statut "soumis").
    // Sautée si autoSubmit=false (le dossier reste en brouillon, le temps de
    // téléverser les pièces, puis on appellera submitDossier).
    if (autoSubmit) {
      await submitDossier(dossierId);
    }

    return dossierId;
  }

  /// Soumet un dossier déjà créé (passage au statut « soumis »).
  /// Remonte le message backend en cas d'échec (ex. pièces manquantes pour
  /// les demandes foncières).
  Future<void> submitDossier(String dossierId) async {
    final submitRes = await client.post('/dossiers/$dossierId/submit/');
    if (submitRes.statusCode != 200) {
      throw ApiException(
        message: _extractError(submitRes.data) ??
            'Erreur lors de la soumission du dossier',
        statusCode: submitRes.statusCode,
      );
    }
  }

  /// Extrait un message lisible depuis la réponse d'erreur DRF standardisée
  /// (`{success, message, data, errors}`). Privilégie le détail de validation
  /// (`errors`) au message générique « Requête invalide. », pour que
  /// l'utilisateur voie la vraie raison (ex. date de décès de plus d'un an).
  String? _extractError(dynamic data) {
    if (data is! Map) return null;
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first is String && first.isNotEmpty) return first;
    }
    final msg = data['message'];
    if (msg is String && msg.isNotEmpty && msg != 'Requête invalide.') {
      return msg;
    }
    return null;
  }

  /// Construit un nom de fichier sûr **avec une extension valide**.
  /// Sur web, le chemin est une URL blob sans extension, ce qui fait rejeter
  /// l'upload par la validation backend. On déduit alors l'extension des
  /// magic bytes (png/pdf/jpg), défaut `jpg`.
  String _safeFileName(String path, List<int>? bytes) {
    final last = path.split(RegExp(r'[\\/]')).last;
    final hasExt =
        RegExp(r'\.(jpe?g|png|pdf|webp|heic)$', caseSensitive: false)
            .hasMatch(last);
    if (hasExt) return last;
    String ext = 'jpg';
    if (bytes != null && bytes.length >= 4) {
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        ext = 'png';
      } else if (bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46) {
        ext = 'pdf';
      }
    }
    return 'document.$ext';
  }

  /// Téléverse une pièce jointe (ex : CNI recto/verso) liée à un dossier.
  ///
  /// Retourne `true` si la pièce a bien été créée, `false` si le backend l'a
  /// rejetée comme **doublon** (HTTP 409 : fichier identique déjà téléversé).
  /// En cas d'autre échec, lève une [ApiException]. Le `false` permet aux
  /// appelants exigeant un nombre de pièces (foncier) de prévenir l'utilisateur
  /// qu'une pièce est en double.
  Future<bool> uploadDocument({
    required String dossierId,
    required String filePath,
    String description = '',
  }) async {
    // Les octets sont mis en cache au moment de la sélection (web ET natif),
    // ce qui permet `fromBytes` partout. On ne retombe sur `fromFile` que si
    // les octets ne sont pas disponibles (chemin natif venant d'ailleurs).
    final bytes = DocumentUploadHelper.bytesFor(filePath);
    // Sur web, `filePath` est une URL blob SANS extension → le backend rejette
    // le fichier (validation d'extension). On garantit donc un nom propre avec
    // l'extension déduite des magic bytes (jpg/png/pdf), sinon `.jpg`.
    final fileName = _safeFileName(filePath, bytes);
    final MultipartFile multipart = bytes != null
        ? MultipartFile.fromBytes(bytes, filename: fileName)
        : await MultipartFile.fromFile(filePath, filename: fileName);
    final formData = FormData.fromMap({
      'dossier': dossierId,
      'description': description,
      'file': multipart,
    });
    final res = await client.post('/documents/', data: formData);
    // 409 = doublon strict détecté côté backend (même fichier, même hash
    // SHA-256 déjà téléversé). La pièce n'est PAS rattachée : on renvoie false.
    if (res.statusCode == 409) return false;
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ApiException(
        message: 'Échec de l\'envoi du document ($description)',
        statusCode: res.statusCode,
      );
    }
    return true;
  }

  /// Télécharge le certificat PDF pour un dossier.
  /// Retourne le chemin local (natif) ou le nom du fichier (web).
  Future<String> downloadCertificate(
    String dossierId, {
    void Function(int received, int total)? onProgress,
  }) async {
    if (kMockMode) {
      // Simulation en mode mock
      return MockService.downloadCertificate(dossierId);
    }
    // Endpoint réel du backend : `download-pdf/` (et non `download/` qui n'existe
    // pas). On récupère le PDF en bytes, puis on le sauvegarde selon la plateforme
    // (web : téléchargement navigateur ; natif : fichier dans documents).
    final res = await client.get<List<int>>(
      '/dossiers/$dossierId/download-pdf/',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = res.data ?? const <int>[];
    if (bytes.isEmpty) {
      throw const ApiException(message: 'Certificat indisponible.');
    }
    debugPrint('[DOWNLOAD] PDF reçu (${bytes.length} octets)');
    return savePdf(bytes, 'certificat_$dossierId.pdf');
  }
}
