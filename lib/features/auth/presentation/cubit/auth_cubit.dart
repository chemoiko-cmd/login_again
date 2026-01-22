// ============================================================================
// FILE: lib/features/auth/presentation/cubit/auth_cubit.dart
// ============================================================================
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_interceptor.dart';
import '../../../../core/storage/auth_local_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'auth_state.dart';
import '../../data/models/user_model.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepositoryImpl authRepository;
  final ApiClient apiClient;
  late final AuthInterceptor _authInterceptor;
  final AuthLocalStorage _storage = AuthLocalStorage();

  AuthCubit(this.authRepository, this.apiClient) : super(AuthInitial()) {
    _authInterceptor = AuthInterceptor(onSessionExpired: _handleSessionExpired);
    apiClient.setAuthInterceptor(_authInterceptor);
  }

  Future<void> restoreSession() async {
    // Avoid running multiple times.
    if (state is AuthChecking) return;
    emit(AuthChecking());

    try {
      final sessionId = await _storage.getSessionId();
      final cachedUserJson = await _storage.getUserJson();
      if (sessionId == null || sessionId.isEmpty || cachedUserJson == null) {
        emit(Unauthenticated());
        return;
      }

      _authInterceptor.setSession(sessionId);

      // Validate session with Odoo. If invalid, Odoo returns uid=false or errors.
      final resp = await apiClient.post(
        '/web/session/get_session_info',
        data: {'jsonrpc': '2.0', 'method': 'call', 'params': {}},
      );
      final result = (resp.data is Map) ? resp.data['result'] : null;
      final uid = (result is Map) ? result['uid'] : null;
      if (uid == null || uid == false) {
        await _storage.clearAll();
        _authInterceptor.clearSession();
        emit(Unauthenticated());
        return;
      }

      // Use cached user snapshot for routing roles and basic identity.
      final user = UserModel.fromJson(cachedUserJson);

      emit(
        Authenticated(
          user,
          isTenant: user.isTenant,
          isLandlord: user.isLandlord,
          isMaintenance: user.isMaintenance,
        ),
      );
    } on DioException catch (_) {
      // Network failure: fall back to cached auth state to avoid locking user out.
      final cachedUserJson = await _storage.getUserJson();
      final sessionId = await _storage.getSessionId();
      if (sessionId != null && sessionId.isNotEmpty && cachedUserJson != null) {
        _authInterceptor.setSession(sessionId);
        final user = UserModel.fromJson(cachedUserJson);
        emit(
          Authenticated(
            user,
            isTenant: user.isTenant,
            isLandlord: user.isLandlord,
            isMaintenance: user.isMaintenance,
          ),
        );
        return;
      }
      emit(Unauthenticated());
    } catch (_) {
      emit(Unauthenticated());
    }
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
        await _storage.saveSession(sessionId: data.sessionId);
        final sidPreview = data.sessionId.length > 10
            ? '${data.sessionId.substring(0, 10)}...'
            : data.sessionId;
        print(
          'Authenticated: id=${data.user.id}, name=${data.user.name}, group=${data.user.primaryGroup}, session=$sidPreview',
        );

        bool isTenant = false;
        bool isLandlord = false;
        bool isMaintenance = false;
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

        // Maintenance group check
        try {
          final maintPayload = {
            'jsonrpc': '2.0',
            'method': 'call',
            'params': {
              'model': 'res.users',
              'method': 'has_group',
              'args': [
                [data.user.id],
                'rental_management.group_rental_maintenance',
              ],
              'kwargs': {},
            },
            'id': 3,
          };
          final maintResp = await apiClient.post(
            '/web/dataset/call_kw',
            data: maintPayload,
          );
          final maintBody = maintResp.data;
          isMaintenance = (maintBody is Map && maintBody['result'] is bool)
              ? maintBody['result'] as bool
              : false;
          print('has_group(maintenance) => $isMaintenance');
        } on DioException catch (e, st) {
          print(st.toString());
          print('has_group maintenance check failed: ${e.message}');
        } catch (e, st) {
          print(st.toString());
          print('has_group maintenance check failed: $e');
        }

        print(
          'Emitting Authenticated: id=${data.user.id}, tenant=$isTenant, landlord=$isLandlord',
        );

        emit(
          Authenticated(
            data.user,
            isTenant: isTenant,
            isLandlord: isLandlord,
            isMaintenance: isMaintenance,
          ),
        );

        // Persist an updated snapshot with computed routing role.
        // Note: We store the minimal user json shape used by UserModel.
        final toStore = UserModel.fromJson({
          'uid': data.user.id,
          'name': data.user.name,
          'username': data.user.username,
          'partner_id': data.user.partnerId,
          'partner_display_name': data.user.partnerDisplayName,
          'is_internal_user': data.user.isInternalUser,
          'is_admin': data.user.isAdmin,
          'db': data.user.database,
          'group': data.user.primaryGroup,
          'user_context': data.user.userContext,
        }).toJson();
        await _storage.saveUserJson(toStore);
      },
    );
  }

  Future<void> logout() async {
    await authRepository.logout();
    _authInterceptor.clearSession();
    await _storage.clearAll();
    emit(Unauthenticated());
  }

  void _handleSessionExpired() {
    _storage.clearAll();
    emit(Unauthenticated());
  }
}
