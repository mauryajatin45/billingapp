import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'layout/main_layout.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/salesReport/salesReport.dart';
import 'screens/taxSummary/TaxSummary.dart';
import 'screens/gstInvoice/GstInvoice.dart';
import 'screens/inventoryTracking/InventoryTracking.dart';
import 'screens/profitLoss/ProfitLoss.dart';
import 'screens/expenses/Expenses.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => DashboardScreen()),

        GoRoute(path: '/sales-report', builder: (_, __) => const SalesReport()),

        GoRoute(path: '/tax-summary', builder: (_, __) => const TaxSummary()),

        GoRoute(path: '/gst', builder: (_, __) => GstInvoice()),

        GoRoute(
          path: '/inventory',
          name: 'inventory',
          builder: (context, state) => const InventoryTrackingScreen(),
        ),

        // Add more routes here if needed
        GoRoute(
          path: '/profit',
          builder: (context, state) => const ProfitLossScreen(),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) => const ExpensesScreen(),
        ),
        // Add more routes here if needed
      ],
    ),
  ],
  initialLocation: '/dashboard',
);
