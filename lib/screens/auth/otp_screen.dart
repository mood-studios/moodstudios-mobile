import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.email});

  final String email;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otp = TextEditingController();

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(widget.email, _otp.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Invalid OTP')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Enter the 6-digit OTP sent to ${widget.email}'),
            const SizedBox(height: 8),
            const Text('Check your backend console in development mode.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 20),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(labelText: 'OTP Code'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.loading ? null : _verify,
                child: const Text('Verify'),
              ),
            ),
            TextButton(
              onPressed: () => auth.resendOtp(widget.email),
              child: const Text('Resend OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
