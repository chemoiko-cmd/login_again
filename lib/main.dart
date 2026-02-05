// ============================================================================
// FILE: lib/main.dart
// ============================================================================
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'core/widgets/update_modal.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

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
          final router = AppRouter(
            context.read<AuthCubit>(),
            navigatorKey: _rootNavigatorKey,
          );
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
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.kolapro.krental';

  static const String _githubOwner = 'chemoiko-cmd';
  static const String _githubRepo = 'login_again';

  bool _isNewerVersion(String currentVersion, String latestVersion) {
    try {
      final current = currentVersion.split('.').map(int.parse).toList();
      final latest = latestVersion.split('.').map(int.parse).toList();

      while (current.length < latest.length) {
        current.add(0);
      }
      while (latest.length < current.length) {
        latest.add(0);
      }

      for (var i = 0; i < current.length; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
      }
      return false;
    } catch (_) {
      return currentVersion != latestVersion;
    }
  }

  Future<String?> _fetchLatestGithubReleaseTag() async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest',
      );
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/vnd.github+json');
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = json['tag_name'];
      if (tag is! String || tag.isEmpty) return null;
      return tag.startsWith('v') ? tag.substring(1) : tag;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(_playStoreUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw Exception('Could not open Play Store');
    }
  }

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
      final info = await PackageInfo.fromPlatform();
      final current = info.version;
      final githubLatest = await _fetchLatestGithubReleaseTag();
      final githubLabel = githubLatest ?? 'unknown';

      final updateAvailable =
          githubLatest != null && _isNewerVersion(current, githubLatest);

      if (!updateAvailable) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Current: $current | GitHub: $githubLabel\nNo updates found. App is up to date.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Current: $current | GitHub: $githubLabel\nUpdate available. Showing update dialog...',
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      if (!mounted) return;
      final navigatorContext = _rootNavigatorKey.currentContext;
      if (navigatorContext == null) return;

      await showGeneralDialog<void>(
        context: navigatorContext,
        barrierDismissible: true,
        barrierLabel: 'update',
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return UpdateModal(
            isOpen: true,
            currentVersion: current,
            latestVersion: githubLabel,
            onDismiss: () => Navigator.of(context).pop(),
            onUpdate: () {
              Navigator.of(context).pop();
              _openPlayStore();
            },
          );
        },
      );
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
