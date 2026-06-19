import '../../../../core/constants/app_constants.dart';

/// Mapping des statuts backend (Django, anglais) vers les codes utilisés
/// par l'UI Flutter (français) — voir [StatusBadge], [DossierProgressStepper]
/// et [AppFormatters.statusLabel].
const Map<String, String> kStatusBackendToUi = {
  'draft': 'en_cours',
  'submitted': 'soumis',
  'in_review': 'en_verification',
  'generated': 'valide',
  'validated': 'valide',
  'approved': 'valide',
  'delivered': 'pret',
  'completed': 'pret',
  'rejected': 'rejete',
};

/// Mapping inverse, utile si l'UI doit renvoyer un statut au backend.
const Map<String, String> kStatusUiToBackend = {
  'en_cours': 'draft',
  'soumis': 'submitted',
  'en_verification': 'in_review',
  'pret': 'approved',
  'rejete': 'rejected',
};

/// Mapping des types de dossier backend (Django) vers les codes UI Flutter.
const Map<String, String> kTypeBackendToUi = {
  'birth_certificate': 'naissance',
  'marriage_certificate': 'mariage',
  'death_certificate': 'deces',
  'residence_certificate': 'residence',
  'other': 'other',
};

/// Mapping inverse, utilisé lors de la soumission d'une nouvelle demande.
const Map<String, String> kTypeUiToBackend = {
  'naissance': 'birth_certificate',
  'mariage': 'marriage_certificate',
  'deces': 'death_certificate',
  'residence': 'residence_certificate',
  'other': 'other',
};

class DossierModel {
  final String id;
  final String type;
  final String status;
  final DateTime createdAt;
  final String? communeNom;
  final String? beneficiaryNom;
  final int? fraisFCFA;
  final String? agentNom;
  final String? agentPhone;
  // Champs exposés par le DossierDetailSerializer (et partiellement la liste).
  final String? reference; // ex: DOS-2026-B36C3
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? completedAt;
  final List<DossierDocument> documents;

  const DossierModel({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    this.communeNom,
    this.beneficiaryNom,
    this.fraisFCFA,
    this.agentNom,
    this.agentPhone,
    this.reference,
    this.submittedAt,
    this.reviewedAt,
    this.completedAt,
    this.documents = const [],
  });

  /// Frais officiels du dossier. Le backend n'expose pas de champ `frais`,
  /// on retombe donc sur le tarif officiel par type (foncier = 1000 FCFA).
  int get effectiveFeeFCFA {
    if (fraisFCFA != null && fraisFCFA! > 0) return fraisFCFA!;
    switch (type) {
      case 'naissance':
        return AppConstants.naissanceFeesFCFA;
      case 'deces':
        return AppConstants.decesFeesFCFA;
      case 'mariage':
        return AppConstants.mariageFeesFCFA;
      case 'residence':
        return AppConstants.residenceFeesFCFA;
      case 'regularisation':
      case 'autorisation_construire':
      case 'mutation_parcelle':
        return AppConstants.foncierFeesFCFA;
      default:
        return 0;
    }
  }

  /// Progression calculée depuis le statut UI (affichage uniquement)
  double get progress {
    switch (status) {
      case 'soumis':    return 0.25;
      case 'en_verification': return 0.5;
      case 'valide':    return 0.75;
      case 'pret':      return 1.0;
      case 'rejete':    return 0.3;
      default:          return 0.1; // en_cours / draft
    }
  }

  factory DossierModel.fromJson(Map<String, dynamic> json) {
    final backendType = json['type'] as String? ?? '';
    final backendStatus = json['status'] as String? ?? 'draft';
    return DossierModel(
      id: json['id'] as String? ?? '',
      // Codes backend (Django, anglais) traduits vers les codes UI
      // (français) attendus par StatusBadge / DossierProgressStepper /
      // AppFormatters et les écrans de dossiers.
      type: kTypeBackendToUi[backendType] ?? backendType,
      status: kStatusBackendToUi[backendStatus] ?? 'en_cours',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      // 'commune_name' = champ réel renvoyé par DossierListSerializer /
      // DossierDetailSerializer côté backend.
      communeNom: json['commune_name'] as String?,
      // Exposés par DossierListSerializer / DossierDetailSerializer
      // (beneficiary_nom, frais — voir apps/dossiers/serializers.py).
      beneficiaryNom: json['beneficiary_nom'] as String?,
      fraisFCFA: json['frais'] as int?,
      // 'agent_name' = champ déjà exposé par DossierListSerializer /
      // DossierDetailSerializer (assigned_agent.full_name).
      agentNom: json['agent_name'] as String?,
      agentPhone: (json['assigned_agent'] as Map<String, dynamic>?)?['phone']
          as String?,
      reference: json['reference'] as String?,
      submittedAt: _parseDate(json['submitted_at']),
      reviewedAt: _parseDate(json['reviewed_at']),
      completedAt: _parseDate(json['completed_at']),
      documents: (json['documents'] is List)
          ? (json['documents'] as List)
              .whereType<Map<String, dynamic>>()
              .map(DossierDocument.fromJson)
              .toList()
          : const [],
    );
  }

  static DateTime? _parseDate(dynamic v) =>
      (v is String && v.isNotEmpty) ? DateTime.tryParse(v) : null;
}

/// Pièce jointe d'un dossier (DocumentListSerializer côté backend).
class DossierDocument {
  final String id;
  final String filename;
  final String? fileType;
  final int? fileSize;
  final String? description;

  const DossierDocument({
    required this.id,
    required this.filename,
    this.fileType,
    this.fileSize,
    this.description,
  });

  factory DossierDocument.fromJson(Map<String, dynamic> json) => DossierDocument(
        id: json['id']?.toString() ?? '',
        filename: (json['original_filename'] as String?)?.trim().isNotEmpty ==
                true
            ? json['original_filename'] as String
            : 'Document',
        fileType: json['file_type'] as String?,
        fileSize: json['file_size'] as int?,
        description: json['description'] as String?,
      );

  /// Taille lisible (Ko / Mo).
  String? get sizeLabel {
    final s = fileSize;
    if (s == null || s <= 0) return null;
    if (s < 1024 * 1024) return '${(s / 1024).toStringAsFixed(0)} Ko';
    return '${(s / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}
