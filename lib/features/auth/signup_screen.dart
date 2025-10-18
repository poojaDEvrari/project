import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'auth_service.dart';
import 'auth_models.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  void _submit() async {
    setState(() => _loading = true);
    try {
      final req = SignupRequest(email: _email.text.trim(), password: _pwd.text.trim(), firstName: _first.text.trim(), lastName: _last.text.trim());
      final res = await _auth.signup(req);
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
        context.go('/lidar-detection');
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
      appBar: AppBar(title: 'Signup'.text.make()),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _first, decoration: const InputDecoration(labelText: 'First name')),
            const SizedBox(height: 8),
            TextField(controller: _last, decoration: const InputDecoration(labelText: 'Last name')),
            const SizedBox(height: 8),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: _pwd, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator() : 'Sign up'.text.make())),
          ],
        ),
      ),
    );
  }
}
