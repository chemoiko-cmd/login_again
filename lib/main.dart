// ============================================================================
// COMPLETE PROJECT STRUCTURE - COPY EACH FILE SEPARATELY
// ============================================================================

// ============================================================================
// FILE: lib/main.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/api/api_client.dart';
import 'core/routes/app_router.dart';
import 'core/currency/currency_repository.dart';
import 'core/currency/currency_cubit.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';

void main() {
  // TODO: Replace with your actual Odoo server URL
  final apiClient = ApiClient(baseUrl: 'http://192.168.1.4:8069');
  final authDataSource = AuthRemoteDataSource(apiClient);
  final authRepository = AuthRepositoryImpl(authDataSource);

  runApp(MyApp(authRepository: authRepository, apiClient: apiClient));
}

class MyApp extends StatelessWidget {
  final AuthRepositoryImpl authRepository;
  final ApiClient apiClient;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.apiClient,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(authRepository, apiClient),
        ),
        BlocProvider<CurrencyCubit>(
          create: (context) => CurrencyCubit(
            repo: CurrencyRepository(
              apiClient: apiClient,
              authCubit: context.read<AuthCubit>(),
            ),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter(context.read<AuthCubit>());
          return BlocListener<AuthCubit, AuthState>(
            listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
            listener: (context, state) {
              final currency = context.read<CurrencyCubit>();
              if (state is Authenticated) {
                currency.load();
              } else {
                currency.reset();
              }
            },
            child: MaterialApp.router(
              title: 'Odoo Property Management',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                useMaterial3: true,
              ),
              routerConfig: router.router,
              debugShowCheckedModeBanner: false,
            ),
          );
        },
      ),
    );
  }
}
