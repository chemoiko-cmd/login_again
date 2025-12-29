// ============================================================================
// FILE: lib/features/auth/data/repositories/auth_repository_impl.dart
// ============================================================================
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, ({User user, String sessionId})>> login({
    required String username,
    required String password,
    required String database,
  }) async {
    try {
      final result = await remoteDataSource.login(
        username: username,
        password: password,
        database: database,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
  }
}
