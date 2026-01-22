// ============================================================================
// FILE: lib/features/auth/data/services/password_reset_service.dart
// PURPOSE: Service for handling password reset requests
// ============================================================================
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class PasswordResetService {
  final ApiClient apiClient;

  PasswordResetService(this.apiClient);

  Future<Map<String, dynamic>> requestPasswordResetOtp({
    required String login,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/delivery/password-reset/request-otp',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {'email': login},
        },
      );

      final responseData = response.data;
      final result = responseData['result'];

      if (result is Map && result['success'] == true) {
        return Map<String, dynamic>.from(result);
      }
      throw Exception(
        (result is Map ? result['error'] : null) ?? 'Failed to request OTP',
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          final errorData = e.response!.data;
          if (errorData is Map && errorData['message'] != null) {
            throw Exception(errorData['message']);
          } else if (errorData is Map && errorData['error'] != null) {
            final errorMessage =
                errorData['error']['data']?['message'] ??
                errorData['error']['message'] ??
                'Server error occurred';
            throw Exception(errorMessage);
          }
        } catch (e) {
          if (e is Exception) rethrow;
        }
      }

      throw Exception('Could not request OTP');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> verifyPasswordResetOtp({
    required String login,
    required String otp,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/delivery/password-reset/verify-otp',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {'email': login, 'otp': otp},
        },
      );

      final responseData = response.data;
      final result = responseData['result'];

      if (result is Map && result['success'] == true) {
        return Map<String, dynamic>.from(result);
      }
      throw Exception(
        (result is Map ? result['error'] : null) ?? 'Failed to verify OTP',
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          final errorData = e.response!.data;
          if (errorData is Map && errorData['message'] != null) {
            throw Exception(errorData['message']);
          } else if (errorData is Map && errorData['error'] != null) {
            final errorMessage =
                errorData['error']['data']?['message'] ??
                errorData['error']['message'] ??
                'Server error occurred';
            throw Exception(errorMessage);
          }
        } catch (e) {
          if (e is Exception) rethrow;
        }
      }

      throw Exception('Could not verify OTP');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithToken({
    required String login,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/delivery/password-reset/reset-password',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'email': login,
            'reset_token': resetToken,
            'new_password': newPassword,
          },
        },
      );

      final responseData = response.data;
      final result = responseData['result'];

      if (result is Map && result['success'] == true) {
        return Map<String, dynamic>.from(result);
      }
      throw Exception(
        (result is Map ? result['error'] : null) ?? 'Failed to reset password',
      );
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          final errorData = e.response!.data;
          if (errorData is Map && errorData['message'] != null) {
            throw Exception(errorData['message']);
          } else if (errorData is Map && errorData['error'] != null) {
            final errorMessage =
                errorData['error']['data']?['message'] ??
                errorData['error']['message'] ??
                'Server error occurred';
            throw Exception(errorMessage);
          }
        } catch (e) {
          if (e is Exception) rethrow;
        }
      }

      throw Exception('Could not reset password');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Sends password reset request to backend
  /// Returns success message on success
  /// Throws exception with error message on failure
  Future<String> resetPassword(String email) async {
    try {
      final response = await apiClient.post(
        '/api/reset_password',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {'login': email},
        },
      );

      final responseData = response.data;
      final result = responseData['result'];

      if (result['success'] == true) {
        return result['message'] ??
            'Password reset instructions have been sent';
      } else {
        throw Exception(result['message'] ?? 'Failed to send reset email');
      }
    } on DioException catch (e) {
      // Try to get backend error message
      if (e.response?.data != null) {
        try {
          final errorData = e.response!.data;
          if (errorData is Map && errorData['message'] != null) {
            throw Exception(errorData['message']);
          } else if (errorData is Map && errorData['error'] != null) {
            final errorMessage =
                errorData['error']['data']?['message'] ??
                errorData['error']['message'] ??
                'Server error occurred';
            throw Exception(errorMessage);
          }
        } catch (e) {
          if (e is Exception) rethrow;
        }
      }

      if (e.response?.statusCode == 404) {
        throw Exception('Password reset endpoint not found');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error occurred');
      }

      throw Exception('Could not send reset email');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }
}
