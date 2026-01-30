// ============================================================================
// FILE: lib/features/auth/presentation/cubit/auth_cubit.dart
// ============================================================================
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/features/auth/data/datasources/auth_remote_datasource.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_interceptor.dart';
import '../../../../core/storage/auth_local_storage.dart';
import '../../data/datasources/google_auth_remote_datasource.dart';
import '../../data/datasources/google_register_remote_datasource.dart';
import '../../data/datasources/register_remote_datasource.dart';
import '../../data/services/google_sign_in_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'auth_state.dart';
import '../../data/models/user_model.dart';
import '../../../profile/data/profile_repository.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepositoryImpl authRepository;
  final ApiClient apiClient;
  late final AuthInterceptor _authInterceptor;
  final AuthLocalStorage _storage = AuthLocalStorage();
  late final GoogleAuthRemoteDataSource _googleAuthRemote;
  late final GoogleRegisterRemoteDataSource _googleRegisterRemote;
  late final RegisterRemoteDataSource _registerRemote;
  final GoogleSignInService _googleSignInService = GoogleSignInService();

  AuthCubit(this.authRepository, this.apiClient) : super(AuthInitial()) {
    _authInterceptor = AuthInterceptor(onSessionExpired: _handleSessionExpired);
    apiClient.setAuthInterceptor(_authInterceptor);
    _googleAuthRemote = GoogleAuthRemoteDataSource(apiClient);
    _googleRegisterRemote = GoogleRegisterRemoteDataSource(apiClient);
    _registerRemote = RegisterRemoteDataSource(apiClient);
  }

  Future<void> loginWithGoogle({required String database}) async {
    emit(AuthLoading());
    try {
      final accessToken = await _googleSignInService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        emit(const AuthError('Google sign-in cancelled'));
        return;
      }

      final data = await _googleAuthRemote.loginWithGoogle(
        database: database,
        accessToken: accessToken,
      );

      await _completeLogin(user: data.user, sessionId: data.sessionId);
    } on ServerException catch (e) {
      emit(AuthError(e.message));
    } on NetworkException catch (e) {
      emit(AuthError(e.message));
    } on Exception catch (e) {
      emit(AuthError(e.toString()));
    } catch (e) {
      emit(AuthError('Unexpected error: $e'));
    }
  }

  Future<void> registerWithGoogle({required String database}) async {
    emit(AuthLoading());
    try {
      final accessToken = await _googleSignInService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        emit(const AuthError('Google sign-up cancelled'));
        return;
      }

      final data = await _googleRegisterRemote.registerWithGoogle(
        database: database,
        accessToken: accessToken,
      );

      await _completeLogin(user: data.user, sessionId: data.sessionId);
    } on ServerException catch (e) {
      emit(AuthError(e.message));
    } on NetworkException catch (e) {
      emit(AuthError(e.message));
    } on Exception catch (e) {
      emit(AuthError(e.toString()));
    } catch (e) {
      emit(AuthError('Unexpected error: $e'));
    }
  }

  Future<void> registerLandlord({
    required String database,
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final data = await _registerRemote.registerLandlord(
        database: database,
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      await _completeLogin(user: data.user, sessionId: data.sessionId);
    } on ServerException catch (e) {
      emit(AuthError(e.message));
    } on NetworkException catch (e) {
      emit(AuthError(e.message));
    } on Exception catch (e) {
      emit(AuthError(e.toString()));
    } catch (e) {
      emit(AuthError('Unexpected error: $e'));
    }
  }

  Future<void> _completeLogin({
    required dynamic user,
    required String sessionId,
  }) async {
    _authInterceptor.setSession(sessionId);
    await _storage.saveSession(sessionId: sessionId);
    final sidPreview = sessionId.length > 10
        ? '${sessionId.substring(0, 10)}...'
        : sessionId;
    try {
      // user is a domain User but we persist via UserModel shape later.
      // Keep log best-effort.
      // ignore: avoid_print
      print(
        'Authenticated: id=${user.id}, name=${user.name}, group=${user.primaryGroup}, session=$sidPreview',
      );
    } catch (_) {}

    bool isTenant = false;
    bool isLandlord = false;
    bool isMaintenance = false;
    final isInternalUser = user.isInternalUser;

    try {
      final tenantPayload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': 'res.users',
          'method': 'has_group',
          'args': [
            [user.id],
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
      final inTenantGroup = (tenantBody is Map && tenantBody['result'] is bool)
          ? tenantBody['result'] as bool
          : false;
      isTenant = inTenantGroup || !isInternalUser;
    } catch (_) {}

    try {
      final landlordPayload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': 'res.users',
          'method': 'has_group',
          'args': [
            [user.id],
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
    } catch (_) {}

    try {
      final maintPayload = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': 'res.users',
          'method': 'has_group',
          'args': [
            [user.id],
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
    } catch (_) {}

    emit(
      Authenticated(
        user,
        isTenant: isTenant,
        isLandlord: isLandlord,
        isMaintenance: isMaintenance,
      ),
    );

    final toStore = UserModel.fromJson({
      'uid': user.id,
      'name': user.name,
      'username': '',
      'partner_id': user.partnerId,
      'partner_display_name': user.partnerDisplayName,
      'is_internal_user': user.isInternalUser,
      'is_admin': user.isAdmin,
      'db': user.database,
      'group': user.primaryGroup,
      'user_context': user.userContext,
    }).toJson();
    await _storage.saveUserJson(toStore);

    // Cache avatar once (eBroker-style) so we don't re-query the API on each build.
    // Best-effort: failures should not affect login flow.
    try {
      final pid = user.partnerId as int?;
      if (pid != null && pid > 0) {
        final existing = await _storage.getPartnerAvatarBase64(pid);
        if (existing == null || existing.isEmpty) {
          final repo = ProfileRepository(apiClient: apiClient);
          final profile = await repo.fetchPartnerProfile(partnerId: pid);
          final bytes = profile?.imageBytes;
          if (bytes != null && bytes.isNotEmpty) {
            await _storage.savePartnerAvatarBase64(
              partnerId: pid,
              base64: base64Encode(bytes),
            );
          }
        }
      }
    } catch (_) {}
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

      // Trust local snapshot (eBroker-style). If the session is actually expired,
      // subsequent requests will fail with 401 and trigger logout via interceptor.
      final user = UserModel.fromJson(cachedUserJson);

      emit(
        Authenticated(
          user,
          isTenant: user.isTenant,
          isLandlord: user.isLandlord,
          isMaintenance: user.isMaintenance,
        ),
      );
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
        await _completeLogin(user: data.user, sessionId: data.sessionId);
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
