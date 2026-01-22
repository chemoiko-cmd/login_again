// ============================================================================
// FILE: lib/features/auth/presentation/pages/verify_reset_otp_page.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:login_again/core/api/api_client.dart';
import 'package:login_again/core/widgets/app_loading_indicator.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
import '../../data/services/password_reset_service.dart';
import 'reset_password_with_token_page.dart';

class VerifyResetOtpPage extends StatefulWidget {
  final String email;

  const VerifyResetOtpPage({super.key, required this.email});

  @override
  State<VerifyResetOtpPage> createState() => _VerifyResetOtpPageState();
}

class _VerifyResetOtpPageState extends State<VerifyResetOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordResetService = PasswordResetService(ApiClient());
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _passwordResetService.verifyPasswordResetOtp(
        login: widget.email,
        otp: _otpController.text.trim(),
      );

      final resetToken = (result['reset_token'] ?? '').toString();
      if (resetToken.isEmpty) {
        throw Exception('Invalid response: missing reset token');
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordWithTokenPage(
            login: widget.email,
            resetToken: resetToken,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomRadius = BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
    );

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/login-image.jpg', fit: BoxFit.cover),
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
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 72,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Enter OTP',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'We sent a 6-digit code to your email for ${widget.email}.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _otpController,
                                decoration: const InputDecoration(
                                  labelText: 'OTP',
                                  prefixIcon: Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  final v = (value ?? '').trim();
                                  if (v.isEmpty) return 'Please enter the OTP';
                                  if (v.length != 6)
                                    return 'OTP must be 6 digits';
                                  return null;
                                },
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: 16),
                              GradientButton(
                                onPressed: _isLoading ? null : _handleVerify,
                                padding: const EdgeInsets.all(16),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: AppLoadingIndicator(
                                          width: 20,
                                          height: 20,
                                        ),
                                      )
                                    : const Text('Verify'),
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
          ],
        ),
      ),
    );
  }
}
