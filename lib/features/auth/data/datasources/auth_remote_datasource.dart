// ============================================================================
// FILE: lib/features/auth/data/datasources/auth_remote_datasource.dart
// PURPOSE: Network access layer for authentication.
// - Performs login against Odoo `/web/session/authenticate`.
// - Extracts `session_id` from `Set-Cookie` header for subsequent requests.
// - Maps the `result` payload into a domain `User` via `UserModel`.
// - Provides logout endpoint to destroy the server session.
// ============================================================================
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../models/user_model.dart';
import '../../domain/entities/user.dart';

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource(this.apiClient);

  /// Perform login with credentials and database.
  ///
  /// Returns a tuple containing:
  /// - `user`: The authenticated domain user model
  /// - `sessionId`: The extracted session cookie value used for auth
  ///
  /// Throws [ServerException] for server-side errors and invalid credentials,
  /// and [NetworkException] for connectivity issues/timeouts.
  Future<({User user, String sessionId})> login({
    required String username,
    required String password,
    required String database,
  }) async {
    try {
      final response = await apiClient.post(
        '/web/session/authenticate',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {'db': database, 'login': username, 'password': password},
        },
      );

      if (response.statusCode == 200) {
        final result = response.data['result'];

        if (result == null || result['uid'] == false || result['uid'] == null) {
          throw ServerException('Invalid credentials');
        }

        if (kDebugMode) {
          try {
            debugPrint('auth result keys: ${result.keys.toList()}');
            debugPrint('auth result.group: ${result['group']}');
          } catch (_) {}
        }

        // Extract session from cookies in `Set-Cookie: session_id=<val>; ...`
        final cookies = response.headers['set-cookie'];
        String? sessionId;

        if (cookies != null) {
          for (var cookie in cookies) {
            if (cookie.contains('session_id=')) {
              sessionId = cookie.split('session_id=')[1].split(';')[0];
              break;
            }
          }
        }

        if (sessionId == null) {
          throw ServerException('No session ID received');
        }

        if (kDebugMode) {
          final sidPreview = (sessionId.length > 10)
              ? '${sessionId.substring(0, 10)}...'
              : sessionId;
          debugPrint('session_id: $sidPreview');
        }

        final user = UserModel.fromJson(result);
        return (user: user, sessionId: sessionId);
      }

      throw ServerException('Login failed with status: ${response.statusCode}');
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

  /// Destroy the server-side session. Errors are intentionally swallowed
  /// because logout should be best-effort and not block local state clearing.
  Future<void> logout() async {
    try {
      await apiClient.post(
        '/web/session/destroy',
        data: {'jsonrpc': '2.0', 'method': 'call', 'params': {}},
      );
    } catch (e) {
      // Ignore logout errors
    }
  }
}
