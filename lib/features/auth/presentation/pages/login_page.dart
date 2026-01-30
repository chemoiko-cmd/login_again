// ============================================================================
// FILE: lib/features/auth/presentation/pages/login_page.dart
// ============================================================================
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
import 'package:login_again/core/widgets/app_loading_indicator.dart';
import 'package:login_again/core/widgets/glass_background.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'forgot_password_page.dart';
import 'register_options_page.dart';
import 'package:upgrader/upgrader.dart'; // ← ADD THIS IMPORT

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _databaseController = TextEditingController(text: 'rental');
  bool _obscurePassword = true;

  Future<void> _showPolicySheet({required String title}) async {
    final markdown = await rootBundle.loadString('assets/privacy_policy.md');

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title, style: theme.textTheme.titleLarge),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Markdown(
                    data: markdown,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsAndPrivacy({required bool enabled}) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodySmall;
    final linkStyle = baseStyle?.copyWith(
      color: theme.primaryColor,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: 'By continuing, you agree to our\n'),
          TextSpan(
            text: 'Terms & Conditions',
            // style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = enabled
                  ? () => _showPolicySheet(title: 'Terms & Conditions')
                  : null,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = enabled
                  ? () => _showPolicySheet(title: 'Privacy Policy')
                  : null,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _databaseController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        database: _databaseController.text.trim(),
      );
    }
  }

  void _handleGoogleLogin() {
    context.read<AuthCubit>().loginWithGoogle(
      database: _databaseController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return UpgradeAlert(
      barrierDismissible: false,
      showLater: false,
      showIgnore: false,
      upgrader: Upgrader(messages: UpgraderMessages(code: 'en')),
      child: Scaffold(
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              const Positioned.fill(
                child: GlassBackground(child: SizedBox.expand()),
              ),
              Positioned.fill(
                child: Image.asset(
                  'assets/login-image.webp',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: BlocConsumer<AuthCubit, AuthState>(
                    listener: (context, state) {
                      if (state is AuthError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: GlassBackground(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 480,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Align(
                                        alignment: Alignment.center,
                                        child: Image.asset(
                                          'assets/app_icon.png',
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'KRental',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.headlineSmall,
                                      ),
                                      const SizedBox(height: 24),
                                      TextFormField(
                                        controller: _usernameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Username or Phone',
                                          prefixIcon: Icon(Icons.person),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your username or phone';
                                          }
                                          return null;
                                        },
                                        enabled: !isLoading,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _passwordController,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: const Icon(Icons.lock),
                                          border: const OutlineInputBorder(),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                        obscureText: _obscurePassword,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          return null;
                                        },
                                        enabled: !isLoading,
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: isLoading
                                              ? null
                                              : () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const ForgotPasswordPage(),
                                                    ),
                                                  );
                                                },
                                          child: Text(
                                            'Forgot Password?',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme.primaryColor,
                                                ),
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: isLoading
                                              ? null
                                              : () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          RegisterOptionsPage(
                                                            database:
                                                                _databaseController
                                                                    .text
                                                                    .trim(),
                                                          ),
                                                    ),
                                                  );
                                                },
                                          child: Text(
                                            'Create account',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme.primaryColor,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      GradientButton(
                                        onPressed: isLoading
                                            ? null
                                            : _handleLogin,
                                        padding: const EdgeInsets.all(16),
                                        child: isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: AppLoadingIndicator(
                                                  width: 20,
                                                  height: 20,
                                                ),
                                              )
                                            : const Text('Login'),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          const Expanded(child: Divider()),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              'OR',
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          ),
                                          const Expanded(child: Divider()),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      OutlinedButton.icon(
                                        onPressed: isLoading
                                            ? null
                                            : _handleGoogleLogin,
                                        icon: SvgPicture.asset(
                                          'assets/google_g.svg',
                                          width: 20,
                                          height: 20,
                                        ),
                                        label: const Text(
                                          'Sign in with Google',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.all(16),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTermsAndPrivacy(
                                        enabled: !isLoading,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
