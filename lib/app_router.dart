import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Layout
import 'layout/main_layout.dart';

// Screens
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/salesReport/salesReport.dart';
import 'screens/taxSummary/TaxSummary.dart';
import 'screens/gstInvoice/GstInvoice.dart';
import 'screens/inventoryTracking/InventoryTracking.dart';
import 'screens/profitLoss/ProfitLoss.dart';
import 'screens/expenses/Expenses.dart';
import 'screens/parties/Parties.dart';
import 'screens/settings/Settings.dart';
import 'screens/reports/Reports.dart';

// Auth Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/otp_verification_screen.dart';

// App Router
final GoRouter appRouter = GoRouter(
  initialLocation: '/login', // Changed to login as initial route
  routes: [
    // Auth routes (outside ShellRoute as they don't need the main layout)
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(
      path: '/verify-otp',
      builder: (_, state) =>
          OtpVerificationScreen(mobile: state.extra as String),
    ),

    // Main app routes with ShellRoute for the layout
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        // Dashboard Screen
        GoRoute(path: '/dashboard', builder: (_, __) => DashboardScreen()),

        // Sales Report Screen
        GoRoute(path: '/sales-report', builder: (_, __) => const SalesReport()),

        // Tax Summary Screen
        GoRoute(path: '/tax-summary', builder: (_, __) => const TaxSummary()),

        // GST Invoice Screen
        GoRoute(path: '/gst', builder: (_, __) => GstInvoice()),

        // Inventory Tracking Screen
        GoRoute(
          path: '/inventory',
          name: 'inventory',
          builder: (context, state) => const InventoryTrackingScreen(),
        ),

        // Profit Loss Screen
        GoRoute(
          path: '/profit',
          builder: (context, state) => const ProfitLossScreen(),
        ),

        // Expenses Screen
        GoRoute(
          path: '/expenses',
          builder: (context, state) => const ExpensesScreen(),
        ),

        // Parties Screen
        GoRoute(
          path: '/parties',
          builder: (context, state) => const PartiesScreen(),
        ),

        GoRoute(
          path: '/reports',
          name: 'reports',
          builder: (context, state) => const ReportsScreen(),
        ),

        // Settings Routes
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
          routes: [
            GoRoute(
              path: 'user',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: 'preferences',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: 'billing',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: 'notifications',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: 'security',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: 'integrations',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: 'appearance',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: 'account',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
  // Redirect logic for authentication
  redirect: (BuildContext context, GoRouterState state) async {
    final prefs = await SharedPreferences.getInstance();
    final bool loggedIn = prefs.getString('authToken') != null;
    final bool goingToAuth =
        state.matchedLocation.startsWith('/login') ||
        state.matchedLocation.startsWith('/signup') ||
        state.matchedLocation.startsWith('/verify-otp');

    if (!loggedIn && !goingToAuth) return '/login';
    if (loggedIn && goingToAuth) return '/dashboard';

    return null;
  },
);
