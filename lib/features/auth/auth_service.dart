import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'auth_models.dart';

class AuthService {
  static const String _base = 'http://98.86.182.22';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  // Consistent platform options for read/write
  static const AndroidOptions _aOptions = AndroidOptions(encryptedSharedPreferences: true);
  static const IOSOptions _iOptions = IOSOptions(accessibility: KeychainAccessibility.unlocked);

  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'jwt', value: token, aOptions: _aOptions, iOptions: _iOptions);
  }

  Future<String?> _readToken() async {
    return await _storage.read(key: 'jwt', aOptions: _aOptions, iOptions: _iOptions);
  }

  Future<void> _deleteToken() async {
    await _storage.delete(key: 'jwt', aOptions: _aOptions, iOptions: _iOptions);
  }

  Future<AuthSuccessResponse> login(LoginRequest req) async {
    debugPrint('🔐 LOGIN: Starting login for ${req.email}');
    
    try {
      final response = await http.post(
        Uri.parse('$_base/auth/login/'),
        body: jsonEncode(req.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
      
      debugPrint('🔐 LOGIN: Status code: ${response.statusCode}');
      debugPrint('🔐 LOGIN: Response body: ${response.body}');
      
      final body = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final resp = AuthSuccessResponse.fromJson(body);
        
        // Extract token with detailed logging
        final token = _extractToken(body, resp.data);
        debugPrint('🔐 LOGIN: Extracted token: ${token != null ? "YES (${token.substring(0, 20)}...)" : "NO"}');
        
        if (token != null && token.isNotEmpty) {
          await _saveToken(token);
          debugPrint('🔐 LOGIN: Token saved to storage');
          
          // Verify it was saved
          final verified = await _readToken();
          debugPrint('🔐 LOGIN: Token verification: ${verified != null ? "SUCCESS" : "FAILED"}');
        } else {
          debugPrint('❌ LOGIN: No token found in response!');
          debugPrint('❌ LOGIN: Response structure: ${body.toString()}');
        }
        
        return resp;
      } else {
        debugPrint('❌ LOGIN: Failed with status ${response.statusCode}');
        return AuthSuccessResponse(
          success: false,
          message: body['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      debugPrint('❌ LOGIN: Exception: $e');
      rethrow;
    }
  }

  Future<AuthSuccessResponse> signup(SignupRequest req) async {
    debugPrint('🔐 SIGNUP: Starting signup for ${req.email}');
    
    try {
      final response = await http.post(
        Uri.parse('$_base/auth/signup/'),
        body: jsonEncode(req.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
      
      debugPrint('🔐 SIGNUP: Status code: ${response.statusCode}');
      debugPrint('🔐 SIGNUP: Response body: ${response.body}');
      
      final body = jsonDecode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final resp = AuthSuccessResponse.fromJson(body);
        final token = _extractToken(body, resp.data);
        
        debugPrint('🔐 SIGNUP: Extracted token: ${token != null ? "YES" : "NO"}');
        
        if (token != null && token.isNotEmpty) {
          await _saveToken(token);
          debugPrint('🔐 SIGNUP: Token saved to storage');
        } else {
          debugPrint('❌ SIGNUP: No token found in response!');
        }
        
        return resp;
      } else {
        return AuthSuccessResponse(
          success: false,
          message: body['message'] ?? 'Signup failed',
        );
      }
    } catch (e) {
      debugPrint('❌ SIGNUP: Exception: $e');
      rethrow;
    }
  }

  String? _extractToken(Map<String, dynamic> rawJson, Map<String, dynamic>? data) {
    debugPrint('🔍 EXTRACT: Raw JSON keys: ${rawJson.keys.toList()}');
    debugPrint('🔍 EXTRACT: Data keys: ${data?.keys.toList()}');

    // Priority: data.tokens.access_token
    final tokens = (data?['tokens'] is Map) ? data!['tokens'] as Map<String, dynamic> : null;
    final nestedAccess = tokens != null ? tokens['access_token'] as String? : null;
    final nestedRefresh = tokens != null ? tokens['refresh_token'] as String? : null;
    if (nestedAccess != null && nestedAccess.isNotEmpty) {
      // Optionally store refresh token for future use
      if (nestedRefresh != null && nestedRefresh.isNotEmpty) {
        // Fire-and-forget: save refresh token under a different key
        _storage.write(key: 'refresh_jwt', value: nestedRefresh, aOptions: _aOptions, iOptions: _iOptions);
      }
      final cleaned = _cleanToken(nestedAccess);
      if (cleaned != null && cleaned.isNotEmpty) {
        debugPrint('✅ EXTRACT: Found access token in data.tokens.access_token');
        return cleaned;
      }
    }

    // Fallback candidates
    final candidates = <String?>[
      data?['token'] as String?,
      data?['access'] as String?,
      data?['jwt'] as String?,
      data?['access_token'] as String?,
      rawJson['token'] as String?,
      rawJson['access'] as String?,
      rawJson['jwt'] as String?,
      rawJson['access_token'] as String?,
      (rawJson['auth'] as Map<String, dynamic>?)?['token'] as String?,
      (rawJson['auth'] as Map<String, dynamic>?)?['access_token'] as String?,
    ];

    for (int i = 0; i < candidates.length; i++) {
      final c = candidates[i];
      if (c != null && c.isNotEmpty) {
        debugPrint('🔍 EXTRACT: Found candidate at $i: ${c.substring(0, 20)}...');
        final cleaned = _cleanToken(c);
        if (cleaned != null && cleaned.isNotEmpty) {
          debugPrint('✅ EXTRACT: Successfully extracted and cleaned token');
          return cleaned;
        }
      }
    }

    debugPrint('❌ EXTRACT: No token found in any expected location');
    return null;
  }

  String? _cleanToken(String? token) {
    if (token == null) return null;
    var t = token.trim();
    if (t.isEmpty) return null;
    
    for (final prefix in const ['Bearer ', 'JWT ', 'Token ']) {
      if (t.startsWith(prefix)) {
        t = t.substring(prefix.length).trim();
      }
    }
    return t;
  }

  Future<String?> getToken() async {
    final stored = await _readToken();
    debugPrint('🔑 GET TOKEN: ${stored != null ? "Found (${stored.substring(0, 20)}...)" : "Not found"}');
    
    final cleaned = _cleanToken(stored);
    if (cleaned != null && cleaned != stored) {
      await _saveToken(cleaned);
    }
    return cleaned;
  }

  Future<bool> isAuthenticated() async {
    final token = await _readToken();
    if (token == null || token.isEmpty) {
      debugPrint('🔒 AUTH CHECK: No token found');
      return false;
    }
    
    final expired = _isTokenExpired(token);
    debugPrint('🔒 AUTH CHECK: Token ${expired ? "expired" : "valid"}');
    return !expired;
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      // If token is not a JWT (opaque token), do not expire it client-side.
      if (parts.length != 3) return false;
      final payload = _decodeBase64(parts[1]);
      final Map<String, dynamic> decoded = json.decode(payload);
      final exp = decoded['exp'];
      if (exp == null) return false;
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expirationDate);
    } catch (_) {
      // On decode failure, assume valid and let server enforce auth
      return false;
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
    final token = await _readToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    
    debugPrint('👤 PROFILE: Fetching with token');
    
    final response = await http.get(
      Uri.parse('$_base/auth/profile/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    debugPrint('👤 PROFILE: Status ${response.statusCode}');
    
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return body['data'] as Map<String, dynamic>;
    } else {
      throw Exception(body['message'] ?? 'Failed to fetch profile');
    }
  }

  Future<void> clearExpiredToken() async {
    final token = await _readToken();
    if (token != null && _isTokenExpired(token)) {
      await _deleteToken();
      debugPrint('🗑️ Cleared expired token');
    }
  }
  Future<void> logout() async {
    await _deleteToken();
    debugPrint('👋 Logged out - token deleted');
  }
}