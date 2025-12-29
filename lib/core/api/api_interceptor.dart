import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final Function() onSessionExpired;
  String? _sessionId;

  AuthInterceptor({required this.onSessionExpired});

  void setSession(String sessionId) {
    _sessionId = sessionId;
  }

  void clearSession() {
    _sessionId = null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_sessionId != null) {
      options.headers['Cookie'] = 'session_id=$_sessionId';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      clearSession();
      onSessionExpired();
    }
    handler.next(err);
  }
}
