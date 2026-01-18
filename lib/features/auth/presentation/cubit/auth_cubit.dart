// ============================================================================
// FILE: lib/features/auth/presentation/cubit/auth_cubit.dart
// ============================================================================
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_interceptor.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepositoryImpl authRepository;
  final ApiClient apiClient;
  late final AuthInterceptor _authInterceptor;

  AuthCubit(this.authRepository, this.apiClient) : super(AuthInitial()) {
    _authInterceptor = AuthInterceptor(onSessionExpired: _handleSessionExpired);
    apiClient.setAuthInterceptor(_authInterceptor);
  }

  Future<void> login({
    required String username,
    required String password,
    required String database,
  }) async {
    emit(AuthLoading());

    final result = await authRepository.login(
      username: username,
      password: password,
      database: database,
    );

    await result.fold<Future<void>>(
      (failure) async {
        print('Login failed: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (data) async {
        _authInterceptor.setSession(data.sessionId);
        final sidPreview = data.sessionId.length > 10
            ? '${data.sessionId.substring(0, 10)}...'
            : data.sessionId;
        print(
          'Authenticated: id=${data.user.id}, name=${data.user.name}, group=${data.user.primaryGroup}, session=$sidPreview',
        );

        bool isTenant = false;
        bool isLandlord = false;
        final isInternalUser = data.user.isInternalUser;
        try {
          final tenantPayload = {
            'jsonrpc': '2.0',
            'method': 'call',
            'params': {
              'model': 'res.users',
              'method': 'has_group',
              'args': [
                [data.user.id],
                'rental_management.group_rental_tenant',
              ],
              'kwargs': {},
            },
            'id': 1,
          };
          final tenantResp = await apiClient.post(
            '/web/dataset/call_kw',
            data: tenantPayload,
          );
          final tenantBody = tenantResp.data;
          final inTenantGroup =
              (tenantBody is Map && tenantBody['result'] is bool)
              ? tenantBody['result'] as bool
              : false;
          isTenant = inTenantGroup || !isInternalUser;
          print(
            'has_group(tenant) => $inTenantGroup | is_internal_user=$isInternalUser | isTenant=$isTenant',
          );
        } on DioException catch (e, st) {
          print(st.toString());
          print('has_group tenant check failed: ${e.message}');
        } catch (e, st) {
          print(st.toString());
          print('has_group tenant check failed: $e');
        }

        try {
          final landlordPayload = {
            'jsonrpc': '2.0',
            'method': 'call',
            'params': {
              'model': 'res.users',
              'method': 'has_group',
              'args': [
                [data.user.id],
                'rental_management.group_rental_landlord',
              ],
              'kwargs': {},
            },
            'id': 2,
          };
          final landlordResp = await apiClient.post(
            '/web/dataset/call_kw',
            data: landlordPayload,
          );
          final landlordBody = landlordResp.data;
          isLandlord = (landlordBody is Map && landlordBody['result'] is bool)
              ? landlordBody['result'] as bool
              : false;
          print('has_group(landlord) => $isLandlord');
        } on DioException catch (e, st) {
          print(st.toString());
          print('has_group landlord check failed: ${e.message}');
        } catch (e, st) {
          print(st.toString());
          print('has_group landlord check failed: $e');
        }

        print(
          'Emitting Authenticated: id=${data.user.id}, tenant=$isTenant, landlord=$isLandlord',
        );

        emit(
          Authenticated(data.user, isTenant: isTenant, isLandlord: isLandlord),
        );
      },
    );
  }

  Future<void> logout() async {
    await authRepository.logout();
    _authInterceptor.clearSession();
    emit(Unauthenticated());
  }

  void _handleSessionExpired() {
    emit(Unauthenticated());
  }
}
