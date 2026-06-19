import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/widgets/upload_document_card.dart'
    show DocumentUploadHelper;

class NaissanceRemoteDatasource {
  final DioClient client;
  const NaissanceRemoteDatasource({required this.client});

  /// Envoie la **vraie** image au backend OCR (`/ai/ocr/extract/`) en multipart
  /// avec `dossier_type=birth_certificate`, et retourne les données extraites
  /// normalisées vers les clés attendues par l'écran (`registre`,
  /// `annee_registre`, `date_naissance` en ISO, `nom`).
  ///
  /// Depuis le fix backend du 14/06, l'OCR dispose d'un **parseur d'extrait de
  /// naissance** (déclenché par `dossier_type=birth_certificate`) qui renvoie
  /// `numero_registre`, `annee_registre`, `commune`, `date_naissance`, `nom`,
  /// `prenom`. Le `check_dossier_duplicate` a aussi été retiré de l'OCR, donc
  /// envoyer `dossier_type` ne provoque plus de 400.
  Future<Map<String, dynamic>> extractOcr(String imagePath) async {
    try {
      final fileName = imagePath.split(RegExp(r'[\\/]')).last;
      final bytes = DocumentUploadHelper.bytesFor(imagePath);
      final MultipartFile multipart = bytes != null
          ? MultipartFile.fromBytes(bytes, filename: fileName)
          : await MultipartFile.fromFile(imagePath, filename: fileName);

      final formData = FormData.fromMap({
        'document': multipart,
        'dossier_type': 'birth_certificate',
      });

      final res = await client.post('/ai/ocr/extract/', data: formData);

      if (res.statusCode == 200 && res.data is Map) {
        final body = res.data as Map<String, dynamic>;
        final extracted =
            (body['extracted_data'] as Map?)?.cast<String, dynamic>() ?? {};
        return _normalize(extracted);
      }
      throw const ApiException(message: 'Extraction OCR échouée');
    } on DioException {
      throw const ApiException(message: 'Erreur lors de l\'extraction OCR');
    }
  }

  /// Mappe les champs du parseur d'extrait backend vers les clés consommées par
  /// l'écran : `registre`, `annee_registre`, `date_naissance` (ISO), `nom`.
  /// La commune renvoyée (nom libre) n'est pas mappée : la sélection commune
  /// reste manuelle (elle exige un identifiant, pas un nom).
  Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};

    final reg = (raw['numero_registre'] as String?)?.trim() ?? '';
    if (reg.isNotEmpty) out['registre'] = reg;

    final annee = (raw['annee_registre']?.toString())?.trim() ?? '';
    if (RegExp(r'^\d{4}$').hasMatch(annee)) out['annee_registre'] = annee;

    final iso = _toIsoDate((raw['date_naissance'] as String?)?.trim() ?? '');
    if (iso != null) out['date_naissance'] = iso;

    final nomComplet =
        '${(raw['prenom'] ?? '').toString().trim()} ${(raw['nom'] ?? '').toString().trim()}'
            .trim();
    if (nomComplet.isNotEmpty) out['nom'] = nomComplet;

    return out;
  }

  /// Convertit une date OCR (`jj/mm/aaaa` ou `aaaa/mm/jj`, séparateurs `/` ou
  /// `-`) en ISO `aaaa-mm-jj`. Retourne null si le format est inattendu.
  String? _toIsoDate(String value) {
    final v = value.replaceAll(RegExp(r'[.\s-]'), '/');
    final dmy = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(v);
    if (dmy != null) {
      return '${dmy.group(3)}-${dmy.group(2)}-${dmy.group(1)}';
    }
    final ymd = RegExp(r'^(\d{4})/(\d{2})/(\d{2})$').firstMatch(v);
    if (ymd != null) {
      return '${ymd.group(1)}-${ymd.group(2)}-${ymd.group(3)}';
    }
    return null;
  }
}
