import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/features/profile/data/models/profile_model.dart';

void main() {
  group('ProfileUpdateModel', () {
    test('toJson inclut uniquement les champs non nuls', () {
      const model = ProfileUpdateModel(nom: 'Amadou');
      final json = model.toJson();
      expect(json.containsKey('nom'), isTrue);
      expect(json.containsKey('commune_id'), isFalse);
    });

    test('toJson inclut les deux champs si fournis', () {
      const model = ProfileUpdateModel(nom: 'Amadou', communeId: 'DK-01');
      final json = model.toJson();
      expect(json['nom'], equals('Amadou'));
      expect(json['commune_id'], equals('DK-01'));
    });

    test('toJson retourne un map vide si aucun champ fourni', () {
      const model = ProfileUpdateModel();
      expect(model.toJson().isEmpty, isTrue);
    });
  });
}
