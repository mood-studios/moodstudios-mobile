import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../services/user_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _changingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPassword.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }
    if (_newPassword.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _changingPassword = true);
    try {
      await context.read<UserService>().changePassword(
            currentPassword: _currentPassword.text,
            newPassword: _newPassword.text,
          );
      if (!mounted) return;
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This permanently deletes your account and cannot be undone. Enter your password to confirm.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<UserService>().deleteAccount(passwordController.text);
      passwordController.dispose();
      if (!mounted) return;
      await context.read<AuthProvider>().logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      passwordController.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Account settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Account info', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(title: const Text('Email'), subtitle: Text(user?.email ?? '')),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Role'),
                  subtitle: Text(user?.role ?? ''),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Member since'),
                  subtitle: Text(
                    user?.createdAt != null
                        ? '${user!.createdAt!.year}-${user.createdAt!.month.toString().padLeft(2, '0')}'
                        : '—',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('Change password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _currentPassword,
            obscureText: _obscureCurrent,
            decoration: InputDecoration(
              labelText: 'Current password',
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPassword,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: 'New password',
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPassword,
            obscureText: _obscureNew,
            decoration: const InputDecoration(labelText: 'Confirm new password'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _changingPassword ? null : _changePassword,
              child: Text(_changingPassword ? 'Updating...' : 'Update password'),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Danger zone', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.red)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text('Delete my account', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}
