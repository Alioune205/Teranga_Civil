import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../mock/mock_service.dart';

class MockInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final path = options.path;
    final method = options.method.toUpperCase();
    final data = options.data as Map<String, dynamic>? ?? {};
    debugPrint('[MOCK] $method $path');

    try {
      final responseData = await _handle(method, path, data);
      handler.resolve(Response(
          requestOptions: options, statusCode: 200, data: responseData));
    } catch (e) {
      handler.reject(DioException(
        requestOptions: options,
        message: e.toString(),
        type: DioExceptionType.badResponse,
        response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {'message': e.toString()}),
      ));
    }
  }

  Future<dynamic> _handle(
      String method, String path, Map<String, dynamic> data) async {

    // ── Auth ──────────────────────────────────────────────
    if (path == '/auth/login') {
      return MockService.login(
        identifier: data['identifier'] as String? ?? '',
        password: data['password'] as String? ?? '',
      );
    }
    if (path == '/auth/register') {
      return MockService.register(
        prenom: data['prenom'] as String? ?? '',
        nom: data['nom'] as String? ?? '',
        password: data['password'] as String? ?? '',
        phone: data['phone'] as String?,
        email: data['email'] as String?,
      );
    }
    if (path == '/auth/verify-otp') {
      return MockService.verifyOtp(
        identifier: data['identifier'] as String? ?? '',
        code: data['code'] as String? ?? '',
      );
    }
    if (path == '/auth/resend-otp') {
      return MockService.resendOtp(
        identifier: data['identifier'] as String? ?? '',
      );
    }
    if (path == '/auth/me') return MockService.getMe();

    // ── Certificats ───────────────────────────────────────
    if (path == '/certificates/submit') {
      return MockService.submitCertificate(data);
    }

    // ── Dossiers ──────────────────────────────────────────
    if (path == '/dossiers' && method == 'GET') {
      return MockService.getDossiers();
    }
    if (path.startsWith('/dossiers/') && method == 'GET') {
      return MockService.getDossierById(
          path.replaceFirst('/dossiers/', ''));
    }

    // ── Paiement ──────────────────────────────────────────
    if (path == '/payment/initiate') {
      return MockService.initiatePayment(
        dossierId: data['dossier_id'] as String? ?? '',
        method: data['method'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
      );
    }

    // ── Profil ────────────────────────────────────────────
    if (path == '/profile/update') return MockService.updateProfile(data);
    if (path == '/profile/change-pin') {
      await MockService.changePin(
        oldPinHash: data['old_pin_hash'] as String? ?? '',
        newPin: data['new_pin'] as String? ?? '',
      );
      return {'success': true};
    }

    // ── Assistant ─────────────────────────────────────────
    if (path == '/assistant/chat') {
      return MockService.sendAssistantMessage(
        message: data['message'] as String? ?? '',
        language: data['language'] as String? ?? 'fr',
      );
    }

    // ── Téléchargement certificat ─────────────────────────
    if (path.contains('/download') && method == 'GET') {
      final dossierId = path.split('/')[2];
      return MockService.downloadCertificate(dossierId);
    }

    // ── OCR ──────────────────────────────────────────────
    if (path == '/ocr/extract-naissance') {
      return MockService.extractNaissanceOcr();
    }

    debugPrint('[MOCK] Route non gérée: $method $path');
    return {'success': true};
  }
}
