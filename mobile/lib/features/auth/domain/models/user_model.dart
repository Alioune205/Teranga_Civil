class UserModel {
  final String id;
  final String prenom;
  final String nom;
  final String? phone;
  final String? email;
  final bool isVerified;
  final String? role;
  // Champs optionnels pour compatibilité avec les certificats
  final String? communeId;
  final String? communeNom;
  final String? registre;
  final DateTime? dateNaissance;

  const UserModel({
    required this.id,
    required this.prenom,
    required this.nom,
    this.phone,
    this.email,
    this.isVerified = false,
    this.role,
    this.communeId,
    this.communeNom,
    this.registre,
    this.dateNaissance,
  });

  String get nomComplet => '$prenom $nom';

  UserModel copyWith({
    String? id,
    String? prenom,
    String? nom,
    String? phone,
    String? email,
    bool? isVerified,
    String? role,
    String? communeId,
    String? communeNom,
    String? registre,
    DateTime? dateNaissance,
  }) =>
      UserModel(
        id: id ?? this.id,
        prenom: prenom ?? this.prenom,
        nom: nom ?? this.nom,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        isVerified: isVerified ?? this.isVerified,
        role: role ?? this.role,
        communeId: communeId ?? this.communeId,
        communeNom: communeNom ?? this.communeNom,
        registre: registre ?? this.registre,
        dateNaissance: dateNaissance ?? this.dateNaissance,
      );
}
