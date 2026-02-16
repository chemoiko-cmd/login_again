import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
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
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _submit() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      context.read<AuthCubit>().registerLandlord(
        database: widget.database,
        name: formData['name']?.trim() ?? '',
        email: formData['email']?.trim() ?? '',
        phone: formData['phone']?.trim() ?? '',
        password: formData['password'] ?? '',
      );
    }
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
                              child: FormBuilder(
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
                                      'Create account',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 24),

                                    _fieldLabel(context, text: 'Full name'),
                                    FormBuilderTextField(
                                      name: 'name',
                                      decoration: _inputDecoration(
                                        hint: 'Enter your full name',
                                        icon: Icons.person,
                                      ),
                                      enabled: !isLoading,
                                      validator: FormBuilderValidators.compose([
                                        FormBuilderValidators.required(),
                                      ]),
                                    ),
                                    const SizedBox(height: 16),

                                    _fieldLabel(context, text: 'Email'),
                                    FormBuilderTextField(
                                      name: 'email',
                                      decoration: _inputDecoration(
                                        hint: 'example@email.com',
                                        icon: Icons.email,
                                      ),
                                      enabled: !isLoading,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: FormBuilderValidators.compose([
                                        FormBuilderValidators.required(),
                                        FormBuilderValidators.email(),
                                      ]),
                                    ),
                                    const SizedBox(height: 16),

                                    _fieldLabel(context, text: 'Phone number'),
                                    FormBuilderTextField(
                                      name: 'phone',
                                      decoration: _inputDecoration(
                                        hint: '0700000000',
                                        icon: Icons.phone,
                                      ),
                                      enabled: !isLoading,
                                      keyboardType: TextInputType.phone,
                                      validator: FormBuilderValidators.compose([
                                        FormBuilderValidators.required(),
                                        FormBuilderValidators.numeric(),
                                        FormBuilderValidators.equalLength(10,
                                            errorText:
                                                'Phone number must be exactly 10 digits'),
                                      ]),
                                    ),
                                    const SizedBox(height: 16),

                                    _fieldLabel(context, text: 'Password'),
                                    FormBuilderTextField(
                                      name: 'password',
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
                                      validator: FormBuilderValidators.compose([
                                        FormBuilderValidators.required(),
                                        FormBuilderValidators.minLength(8),
                                        FormBuilderValidators.match(
                                          RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[^A-Za-z0-9])'),
                                          errorText: 'Password must include uppercase, lowercase, number, and symbol',
                                        ),
                                      ]),
                                    ),
                                    const SizedBox(height: 16),

                                    _fieldLabel(
                                      context,
                                      text: 'Confirm password',
                                    ),
                                    FormBuilderTextField(
                                      name: 'confirmPassword',
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
                                      validator: FormBuilderValidators.compose([
                                        FormBuilderValidators.required(),
                                        (value) {
                                          final password = _formKey.currentState?.fields['password']?.value;
                                          if (value != password) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                      ]),
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton(
                                      onPressed: isLoading ? null : _submit,
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
