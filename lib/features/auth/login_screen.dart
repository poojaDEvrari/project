import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'auth_service.dart';
import 'package:go_router/go_router.dart';
import 'auth_models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isAuth = await _auth.isAuthenticated();
    if (!mounted) return;
    if (isAuth) {
      context.go('/home');
    }
  }

  void _submit() async {
    setState(() => _loading = true);
    try {
      final req = LoginRequest(email: _emailCtrl.text.trim(), password: _pwdCtrl.text.trim());
      final res = await _auth.login(req);
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
        // navigate to Add Room screen
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: 'Login'.text.make()),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _pwdCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator() : 'Login'.text.make()),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: () => context.push('/signup'), child: 'Create an account'.text.make()),
          ],
        ),
      ),
    );
  }
}
