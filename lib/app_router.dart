import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
import 'screens/settings/Settings.dart'; // Import the settings page here
import 'screens/reports/Reports.dart';

// App Router
final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard', // Set the initial route
  routes: [
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
          builder: (context, state) =>
              const SettingsPage(), // Correctly reference SettingsPage
          routes: [
            // Sub-routes for settings pages (same SettingsPage, just different sections)
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

        // Add additional routes here
      ],
    ),
  ],
);
