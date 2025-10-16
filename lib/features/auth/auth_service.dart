import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_models.dart';

class AuthService {
  static const String _base = 'http://98.86.182.22';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<AuthSuccessResponse> login(LoginRequest req) async {
    final response = await http.post(
      Uri.parse('$_base/auth/login/'),
      body: jsonEncode(req.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final resp = AuthSuccessResponse.fromJson(body);
      final token = _extractToken(body, resp.data);
      if (token != null && token.isNotEmpty) {
        await _storage.write(key: 'jwt', value: token);
      }
      return resp;
    } else {
      return AuthSuccessResponse(
        success: false,
        message: body['message'] ?? 'Login failed',
      );
    }
  }

  Future<AuthSuccessResponse> signup(SignupRequest req) async {
    final response = await http.post(
      Uri.parse('$_base/auth/signup/'),
      body: jsonEncode(req.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 201) {
      final resp = AuthSuccessResponse.fromJson(body);
      final token = _extractToken(body, resp.data);
      if (token != null && token.isNotEmpty) {
        await _storage.write(key: 'jwt', value: token);
      }
      return resp;
    } else {
      return AuthSuccessResponse(
        success: false,
        message: body['message'] ?? 'Signup failed',
      );
    }
  }

  String? _extractToken(Map<String, dynamic> rawJson, Map<String, dynamic>? data) {
    final candidates = <String?>[
      data != null ? (data['token'] as String?) : null,
      data != null ? (data['access'] as String?) : null,
      data != null ? (data['jwt'] as String?) : null,
      rawJson['token'] as String?,
      rawJson['access'] as String?,
      rawJson['jwt'] as String?,
    ];
    for (final c in candidates) {
      if (c != null && c.isNotEmpty) return c;
    }
    return null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt');
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null || token.isEmpty) {
      return false;
    }
    return !_isTokenExpired(token);
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return true; // invalid token
      }
      final payload = _decodeBase64(parts[1]);
      final Map<String, dynamic> decoded = json.decode(payload);
      final exp = decoded['exp'];
      if (exp == null) {
        return false; // no expiry claim
      }
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expirationDate);
    } catch (_) {
      return true; // if decoding fails, treat as expired
    }
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    while (output.length % 4 != 0) {
      output += '=';
    }
    return utf8.decode(base64Url.decode(output));
  }

  Future<Map<String, dynamic>> profile() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('Not authenticated');
    }
    final response = await http.get(
      Uri.parse('$_base/auth/profile/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return body['data'] as Map<String, dynamic>;
    } else {
      throw Exception(body['message'] ?? 'Failed to fetch profile');
    }
  }

  Future<void> clearExpiredToken() async {
    final token = await _storage.read(key: 'jwt');
    if (token != null && _isTokenExpired(token)) {
      await _storage.delete(key: 'jwt');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt');
  }
}
