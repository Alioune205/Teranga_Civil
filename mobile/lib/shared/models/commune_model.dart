// Modèles de données pour le select cascadé Région → Département → Commune.
// Chargés depuis assets/data/senegal_communes.json

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

/// Commune telle que renvoyée par l'API backend (`GET /communes/`).
///
/// À la différence de [CommuneModel] (issu du JSON local
/// `senegal_communes.json`, identifiants type "DK-DK-01"), [id] correspond
/// ici à l'UUID de la commune côté backend — c'est cet identifiant qui doit
/// être envoyé lors de la création d'un dossier (`Dossier.commune` /
/// `RegistreCivil.commune`).
class BackendCommuneModel {
  final String id;
  final String name;
  final String region;
  final String department;
  final String code;

  const BackendCommuneModel({
    required this.id,
    required this.name,
    required this.region,
    required this.department,
    required this.code,
  });

  factory BackendCommuneModel.fromJson(Map<String, dynamic> json) =>
      BackendCommuneModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        region: json['region'] as String? ?? '',
        department: json['department'] as String? ?? '',
        code: json['code'] as String? ?? '',
      );

  @override
  String toString() => name;
}
