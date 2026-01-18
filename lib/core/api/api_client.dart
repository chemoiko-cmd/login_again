import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_interceptor.dart';

class ApiClient {
  final Dio dio;
  final String baseUrl;

  ApiClient({this.baseUrl = 'http://rental.kolapro.com'})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  void setAuthInterceptor(AuthInterceptor interceptor) {
    dio.interceptors.add(interceptor);
  }

  Future<Response> post(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    if (kDebugMode) {
      try {
        final url = '${baseUrl}${path}';
        final body = data.toString();
        final preview = body.length > 200 ? body.substring(0, 200) + '…' : body;
        debugPrint('HTTP POST -> ' + url);
        debugPrint(
          'Headers: ' + _sanitizeHeaders(dio.options.headers).toString(),
        );
        debugPrint('Body: ' + preview);
      } catch (_) {}
    }
    final response = await dio.post(path, data: data);
    if (kDebugMode) {
      try {
        debugPrint('← POST status: ${response.statusCode}');
        final respHeaders = response.headers.map.map(
          (k, v) => MapEntry(k, v.join('; ')),
        );
        debugPrint(
          '← POST headers: ' + _sanitizeHeaders(respHeaders).toString(),
        );
      } catch (_) {}
    }
    return response;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    if (kDebugMode) {
      try {
        final url = '${baseUrl}${path}';
        final qp = (queryParams ?? {}).toString();
        debugPrint(
          'HTTP GET  -> ' + url + (queryParams == null ? '' : ' ? ' + qp),
        );
        debugPrint(
          'Headers: ' + _sanitizeHeaders(dio.options.headers).toString(),
        );
      } catch (_) {}
    }
    final response = await dio.get(path, queryParameters: queryParams);
    if (kDebugMode) {
      try {
        debugPrint('← GET  status: ${response.statusCode}');
        final respHeaders = response.headers.map.map(
          (k, v) => MapEntry(k, v.join('; ')),
        );
        debugPrint(
          '← GET  headers: ' + _sanitizeHeaders(respHeaders).toString(),
        );
      } catch (_) {}
    }
    return response;
  }

  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final map = Map<String, dynamic>.from(headers);
    void mask(String k) {
      if (map.containsKey(k)) map[k] = '<hidden>';
    }

    mask('Cookie');
    mask('cookie');
    mask('Authorization');
    mask('authorization');
    return map;
  }
}
