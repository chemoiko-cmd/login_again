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
      final tokenLen = accessToken.length;
      print(
        'GoogleRegisterRemoteDataSource.registerWithGoogle -> db=$database tokenLen=$tokenLen',
      );

      final response = await apiClient.post(
        '/api/mobile/auth/register_google',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {'db': database, 'access_token': accessToken},
        },
      );

      print(
        'register_google -> status=${response.statusCode} hasData=${response.data != null}',
      );

      if (response.statusCode != 200) {
        print('register_google -> non-200 response: ${response.data}');
        throw ServerException(
          'Google registration failed with status: ${response.statusCode}',
        );
      }

      final rpcResult = response.data['result'];
      print(
        'register_google -> rpcResultType=${rpcResult.runtimeType} topKeys=${(response.data is Map) ? (response.data as Map).keys.toList() : 'n/a'}',
      );
      if (rpcResult is! Map) {
        print('register_google -> invalid rpcResult: $rpcResult');
        throw ServerException('Invalid server response');
      }

      final ok = rpcResult['success'] == true;
      print('register_google -> success=$ok error=${rpcResult['error']}');
      if (!ok) {
        throw ServerException(
          (rpcResult['error'] ?? 'Google registration failed').toString(),
        );
      }

      final sessionInfo = rpcResult['result'];
      print(
        'register_google -> sessionInfoType=${sessionInfo.runtimeType} uid=${(sessionInfo is Map) ? sessionInfo['uid'] : 'n/a'}',
      );
      if (sessionInfo is! Map ||
          sessionInfo['uid'] == null ||
          sessionInfo['uid'] == false) {
        throw ServerException('Google registration failed');
      }

      final cookies = response.headers['set-cookie'];
      print('register_google -> set-cookie count=${cookies?.length ?? 0}');
      String? sessionId;
      if (cookies != null) {
        for (final cookie in cookies) {
          if (cookie.contains('session_id=')) {
            sessionId = cookie.split('session_id=')[1].split(';')[0];
            break;
          }
        }
      }

      print(
        'register_google -> sessionIdPresent=${sessionId != null && sessionId.isNotEmpty}',
      );

      if (sessionId == null || sessionId.isEmpty) {
        throw ServerException('No session ID received');
      }

      final user = UserModel.fromJson(Map<String, dynamic>.from(sessionInfo));
      return (user: user, sessionId: sessionId);
    } on DioException catch (e) {
      print(
        'register_google -> DioException type=${e.type} message=${e.message} code=${e.response?.statusCode}',
      );
      if (e.response?.data != null) {
        print('register_google -> error response data: ${e.response?.data}');
      }
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
