class LoginRequest {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class SignupRequest {
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;
  SignupRequest({required this.email, required this.password, this.firstName, this.lastName});
  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
      };
}

class AuthSuccessResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  AuthSuccessResponse({required this.success, required this.message, this.data});
  factory AuthSuccessResponse.fromJson(Map<String, dynamic> json) => AuthSuccessResponse(
        success: json['success'] ?? false,
        message: json['message'] ?? '',
        data: json['data'] as Map<String, dynamic>?,
      );
}

class AuthErrorResponse {
  final bool success;
  final String message;
  AuthErrorResponse({required this.success, required this.message});
  factory AuthErrorResponse.fromJson(Map<String, dynamic> json) => AuthErrorResponse(
        success: json['success'] ?? false,
        message: json['message'] ?? '',
      );
}
