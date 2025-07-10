import '../models/user.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Login user
  static Future<ApiResponse<User>> login(String phoneNumber, String password) async {
    return await ApiService.post<User>(
      '/auth/login',
      {
        'phoneNumber': phoneNumber,
        'password': password,
      },
      (data) => User.fromJson(data['user']),
      saveToken: true,
    );
  }

  // Register user
  static Future<ApiResponse<User>> register(
    String name,
    String phoneNumber,
    String password, {
    String role = 'passenger',
  }) async {
    return await ApiService.post<User>(
      '/auth/register',
      {
        'name': name,
        'phoneNumber': phoneNumber,
        'password': password,
        'role': role,
      },
      (data) => User.fromJson(data['user']),
      saveToken: true,
    );
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    
    if (userData != null) {
      final userMap = User.fromStoredJson(userData);
      return userMap;
    }
    
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null;
  }

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Phone number validation
  static bool isValidPhoneNumber(String phone) {
    // Remove any non-digit characters
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid Kenyan phone number
    final phoneRegex = RegExp(r'^(0[7-9]\d{8}|254[7-9]\d{8}|\d{9})$');
    return phoneRegex.hasMatch(phone);
  }

  // Format phone number to international format
  static String formatPhoneNumber(String phone) {
    // Remove any non-digit characters
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

  // Password validation
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Get password strength message
  static String getPasswordStrengthMessage(String password) {
    if (password.isEmpty) {
      return 'Enter a password';
    } else if (password.length < 6) {
      return 'Password must be at least 6 characters';
    } else if (password.length < 8) {
      return 'Good password';
    } else if (password.length >= 8 && _hasSpecialCharacter(password)) {
      return 'Strong password';
    } else {
      return 'Good password';
    }
  }

  static bool _hasSpecialCharacter(String password) {
    final specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    final numberRegex = RegExp(r'[0-9]');
    final upperCaseRegex = RegExp(r'[A-Z]');
    
    return specialCharRegex.hasMatch(password) ||
           numberRegex.hasMatch(password) ||
           upperCaseRegex.hasMatch(password);
  }

  // Refresh token
  static Future<ApiResponse<String>> refreshToken() async {
    return await ApiService.post<String>(
      '/auth/refresh',
      {},
      (data) => data['token'],
      saveToken: true,
    );
  }

  // Update user profile
  static Future<ApiResponse<User>> updateProfile({
    String? name,
    String? phoneNumber,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;

    return await ApiService.patch<User>(
      '/auth/profile',
      data,
      (data) => User.fromJson(data['user']),
    );
  }

  // Change password
  static Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await ApiService.patch<Map<String, dynamic>>(
      '/auth/change-password',
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      (data) => data,
    );
  }

  // Delete account
  static Future<ApiResponse<Map<String, dynamic>>> deleteAccount(String password) async {
    return await ApiService.delete<Map<String, dynamic>>(
      '/auth/delete-account',
      {'password': password},
      (data) => data,
    );
  }
}