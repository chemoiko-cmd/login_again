// ============================================================================
// FILE: lib/features/auth/presentation/pages/verify_reset_otp_page.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:login_again/core/api/api_client.dart';
import 'package:login_again/core/widgets/app_loading_indicator.dart';
import 'package:login_again/core/widgets/gradient_button.dart';
import 'package:login_again/core/widgets/glass_background.dart';
import '../../data/services/password_reset_service.dart';
import 'reset_password_with_token_page.dart';

class VerifyResetOtpPage extends StatefulWidget {
  final String phoneNo;

  const VerifyResetOtpPage({super.key, required this.phoneNo});

  @override
  State<VerifyResetOtpPage> createState() => _VerifyResetOtpPageState();
}

class _VerifyResetOtpPageState extends State<VerifyResetOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _passwordResetService = PasswordResetService(ApiClient());
  bool _isLoading = false;

  String get _otp => _otpControllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _passwordResetService.verifyPasswordResetOtp(
        phoneNo: widget.phoneNo,
        otp: _otp,
      );

      final resetToken = (result['reset_token'] ?? '').toString();
      if (resetToken.isEmpty) {
        throw Exception('Invalid response: missing reset token');
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordWithTokenPage(
            phoneNo: widget.phoneNo,
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

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            const Positioned.fill(
              child: GlassBackground(child: SizedBox.expand()),
            ),
            Positioned.fill(
              child: Image.asset('assets/login-image.webp', fit: BoxFit.cover),
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
                                  'We sent a 6-digit code to ${widget.phoneNo}.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                FormField<String>(
                                  validator: (_) {
                                    final v = _otp;
                                    if (v.isEmpty) {
                                      return 'Please enter the OTP';
                                    }
                                    if (v.length != 6) {
                                      return 'OTP must be 6 digits';
                                    }
                                    if (!RegExp(r'^\d{6}$').hasMatch(v)) {
                                      return 'OTP must be digits only';
                                    }
                                    return null;
                                  },
                                  builder: (field) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: List.generate(6, (i) {
                                            return SizedBox(
                                              width: 46,
                                              child: TextField(
                                                controller: _otpControllers[i],
                                                focusNode: _otpFocusNodes[i],
                                                enabled: !_isLoading,
                                                keyboardType:
                                                    TextInputType.number,
                                                textAlign: TextAlign.center,
                                                maxLength: 1,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                ],
                                                decoration: InputDecoration(
                                                  counterText: '',
                                                  border:
                                                      const OutlineInputBorder(),
                                                  errorText: null,
                                                ),
                                                onChanged: (value) {
                                                  if (value.length > 1) {
                                                    _otpControllers[i].text =
                                                        value.substring(0, 1);
                                                    _otpControllers[i]
                                                            .selection =
                                                        const TextSelection.collapsed(
                                                          offset: 1,
                                                        );
                                                  }

                                                  if (value.isNotEmpty) {
                                                    if (i < 5) {
                                                      _otpFocusNodes[i + 1]
                                                          .requestFocus();
                                                    } else {
                                                      FocusScope.of(
                                                        context,
                                                      ).unfocus();
                                                    }
                                                  } else {
                                                    if (i > 0) {
                                                      _otpFocusNodes[i - 1]
                                                          .requestFocus();
                                                    }
                                                  }

                                                  field.validate();
                                                },
                                              ),
                                            );
                                          }),
                                        ),
                                        if (field.errorText != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            field.errorText!,
                                            style: TextStyle(
                                              color: theme.colorScheme.error,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
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
            ),
          ],
        ),
      ),
    );
  }
}
