import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

class GoogleRegisterRemoteDataSource {
  final ApiClient apiClient;

  GoogleRegisterRemoteDataSource(this.apiClient);

  Future<({User user, String sessionId})> registerWithGoogle({
    required String database,
    required String accessToken,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/mobile/auth/register_google',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {'db': database, 'access_token': accessToken},
        },
      );

      if (response.statusCode != 200) {
        throw ServerException(
          'Google registration failed with status: ${response.statusCode}',
        );
      }

      final rpcResult = response.data['result'];
      if (rpcResult is! Map) {
        throw ServerException('Invalid server response');
      }

      final ok = rpcResult['success'] == true;
      if (!ok) {
        throw ServerException(
          (rpcResult['error'] ?? 'Google registration failed').toString(),
        );
      }

      final sessionInfo = rpcResult['result'];
      if (sessionInfo is! Map ||
          sessionInfo['uid'] == null ||
          sessionInfo['uid'] == false) {
        throw ServerException('Google registration failed');
      }

      final cookies = response.headers['set-cookie'];
      String? sessionId;
      if (cookies != null) {
        for (final cookie in cookies) {
          if (cookie.contains('session_id=')) {
            sessionId = cookie.split('session_id=')[1].split(';')[0];
            break;
          }
        }
      }

      if (sessionId == null || sessionId.isEmpty) {
        throw ServerException('No session ID received');
      }

      final user = UserModel.fromJson(Map<String, dynamic>.from(sessionInfo));
      return (user: user, sessionId: sessionId);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection $e');
      }
      throw ServerException(e.message ?? 'Unknown error');
    }
  }
}
