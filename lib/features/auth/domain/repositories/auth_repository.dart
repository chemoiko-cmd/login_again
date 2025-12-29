// ============================================================================
// FILE: lib/features/auth/domain/repositories/auth_repository.dart
// ============================================================================
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, ({User user, String sessionId})>> login({
    required String username,
    required String password,
    required String database,
  });

  Future<void> logout();
}
