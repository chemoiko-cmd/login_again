import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'register_landlord_page.dart';

class RegisterOptionsPage extends StatelessWidget {
  final String database;

  const RegisterOptionsPage({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomRadius = const BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
    );

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
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

            return Stack(
              children: [
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
                          Colors.black.withOpacity(0.15),
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: bottomRadius,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, -8),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                const SizedBox(height: 6),
                                Text(
                                  'Choose a sign up method',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _OptionCard(
                                  title: 'Sign up with Email',
                                  subtitle:
                                      'Use your email address to create account',
                                  icon: Icons.email,
                                  onTap: isLoading
                                      ? () {}
                                      : () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  RegisterLandlordPage(
                                                    database: database,
                                                  ),
                                            ),
                                          );
                                        },
                                ),
                                const SizedBox(height: 12),
                                _OptionCard(
                                  title: 'Sign up with Google',
                                  subtitle:
                                      'Create account with your Google account',
                                  icon: Icons.g_mobiledata,
                                  onTap: isLoading
                                      ? () {}
                                      : () {
                                          context
                                              .read<AuthCubit>()
                                              .registerWithGoogle(
                                                database: database,
                                              );
                                        },
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Already have an account? Login',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
          color: color.withOpacity(0.06),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
