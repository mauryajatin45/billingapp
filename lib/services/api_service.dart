// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000'; // Android emulator localhost

  static Future<Map<String, dynamic>> getBillingTotal() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/billing/expenses'));
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> getExpenses() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/expenses'));
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> getInventory() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/inventory/products'));
    return json.decode(response.body);
  }
}