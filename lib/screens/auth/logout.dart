import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_router.dart'; // Ensure this path is correct

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  @override
  void initState() {
    super.initState();
    _performLogout();
  }

  Future<void> _performLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored keys (authToken, userId, etc.)

    // Or use your AuthNotifier to update state as well
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    await authNotifier.setLoggedOut();

    // Go to login screen after a short delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Logging out...'),
          ],
        ),
      ),
    );
  }
}
