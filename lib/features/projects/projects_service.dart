import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';

class ProjectsService {
  final String baseUrl;
  ProjectsService({this.baseUrl = 'http://98.86.182.22'});

  Future<List<Map<String, dynamic>>> fetchProjects({String? search}) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found. Please login again.');
    }
    final uri = Uri.parse('$baseUrl/projects/projects/').replace(
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        // cache-busting param to avoid stale intermediaries
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = json.decode(res.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      if (data is Map && data['results'] is List) {
        return (data['results'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } else {
      throw Exception('Failed to fetch projects: ${res.statusCode} ${res.body}');
    }
  }

  Future<Map<String, dynamic>> createProject({
    required String projectName,
    required String address,
    required String scanDate,
    String? floorPlan,
    bool dataAtRestEncrypted = true,
    String? accessPolicyId,
    String? s3KeyScope,
  }) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found. Please login again.');
    }
    final uri = Uri.parse('$baseUrl/projects/projects/');
    final body = {
      'project_name': projectName,
      'address': address,
      'scan_date': scanDate,
      if (floorPlan != null && floorPlan.isNotEmpty) 'floor_plan': floorPlan,
      'data_at_rest_encrypted': dataAtRestEncrypted,
      if (accessPolicyId != null && accessPolicyId.isNotEmpty) 
        'access_policy_id': accessPolicyId,
      if (s3KeyScope != null && s3KeyScope.isNotEmpty) 
        's3_key_scope': s3KeyScope,
    };
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );
    if (res.statusCode == 201 || (res.statusCode >= 200 && res.statusCode < 300)) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create project: ${res.statusCode} ${res.body}');
    }
  }
}