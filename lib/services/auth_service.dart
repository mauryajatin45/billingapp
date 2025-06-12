import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/auth'; // Use 10.0.2.2 for Android emulator

  static Future<Map<String, dynamic>> register({
    required String mobile,
    required String email,
    required String businessName,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'email': email,
        'businessName': businessName,
        'password': password,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? 'Registration failed');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String mobile,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'password': password,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'otp': otp,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      // Save auth token to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', responseData['token']);
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? 'OTP verification failed');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }
}