import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/validation/form_validators.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _codeSent = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  String? _status;
  bool _statusIsError = false;

  static const _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _email.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = _resendSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) {
          _resendCooldown = 0;
          timer.cancel();
        }
      });
    });
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter your email address.';
    if (!v.contains('@')) return 'Enter a valid email address.';
    return null;
  }

  Future<void> _sendCode() async {
    final emailErr = _validateEmail(_email.text);
    if (emailErr != null) {
      setState(() {
        _status = emailErr;
        _statusIsError = true;
      });
      return;
    }

    final auth = context.read<AuthProvider>();
    setState(() {
      _status = 'Sending reset code…';
      _statusIsError = false;
    });

    final ok = await auth.sendForgotPasswordOtp(_email.text.trim());
    if (!mounted) return;

    if (ok) {
      setState(() {
        _codeSent = true;
        _status =
            'If an account exists for this email, a 6-digit code has been sent.';
        _statusIsError = false;
      });
      _startResendCooldown();
    } else {
      setState(() {
        _status = auth.error ?? 'Could not send code. Try again.';
        _statusIsError = true;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_password.text != _confirmPassword.text) {
      setState(() {
        _status = 'Passwords do not match.';
        _statusIsError = true;
      });
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.resetForgotPassword(
      email: _email.text.trim(),
      otp: _otp.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password updated. Log in with your new password.',
          ),
        ),
      );
      Navigator.pop(context, _email.text.trim());
    } else {
      setState(() {
        _status = auth.error ?? 'Could not reset password.';
        _statusIsError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Reset your password',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Enter the email on your account. We'll send a 6-digit code to confirm it's you.",
                  style: TextStyle(color: AppColors.muted, height: 1.35),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_codeSent,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: auth.loading || _resendCooldown > 0
                        ? null
                        : _sendCode,
                    icon: const Icon(Icons.mail_outline),
                    label: Text(
                      _resendCooldown > 0
                          ? 'Resend in ${_resendCooldown}s'
                          : _codeSent
                              ? 'Resend code'
                              : 'Send reset code',
                    ),
                  ),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _status!,
                    style: TextStyle(
                      fontSize: 13,
                      color: _statusIsError
                          ? Colors.red.shade700
                          : AppColors.muted,
                    ),
                  ),
                ],
                if (_codeSent) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otp,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Reset code',
                      counterText: '',
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.length != 6) {
                        return 'Enter the 6-digit code from your email.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: FormValidators.validatePasswordStrength,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'At least 8 characters, one uppercase letter, and one special character.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm new password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if ((v ?? '').isEmpty) return 'Confirm your password.';
                      if (v != _password.text) return 'Passwords do not match.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.loading ? null : _resetPassword,
                      child: Text(
                        auth.loading ? 'Updating…' : 'Update password',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Back to log in',
                    style: TextStyle(color: AppColors.purple),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
