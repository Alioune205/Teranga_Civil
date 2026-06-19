import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/features/dossiers/data/models/dossier_model.dart';

void main() {
  group('DossierModel.fromJson', () {
    test('parse correctement un dossier valide', () {
      final json = {
        'id': 'd_001',
        'type': 'naissance',
        'status': 'en_verification',
        'created_at': '2024-03-15T10:30:00.000Z',
        'commune_nom': 'Dakar Plateau',
        'beneficiary_nom': 'Amadou Diallo',
        'frais': 500,
      };
      final model = DossierModel.fromJson(json);
      expect(model.id, equals('d_001'));
      expect(model.type, equals('naissance'));
      expect(model.status, equals('en_verification'));
      expect(model.communeNom, equals('Dakar Plateau'));
      expect(model.fraisFCFA, equals(500));
    });

    test('gère les champs optionnels null', () {
      final json = {
        'id': 'd_002',
        'type': 'deces',
        'status': 'soumis',
        'created_at': '2024-03-15T10:30:00.000Z',
      };
      final model = DossierModel.fromJson(json);
      expect(model.communeNom, isNull);
      expect(model.beneficiaryNom, isNull);
      expect(model.fraisFCFA, isNull);
    });

    test('utilise DateTime.now() si created_at invalide', () {
      final json = {
        'id': 'd_003',
        'type': 'mariage',
        'status': 'pret',
        'created_at': 'date-invalide',
      };
      final model = DossierModel.fromJson(json);
      final diff = DateTime.now().difference(model.createdAt);
      expect(diff.inSeconds.abs(), lessThan(5));
    });

    test('statut par défaut = soumis si absent', () {
      final json = {
        'id': 'd_004',
        'type': 'naissance',
        'created_at': '2024-01-01T00:00:00.000Z',
      };
      final model = DossierModel.fromJson(json);
      expect(model.status, equals('soumis'));
    });
  });
}
