import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:login_again/core/widgets/glass_background.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class RegisterLandlordPage extends StatefulWidget {
  final String database;

  const RegisterLandlordPage({super.key, required this.database});

  @override
  State<RegisterLandlordPage> createState() => _RegisterLandlordPageState();
}

class _RegisterLandlordPageState extends State<RegisterLandlordPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _canSubmit = false;

  bool _isValidEmail(String input) {
    final email = input.trim();
    final reg = RegExp(
      r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
      caseSensitive: false,
    );
    return reg.hasMatch(email);
  }

  bool _isValidPhone(String input) {
    final phone = input.trim();
    final normalized = phone.startsWith('+') ? phone.substring(1) : phone;
    if (!RegExp(r'^[0-9]+$').hasMatch(normalized)) return false;
    return normalized.length >= 9 && normalized.length <= 10;
  }

  String? _passwordValidationError(String password) {
    if (password.trim().isEmpty) return 'Please enter a password';
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must include an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must include a lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must include a number';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Password must include a symbol';
    }
    return null;
  }

  void _recomputeCanSubmit() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    final next =
        name.isNotEmpty &&
        _isValidEmail(email) &&
        _isValidPhone(phone) &&
        _passwordValidationError(password) == null &&
        confirm.isNotEmpty &&
        confirm == password;

    if (next == _canSubmit) return;
    setState(() => _canSubmit = next);
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_recomputeCanSubmit);
    _emailController.addListener(_recomputeCanSubmit);
    _phoneController.addListener(_recomputeCanSubmit);
    _passwordController.addListener(_recomputeCanSubmit);
    _confirmPasswordController.addListener(_recomputeCanSubmit);
  }

  @override
  void dispose() {
    _nameController.removeListener(_recomputeCanSubmit);
    _emailController.removeListener(_recomputeCanSubmit);
    _phoneController.removeListener(_recomputeCanSubmit);
    _passwordController.removeListener(_recomputeCanSubmit);
    _confirmPasswordController.removeListener(_recomputeCanSubmit);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().registerLandlord(
      database: widget.database,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
  }

  Widget _requiredStar(BuildContext context) {
    return Text(
      '*',
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _fieldLabel(
    BuildContext context, {
    required String text,
    bool required = true,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (required) ...[const SizedBox(width: 4), _requiredStar(context)],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

            if (state is Authenticated) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Stack(
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
                SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: GlassBackground(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: Form(
                                key: _formKey,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
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
                                      'Create account',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 24),

                                    _fieldLabel(context, text: 'Full name'),
                                    TextFormField(
                                      controller: _nameController,
                                      decoration: _inputDecoration(
                                        hint: 'Enter your full name',
                                        icon: Icons.person,
                                      ),
                                      enabled: !isLoading,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    _fieldLabel(context, text: 'Email'),
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: _inputDecoration(
                                        hint: 'example@email.com',
                                        icon: Icons.email,
                                      ),
                                      enabled: !isLoading,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        final v = value?.trim() ?? '';
                                        if (v.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!_isValidEmail(v)) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    _fieldLabel(context, text: 'Phone number'),
                                    TextFormField(
                                      controller: _phoneController,
                                      decoration: _inputDecoration(
                                        hint: '0700000000',
                                        icon: Icons.phone,
                                      ),
                                      enabled: !isLoading,
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        final v = value?.trim() ?? '';
                                        if (v.isEmpty) {
                                          return 'Please enter your phone number';
                                        }
                                        if (!_isValidPhone(v)) {
                                          return 'Please enter a valid phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    _fieldLabel(context, text: 'Password'),
                                    TextFormField(
                                      controller: _passwordController,
                                      decoration:
                                          _inputDecoration(
                                            hint: 'Enter password',
                                            icon: Icons.lock,
                                          ).copyWith(
                                            suffixIcon: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                              ),
                                            ),
                                          ),
                                      enabled: !isLoading,
                                      obscureText: _obscurePassword,
                                      validator: (value) {
                                        return _passwordValidationError(
                                          value ?? '',
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    _fieldLabel(
                                      context,
                                      text: 'Confirm password',
                                    ),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      decoration:
                                          _inputDecoration(
                                            hint: 'Re-enter password',
                                            icon: Icons.lock_outline,
                                          ).copyWith(
                                            suffixIcon: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  _obscureConfirmPassword =
                                                      !_obscureConfirmPassword;
                                                });
                                              },
                                              icon: Icon(
                                                _obscureConfirmPassword
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                              ),
                                            ),
                                          ),
                                      enabled: !isLoading,
                                      obscureText: _obscureConfirmPassword,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton(
                                      onPressed: (isLoading || !_canSubmit)
                                          ? null
                                          : _submit,
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.all(16),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Register'),
                                    ),
                                  ],
                                ),
                              ),
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
