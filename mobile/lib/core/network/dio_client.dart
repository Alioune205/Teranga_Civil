import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../mock/mock_config.dart';
import 'network_interceptor.dart';
import 'mock_interceptor.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  const storage = FlutterSecureStorage();
  return DioClient(storage: storage);
});

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage storage;

  DioClient({required this.storage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiConnectTimeout,
        receiveTimeout: AppConstants.apiReceiveTimeout,
        sendTimeout: AppConstants.apiSendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Version': AppConstants.appVersion,
          'X-Platform': 'mobile',
          // Connexion réelle vers 10.0.2.2, mais on présente `localhost` à Django
          // pour passer la validation ALLOWED_HOSTS sans toucher au backend.
          if (!kIsWeb) 'Host': AppConstants.apiHostHeader,
        },
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (kMockMode) {
      // En mode mock : intercepteur qui retourne des données locales
      _dio.interceptors.add(MockInterceptor());
      debugPrint('[MOCK] Mode mock activé — aucun serveur requis');
    } else {
      // En mode production : vrai intercepteur JWT
      _dio.interceptors.add(NetworkInterceptor(storage: storage, dio: _dio));
    }
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) =>
      _dio.get<T>(path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response<T>> post<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) =>
      _dio.post<T>(path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response<T>> put<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) =>
      _dio.put<T>(path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response<T>> patch<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) =>
      _dio.patch<T>(path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response<T>> delete<T>(String path,
      {dynamic data,
      Options? options,
      CancelToken? cancelToken}) =>
      _dio.delete<T>(path,
          data: data,
          options: options,
          cancelToken: cancelToken);

  Future<Response> download(String path, String savePath,
      {ProgressCallback? onReceiveProgress, CancelToken? cancelToken}) =>
      _dio.download(path, savePath,
          onReceiveProgress: onReceiveProgress,
          cancelToken: cancelToken,
          options: Options(responseType: ResponseType.bytes));
}
