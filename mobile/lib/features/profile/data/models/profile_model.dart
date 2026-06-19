class ProfileUpdateModel {
  final String? nom;
  final String? communeId;

  const ProfileUpdateModel({this.nom, this.communeId});

  Map<String, dynamic> toJson() => {
        if (nom != null) 'nom': nom,
        if (communeId != null) 'commune_id': communeId,
      };
}
