import 'dart:async';
import 'package:flutter/foundation.dart';

class MockService {
  MockService._();

  static Future<void> delay([int ms = 800]) async {
    await Future.delayed(Duration(milliseconds: ms));
  }

  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    await delay();
    debugPrint('[MOCK] login identifier=$identifier');
    if (identifier.isEmpty || password.isEmpty) {
      throw Exception('Identifiants incorrects');
    }
    return {
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': 'mock_user_001',
      'needs_otp': false,
    };
  }

  static Future<Map<String, dynamic>> register({
    required String prenom,
    required String nom,
    required String password,
    String? phone,
    String? email,
  }) async {
    await delay();
    debugPrint('[MOCK] register prenom=$prenom phone=$phone email=$email');
    return {'success': true, 'otp_sent': true};
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String identifier,
    required String code,
  }) async {
    await delay(600);
    debugPrint('[MOCK] verifyOtp code=$code');
    if (code.length != 6) throw Exception('Code OTP invalide');
    return {'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}'};
  }

  static Future<Map<String, dynamic>> resendOtp({
    required String identifier,
  }) async {
    await delay(500);
    return {'success': true};
  }

  static Future<Map<String, dynamic>> getMe() async {
    await delay(400);
    return {
      'id': 'mock_user_001',
      'prenom': 'Amadou',
      'nom': 'Diallo',
      'phone': '771234567',
      'email': 'amadou@example.com',
      'is_verified': true,
      'commune_id': 'DK-DK-01',
      'commune_nom': 'Dakar Plateau',
      'registre': 'SN-123456-A',
      'date_naissance': '1990-05-15',
    };
  }

  static Future<Map<String, dynamic>> submitCertificate(
      Map<String, dynamic> payload) async {
    await delay(1000);
    final type = payload['type'] as String? ?? 'naissance';
    final id =
        'DOS-${type.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
    return {'dossier_id': id, 'status': 'soumis'};
  }

  static Future<List<Map<String, dynamic>>> getDossiers() async {
    await delay(600);
    return [
      {
        'id': 'DOS-NAISSANCE-001',
        'type': 'naissance',
        'status': 'en_verification',
        'created_at':
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'commune_nom': 'Dakar Plateau',
        'beneficiary_nom': 'Amadou Diallo',
        'frais': 500,
      },
      {
        'id': 'DOS-MARIAGE-002',
        'type': 'mariage',
        'status': 'pret',
        'created_at':
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        'commune_nom': 'Médina',
        'beneficiary_nom': 'Oumar Diop & Aïssatou Fall',
        'frais': 1000,
      },
      {
        'id': 'DOS-DECES-003',
        'type': 'deces',
        'status': 'soumis',
        'created_at':
            DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'commune_nom': 'Pikine Est',
        'beneficiary_nom': 'Mamadou Ba',
        'frais': 500,
      },
    ];
  }

  static Future<Map<String, dynamic>> getDossierById(String id) async {
    await delay(400);
    final all = await getDossiers();
    return all.firstWhere((d) => d['id'] == id, orElse: () => all.first);
  }

  static Future<Map<String, dynamic>> initiatePayment({
    required String dossierId,
    required String method,
    required String phone,
  }) async {
    await delay(1200);
    return {
      'success': true,
      'receipt': 'REC-${DateTime.now().millisecondsSinceEpoch}',
      'transaction_id': 'TXN-${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> data) async {
    await delay(600);
    final base = await getMe();
    return {...base, ...data};
  }

  static Future<void> changePin({
    required String oldPinHash,
    required String newPin,
  }) async {
    await delay(600);
  }

  static Future<Map<String, dynamic>> sendAssistantMessage({
    required String message,
    required String language,
  }) async {
    await delay(1000);
    final msg = message.toLowerCase();
    final responses =
        language == 'fr' ? _frResponses : _woResponses;
    if (msg.contains('naissance')) return {'response': responses['naissance']!};
    if (msg.contains('mariage')) return {'response': responses['mariage']!};
    if (msg.contains('décès') || msg.contains('deces')) {
      return {'response': responses['deces']!};
    }
    if (msg.contains('dossier') || msg.contains('suiv')) {
      return {'response': responses['dossier']!};
    }
    if (msg.contains('frais') || msg.contains('prix')) {
      return {'response': responses['frais']!};
    }
    return {'response': responses['default']!};
  }

  static const _frResponses = {
    'naissance': 'Pour un certificat de naissance : accueil → Certificat de naissance → choisissez le bénéficiaire → confirmez → payez 500 FCFA. Délai : 3 jours ouvrés.',
    'mariage': 'Pour un certificat de mariage : accueil → Certificat de mariage → renseignez les informations → payez 1 000 FCFA. Délai : 5 jours ouvrés.',
    'deces': 'Pour un certificat de décès : accueil → Certificat de décès → renseignez les informations → payez 500 FCFA. Délai : 3 jours ouvrés.',
    'dossier': 'Suivez vos dossiers dans l\'onglet "Dossiers" en bas. Statuts : Soumis → En vérification → Validé → Prêt.',
    'frais': 'Frais : Naissance 500 FCFA • Décès 500 FCFA • Mariage 1 000 FCFA. Paiement : Wave, Orange Money, Free Money.',
    'default': 'Bonjour ! Je suis l\'assistant TERANGA CIVIL. Comment puis-je vous aider avec vos certificats d\'état civil ?',
  };

  static const _woResponses = {
    'naissance': 'Certificat bu naissance : accueil → tëral Naissance → tann boo bëgg → jëfandiku 500 FCFA. Délai : 3 fan.',
    'mariage': 'Certificat bu mariage : accueil → tëral Mariage → bind yëf yi → jëfandiku 1 000 FCFA. Délai : 5 fan.',
    'deces': 'Certificat bu décès : accueil → tëral Décès → bind yëf yi → jëfandiku 500 FCFA. Délai : 3 fan.',
    'dossier': 'Xool sa dossiers ci onglet "Dossiers". Statuts : Soumis → Vérification → Validé → Prêt.',
    'frais': 'Jëfandiku : Naissance 500 FCFA • Décès 500 FCFA • Mariage 1 000 FCFA.',
    'default': 'Mangi fi ! Maa ngi Assistant TERANGA CIVIL. Lan laa mëna def ngir yëngël ci kanam ?',
  };

  /// Simule le téléchargement d'un certificat PDF
  static Future<String> downloadCertificate(String dossierId) async {
    await delay(1500);
    // En mock : retourne un chemin fictif
    return '/mock/downloads/certificat_$dossierId.pdf';
  }

  /// Simule l'OCR d'un extrait de naissance
  /// En production : POST /ocr/extract-naissance avec l'image en multipart
  static Future<Map<String, dynamic>> extractNaissanceOcr() async {
    await delay(1500); // Simule le temps de traitement OCR
    // Données simulées — seront remplacées par la vraie réponse backend
    return {
      'success': true,
      'data': {
        'nom': 'Moussa Diallo',
        'registre': '45678',
        'date_naissance': '1995-08-22',
        'commune_id': 'DK-PI-01',
        'commune_nom': 'Pikine Est',
        'region_id': 'DK',
        'region_nom': 'Dakar',
        'departement_id': 'DK-PI',
        'departement_nom': 'Pikine',
      },
    };
  }
}
