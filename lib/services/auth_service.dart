import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/auth';
  static const Duration timeoutDuration = Duration(seconds: 15);

  // Helper method to handle HTTP responses
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final status = response.statusCode;
    final body = response.body;

    try {
      final responseData = jsonDecode(body);
      if (status >= 200 && status < 300) {
        return responseData;
      } else {
        final errorMsg =
            responseData['message'] ??
            responseData['error'] ??
            'Request failed with status $status';
        throw Exception(errorMsg);
      }
    } on FormatException {
      throw Exception('Invalid JSON response: $body');
    }
  }

  // Validates and extracts token from response
  static String _validateAndExtractToken(Map<String, dynamic> response) {
    if (response.containsKey('data')) {
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null && data.containsKey('tokens')) {
        final tokens = data['tokens'] as Map<String, dynamic>?;
        if (tokens != null && tokens.containsKey('access')) {
          final token = tokens['access'];
          if (token is String && token.isNotEmpty) return token;
        }
      }
    }

    // Fallback to root-level token fields
    final token =
        response['token'] ?? response['access_token'] ?? response['authToken'];

    if (token == null) {
      throw Exception(
        'Token not found in API response. Response keys: ${response.keys.join(', ')}',
      );
    }

    if (token is! String) {
      throw Exception('Token is not a string: ${token.runtimeType}');
    }

    if (token.isEmpty) {
      throw Exception('Token is empty');
    }

    return token;
  }

  // Registration
  static Future<Map<String, dynamic>> register({
    required String mobile,
    required String email,
    required String businessName,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'mobile': mobile,
              'email': email,
              'businessName': businessName,
              'password': password,
            }),
          )
          .timeout(timeoutDuration);

      final responseData = _handleResponse(response);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isRegistered', true);
      await prefs.setString('registeredMobile', mobile);

      // Save userId if available
      final userData = responseData['data']?['user'];
      if (userData != null && userData['id'] != null) {
        await prefs.setString('userId', userData['id'].toString());
      }

      return responseData;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String mobile,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mobile': mobile, 'password': password}),
          )
          .timeout(timeoutDuration);

      final responseData = _handleResponse(response);
      final token = _validateAndExtractToken(responseData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', token);
      await prefs.setBool('isVerified', true);

      // ✅ Store userId from response
      final userData = responseData['data']?['user'];
      if (userData != null && userData['id'] != null) {
        await prefs.setString('userId', userData['id'].toString());
      }

      return responseData;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // OTP Verification
  static Future<Map<String, dynamic>> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mobile': mobile, 'otp': otp}),
          )
          .timeout(timeoutDuration);

      final responseData = _handleResponse(response);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isVerified', true);
      await prefs.remove('isRegistered');
      await prefs.remove('registeredMobile');

      // Save userId if available
      final userData = responseData['data']?['user'];
      if (userData != null && userData['id'] != null) {
        await prefs.setString('userId', userData['id'].toString());
      }

      return responseData;
    } catch (e) {
      throw Exception('OTP verification failed: ${e.toString()}');
    }
  }

  // Resend OTP
  static Future<Map<String, dynamic>> resendOtp({
    required String mobile,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/resend-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mobile': mobile}),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('OTP resend failed: ${e.toString()}');
    }
  }

  // Logout and clear all session data
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
      await prefs.remove('userId'); // ✅ clear userId as well
      await prefs.remove('isVerified');
      await prefs.remove('isRegistered');
      await prefs.remove('registeredMobile');
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  // Utility method to get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Check if token exists
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
