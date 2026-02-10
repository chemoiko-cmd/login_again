import 'package:dio/dio.dart';
import 'api_interceptor.dart';

class ApiClient {
  final Dio dio;
  final String baseUrl;

  ApiClient({this.baseUrl = 'http://192.168.1.3:8069'})
    // http://192.168.1.7:8069  https://rental.kolapro.com
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
    try {
      final url = '${baseUrl}${path}';
      final body = data.toString();
      final preview = body.length > 200 ? body.substring(0, 200) + '…' : body;
      print('HTTP POST -> ' + url);
      print('Headers: ' + _sanitizeHeaders(dio.options.headers).toString());
      print('Body: ' + preview);
    } catch (_) {}
    final response = await dio.post(path, data: data);
    try {
      print('← POST status: ${response.statusCode}');
      final respHeaders = response.headers.map.map(
        (k, v) => MapEntry(k, v.join('; ')),
      );
      print('← POST headers: ' + _sanitizeHeaders(respHeaders).toString());
      try {
        final body = response.data.toString();
        final preview = body.length > 400 ? body.substring(0, 400) + '…' : body;
        print('← POST body: ' + preview);
      } catch (_) {}
    } catch (_) {}
    return response;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final url = '${baseUrl}${path}';
      final qp = (queryParams ?? {}).toString();
      print('HTTP GET  -> ' + url + (queryParams == null ? '' : ' ? ' + qp));
      print('Headers: ' + _sanitizeHeaders(dio.options.headers).toString());
    } catch (_) {}
    final response = await dio.get(path, queryParameters: queryParams);
    try {
      print('← GET  status: ${response.statusCode}');
      final respHeaders = response.headers.map.map(
        (k, v) => MapEntry(k, v.join('; ')),
      );
      print('← GET  headers: ' + _sanitizeHeaders(respHeaders).toString());
      try {
        final body = response.data.toString();
        final preview = body.length > 400 ? body.substring(0, 400) + '…' : body;
        print('← GET  body: ' + preview);
      } catch (_) {}
    } catch (_) {}
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
