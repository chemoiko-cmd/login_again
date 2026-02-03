// ============================================================================
// FILE: lib/main.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_updater/app_updater.dart';
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
import 'styles/loading/ui_utils.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final AppUpdater _appUpdater = AppUpdater.configure(
  githubOwner: 'chemoiko-cmd',
  githubRepo: 'login_again',
);

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
      child: _AppRoot(router: router),
    );
  }
}

class _AppRoot extends StatefulWidget {
  final AppRouter router;

  const _AppRoot({required this.router});

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkForUpdatesAndNotify();
    });
  }

  Future<void> _checkForUpdatesAndNotify() async {
    final messenger = _scaffoldMessengerKey.currentState;
    final messengerContext = _scaffoldMessengerKey.currentContext;
    if (messenger == null || messengerContext == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Checking for updates...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final updateInfo = await _appUpdater.checkForUpdate();

      if (updateInfo.updateAvailable) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Update available (${updateInfo.latestVersion ?? 'unknown'}). Showing update dialog...',
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        await _appUpdater.showUpdateDialog(
          messengerContext,
          onUpdate: () {
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Opening update...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          onCancel: () {
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Update cancelled.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      } else {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No updates found. App is up to date.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Update check failed: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    UiUtils.setContext(context);
    return MaterialApp.router(
      title: 'Odoo Property Management',
      theme: AppTheme.theme,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      routerConfig: widget.router.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
