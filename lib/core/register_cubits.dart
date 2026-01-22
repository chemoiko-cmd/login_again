import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';

import '../core/api/api_client.dart';
import '../core/currency/currency_cubit.dart';
import '../core/currency/currency_repository.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/landlord/data/repositories/landlord_repository.dart';
import '../features/landlord/presentation/cubit/inspections_cubit.dart';
import '../features/landlord/presentation/cubit/maintenance_tasks_cubit.dart';
import '../features/landlord/presentation/cubit/metrics_cubit.dart';
import '../features/landlord/presentation/cubit/tenants_cubit.dart';
import '../features/maintenance2/data/repositories/maintenance_repository.dart'
    as maintenance2_repo;
import '../features/maintainer/data/maintainer_repository.dart';
import '../features/maintainer/presentation/cubit/maintainer_tasks_cubit.dart';
import '../features/maintainer/presentation/cubit/maintainer_inspections_cubit.dart';
import '../features/maintenance2/presentation/cubit/maintenance_cubit.dart';
import '../features/payments/data/payments_repository.dart';
import '../features/payments/presentation/cubit/payments_cubit.dart';
import '../features/tenant/data/tenant_repository.dart';
import '../features/tenant/presentation/cubit/tenant_dashboard_cubit.dart';

class RegisterCubits {
  final ApiClient apiClient;
  final AuthRepositoryImpl authRepository;

  RegisterCubits({required this.apiClient, required this.authRepository});

  List<SingleChildWidget> register() {
    final landlordRepo = LandlordRepository(apiClient: apiClient);
    final maintainerRepo = MaintainerRepository(apiClient: apiClient);
    return [
      BlocProvider<AuthCubit>(
        create: (_) => AuthCubit(authRepository, apiClient),
      ),
      BlocProvider<CurrencyCubit>(
        create: (context) => CurrencyCubit(
          repo: CurrencyRepository(
            apiClient: apiClient,
            authCubit: context.read<AuthCubit>(),
          ),
        ),
      ),
      BlocProvider<TenantDashboardCubit>(
        create: (context) => TenantDashboardCubit(
          repo: TenantRepository(
            apiClient: apiClient,
            authCubit: context.read<AuthCubit>(),
          ),
        ),
      ),
      BlocProvider<PaymentsCubit>(
        create: (context) => PaymentsCubit(
          repo: PaymentsRepository(
            apiClient: apiClient,
            authCubit: context.read<AuthCubit>(),
          ),
        ),
      ),
      BlocProvider<InspectionsCubit>(
        create: (_) => InspectionsCubit(landlordRepo),
      ),
      BlocProvider<MaintenanceTasksCubit>(
        create: (_) => MaintenanceTasksCubit(landlordRepo),
      ),
      BlocProvider<TenantsCubit>(create: (_) => TenantsCubit(landlordRepo)),
      BlocProvider<MetricsCubit>(create: (_) => MetricsCubit(landlordRepo)),
      BlocProvider<MaintenanceCubit>(
        create: (_) => MaintenanceCubit(
          maintenance2_repo.MaintenanceRepository(apiClient: apiClient),
        ),
      ),
      BlocProvider<MaintainerTasksCubit>(
        create: (_) => MaintainerTasksCubit(maintainerRepo),
      ),
      BlocProvider<MaintainerInspectionsCubit>(
        create: (_) => MaintainerInspectionsCubit(maintainerRepo),
      ),
    ];
  }
}
