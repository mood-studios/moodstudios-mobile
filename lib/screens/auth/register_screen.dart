import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/auth_messages.dart';
import '../../core/push/push_notifications.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _emailOtp = TextEditingController();

  bool _emailVerified = false;
  String? _verifyStatus;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _emailOtp.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email first')),
      );
      return;
    }

    setState(() {
      _emailVerified = false;
      _verifyStatus = 'Sending code…';
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.sendSignupOtp(_email.text.trim());
    if (!mounted) return;

    setState(() {
      _verifyStatus = ok ? 'Code sent. Check your email.' : auth.error;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Could not send code')));
    }
  }

  Future<void> _verifyCode() async {
    final email = _email.text.trim();
    final otp = _emailOtp.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email first')),
      );
      return;
    }
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code')),
      );
      return;
    }

    setState(() => _verifyStatus = 'Verifying…');

    final auth = context.read<AuthProvider>();
    final ok = await auth.verifySignupEmail(email, otp);
    if (!mounted) return;

    setState(() {
      _emailVerified = ok;
      _verifyStatus = ok ? 'Email verified ✓' : auth.error;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Invalid code')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your email before signing up')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      phone: _phone.text.trim(),
    );
    if (!mounted) return;

    if (ok) {
      final user = auth.user;
      if (user != null) {
        context.read<SettingsProvider>().applyFromUser(user.preferences);
      }
      await PushNotifications.syncWhenAuthenticated(context);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Registration failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (_) {
                  if (_emailVerified) {
                    setState(() {
                      _emailVerified = false;
                      _verifyStatus = null;
                    });
                  }
                },
                validator: (v) => v != null && v.contains('@') ? null : 'Invalid email',
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _emailOtp,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      enabled: !_emailVerified,
                      decoration: const InputDecoration(
                        labelText: 'Email code',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: auth.loading ? null : _sendCode, child: const Text('Send')),
                  TextButton(onPressed: auth.loading || _emailVerified ? null : _verifyCode, child: const Text('Verify')),
                ],
              ),
              if (_verifyStatus != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _verifyStatus!,
                    style: TextStyle(
                      fontSize: 13,
                      color: _emailVerified ? Colors.green.shade700 : AppColors.muted,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                AuthMessages.otpSpamShort,
                style: TextStyle(fontSize: 12, color: AppColors.muted.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) => v != null && v.length >= 8 ? null : 'Min 8 characters',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.loading ? null : _submit,
                  child: Text(auth.loading ? 'Creating…' : 'Create account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
