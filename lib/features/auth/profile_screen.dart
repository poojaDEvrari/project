import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'auth_service.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _auth.profile();
      setState(() {
        _profile = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: 'Profile'.text.make()),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${_profile?['email'] ?? "-"}'),
                  const SizedBox(height: 8),
                  Text('Name: ${_profile?['first_name'] ?? ""} ${_profile?['last_name'] ?? ""}'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () async { await _auth.logout(); context.go('/login'); }, child: 'Logout'.text.make()),
                ],
              ),
            ),
    );
  }
}
