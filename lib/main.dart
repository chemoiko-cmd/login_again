// ============================================================================
// FILE: lib/main.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:upgrader/upgrader.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/currency/currency_cubit.dart';
import 'core/api/api_client.dart';
import 'core/register_cubits.dart';
import 'core/routes/app_router.dart';
import 'core/storage/auth_local_storage.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<dynamic>(AuthLocalStorage.boxName);

  final apiClient = ApiClient();
  // http://192.168.1.7:8069  https://rental.kolapro.com
  final authRepository = AuthRepositoryImpl(AuthRemoteDataSource(apiClient));

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
        ...RegisterCubits(
          apiClient: apiClient,
          authRepository: authRepository,
        ).register(),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter(context.read<AuthCubit>());
          return _buildAppWithAuthListener(context, router);
        },
      ),
    );
  }

  // ========================================================================
  // Wrap MaterialApp with Auth State Listener
  // ========================================================================
  Widget _buildAppWithAuthListener(BuildContext context, AppRouter router) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      listener: (context, state) {
        final currencyCubit = context.read<CurrencyCubit>();
        if (state is Authenticated) {
          currencyCubit.load();
        } else {
          currencyCubit.reset();
        }
      },
      child: UpgradeAlert(
        barrierDismissible: false,
        showIgnore: false, // Hide the Ignore button
        showLater: false,
        upgrader: Upgrader(
          durationUntilAlertAgain: Duration(hours: 1), // Check frequently
        ),

        child: MaterialApp.router(
          title: 'Odoo Property Management',
          theme: AppTheme.theme,
          routerConfig: router.router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
