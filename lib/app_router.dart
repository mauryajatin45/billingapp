// app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'layout/main_layout.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/salesReport/salesReport.dart';
import 'screens/taxSummary/TaxSummary.dart';
import 'screens/gst_invoice/gst_invoice.dart';
import 'screens/inventoryTracking/InventoryTracking.dart';
import 'screens/profitLoss/ProfitLoss.dart';
import 'screens/expenses/Expenses.dart';
import 'screens/parties/Parties.dart';
import 'screens/settings/Settings.dart';
import 'screens/reports/Reports.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/logout.dart';

class AuthNotifier extends ChangeNotifier {
  bool _loggedIn;

  AuthNotifier(this._loggedIn);
  bool get loggedIn => _loggedIn;

  static Future<AuthNotifier> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    return AuthNotifier(token != null);
  }

  Future<void> setLoggedIn(String token) async {
    if (token.isEmpty) {
      throw ArgumentError('Token cannot be empty');
    }

    print('Storing token: $token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    _loggedIn = true;
    notifyListeners();

    // Verify storage
    final savedToken = prefs.getString('authToken');
    print('Token saved: ${savedToken != null && savedToken.isNotEmpty}');
  }

  Future<void> setLoggedOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    _loggedIn = false;
    notifyListeners();
  }
}

/// Exported GoRouter instance – this will be assigned after initialization.
late GoRouter appRouter;

/// Setup method to initialize AuthNotifier and router
Future<Widget> initializeApp() async {
  final authNotifier = await AuthNotifier.initialize();

  appRouter = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: '/verify-otp',
        builder: (_, state) {
          final mobile = state.extra as String?;
          return OtpVerificationScreen(mobile: mobile ?? '');
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => DashboardScreen()),
          GoRoute(
            path: '/sales-report',
            builder: (_, __) => const SalesReport(),
          ),
          GoRoute(path: '/tax-summary', builder: (_, __) => const TaxSummaryScreen()),
          GoRoute(path: '/gst', builder: (_, __) =>  GstInvoicePage()),
          GoRoute(
            path: '/inventory',
            builder: (_, __) => const InventoryTrackingScreen(),
          ),
          GoRoute(
            path: '/profit',
            builder: (_, __) => const ProfitLossScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (_, __) => const ExpensesScreen(),
          ),
          GoRoute(path: '/parties', builder: (_, __) => const PartiesScreen()),
          GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/logout', builder: (_, __) => const LogoutScreen()),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsPage(),
            routes: [
              GoRoute(path: 'user', builder: (_, __) => const SettingsPage()),
              GoRoute(
                path: 'preferences',
                builder: (_, __) => const SettingsPage(),
              ),
              GoRoute(
                path: 'billing',
                builder: (_, __) => const SettingsPage(),
              ),
              GoRoute(
                path: 'notifications',
                builder: (_, __) => const SettingsPage(),
              ),
              GoRoute(
                path: 'security',
                builder: (_, __) => const SettingsPage(),
              ),
              GoRoute(
                path: 'integrations',
                builder: (_, __) => const SettingsPage(),
              ),
              GoRoute(
                path: 'appearance',
                builder: (_, __) => const SettingsPage(),
              ),
              GoRoute(
                path: 'account',
                builder: (_, __) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final loggedIn = authNotifier.loggedIn;
      final location = state.uri.toString();
      final goingToAuth = location == '/login' || location == '/signup' || location == '/verify-otp';
      if (!loggedIn && !goingToAuth) return '/login';
      if (loggedIn && goingToAuth) return '/dashboard';
      return null;
    },
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );

  return ChangeNotifierProvider.value(
    value: authNotifier,
    child: const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Billing App',
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
    );
  }
}
