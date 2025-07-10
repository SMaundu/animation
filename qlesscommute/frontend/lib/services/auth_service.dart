import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  // Register new user
  static Future<ApiResponse<AuthResult>> register({
    required String name,
    required String phone,
    required String password,
    String role = 'passenger',
  }) async {
    final response = await ApiService.post<AuthResult>(
      '/register',
      {
        'name': name,
        'phone': phone,
        'password': password,
        'role': role,
      },
      AuthResult.fromJson,
      requireAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      // Save user data and token
      await _saveUserData(response.data!.user);
      await ApiService.saveAuthToken(response.data!.token);
    }

    return response;
  }

  // Login user
  static Future<ApiResponse<AuthResult>> login({
    required String phone,
    required String password,
  }) async {
    final response = await ApiService.post<AuthResult>(
      '/login',
      {
        'phone': phone,
        'password': password,
      },
      AuthResult.fromJson,
      requireAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      // Save user data and token
      await _saveUserData(response.data!.user);
      await ApiService.saveAuthToken(response.data!.token);
    }

    return response;
  }

  // Verify token
  static Future<ApiResponse<User>> verifyToken() async {
    final response = await ApiService.get<User>(
      '/verify',
      (data) => User.fromJson(data['user']),
    );

    if (response.isSuccess && response.data != null) {
      // Update stored user data
      await _saveUserData(response.data!);
    }

    return response;
  }

  // Change password
  static Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await ApiService.post<Map<String, dynamic>>(
      '/change-password',
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      (data) => data,
    );
  }

  // Logout
  static Future<void> logout() async {
    await _clearUserData();
    await ApiService.clearAuthToken();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getAuthToken();
    return token != null && token.isNotEmpty;
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    
    if (userData != null) {
      try {
        final userMap = Map<String, dynamic>.from(
          await ApiService.get<Map<String, dynamic>>(
            '/verify',
            (data) => data,
          ).then((response) => response.data ?? {}),
        );
        return User.fromJson(userMap['user'] ?? {});
      } catch (e) {
        // If there's an error, return null and let the app handle re-authentication
        return null;
      }
    }
    
    return null;
  }

  // Save user data locally
  static Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user.toJson().toString());
  }

  // Clear user data locally
  static Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Check authentication status and auto-login if token exists
  static Future<AuthStatus> checkAuthStatus() async {
    try {
      final token = await ApiService.getAuthToken();
      
      if (token == null || token.isEmpty) {
        return AuthStatus.unauthenticated;
      }

      // Verify token with server
      final verifyResponse = await verifyToken();
      
      if (verifyResponse.isSuccess) {
        return AuthStatus.authenticated;
      } else {
        // Token is invalid, clear it
        await logout();
        return AuthStatus.unauthenticated;
      }
    } catch (e) {
      // If there's any error, assume unauthenticated
      await logout();
      return AuthStatus.unauthenticated;
    }
  }

  // Validate phone number format
  static bool isValidPhoneNumber(String phone) {
    // Kenyan phone number formats: 0712345678 or 254712345678
    final phoneRegex = RegExp(r'^(254|0)[7-9]\d{8}$');
    return phoneRegex.hasMatch(phone);
  }

  // Format phone number
  static String formatPhoneNumber(String phone) {
    // Remove any spaces or special characters
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Convert to international format
    if (phone.startsWith('0')) {
      return '254${phone.substring(1)}';
    } else if (phone.startsWith('254')) {
      return phone;
    } else if (phone.length == 9) {
      return '254$phone';
    }
    
    return phone;
  }

  // Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Get password strength message
  static String getPasswordStrengthMessage(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    if (password.length < 8) {
      return 'Good password';
    }
    
    if (password.contains(RegExp(r'[A-Z]')) && 
        password.contains(RegExp(r'[a-z]')) && 
        password.contains(RegExp(r'[0-9]'))) {
      return 'Strong password';
    }
    
    return 'Good password';
  }
}

class AuthResult {
  final User user;
  final String token;

  AuthResult({
    required this.user,
    required this.token,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      user: User.fromJson(json['user']),
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
    };
  }
}

enum AuthStatus {
  authenticated,
  unauthenticated,
  loading,
}