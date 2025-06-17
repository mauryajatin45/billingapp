import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const SettingsApp());

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Settings',
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class UserData {
  final String id;
  final String mobile;
  final String email;
  final String businessName;
  final BusinessAddress businessAddress;
  final Settings settings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserData({
    required this.id,
    required this.mobile,
    required this.email,
    required this.businessName,
    required this.businessAddress,
    required this.settings,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['_id'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      businessName: json['businessName'] ?? '',
      businessAddress: BusinessAddress.fromJson(json['businessAddress'] ?? {}),
      settings: Settings.fromJson(json['settings'] ?? {}),
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class BusinessAddress {
  final String country;

  BusinessAddress({required this.country});

  factory BusinessAddress.fromJson(Map<String, dynamic> json) {
    return BusinessAddress(
      country: json['country'] ?? '',
    );
  }
}

class Settings {
  final String invoicePrefix;
  final int invoiceStartingNumber;
  final bool taxInclusive;
  final double defaultGSTRate;

  Settings({
    required this.invoicePrefix,
    required this.invoiceStartingNumber,
    required this.taxInclusive,
    required this.defaultGSTRate,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      invoicePrefix: json['invoicePrefix'] ?? '',
      invoiceStartingNumber: json['invoiceStartingNumber'] ?? 0,
      taxInclusive: json['taxInclusive'] ?? false,
      defaultGSTRate: (json['defaultGSTRate'] ?? 0.0).toDouble(),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late Future<UserData> _userDataFuture;
  bool _showDeleteModal = false;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<UserData> _fetchUserData() async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return UserData.fromJson(data['data']);
        } else {
          throw Exception('API error: ${data['message']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user data: $e');
    }
  }

  void _handleDelete() {
    setState(() => _showDeleteModal = false);
    // Handle account deletion here
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action is irreversible.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _handleDelete();
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<UserData>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _userDataFuture = _fetchUserData();
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No user data available'));
            }

            final userData = snapshot.data!;
            final settings = userData.settings;

            return ListView(
              children: [
                const Text(
                  'Account Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                
                // Profile Section
                _buildSectionCard('Profile', [
                  _buildInfoRow('Business Name', userData.businessName),
                  _buildInfoRow('Email', userData.email),
                  _buildInfoRow('Mobile', userData.mobile),
                  _buildInfoRow('Country', userData.businessAddress.country),
                ]),
                
                // Invoice Settings Section
                _buildSectionCard('Invoice Settings', [
                  _buildInfoRow('Invoice Prefix', settings.invoicePrefix),
                  _buildInfoRow('Starting Number', settings.invoiceStartingNumber.toString()),
                  _buildInfoRow('Tax Inclusive', settings.taxInclusive ? 'Yes' : 'No'),
                  _buildInfoRow('Default GST Rate', '${settings.defaultGSTRate}%'),
                ]),
                
                // Account Details Section
                _buildSectionCard('Account Details', [
                  _buildInfoRow('Account Status', userData.isActive ? 'Active' : 'Inactive'),
                  _buildInfoRow('Created At', userData.createdAt.toLocal().toString().split('.')[0]),
                  _buildInfoRow('Updated At', userData.updatedAt.toLocal().toString().split('.')[0]),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: _showDeleteConfirmationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete Account'),
                    ),
                  ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }
}