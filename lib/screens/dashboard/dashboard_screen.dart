// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:billingapp/screens/dashboard/stat_card.dart';
import 'package:billingapp/screens/dashboard/invoice_table.dart';
import 'package:billingapp/screens/dashboard/charts/bar_chart_widget.dart';
import 'package:billingapp/screens/dashboard/charts/pie_chart_widget.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({Key? key}) : super(key: key);

  final salesData = [
    {'name': 'Monthly', 'value': 30000},
    {'name': 'Expense', 'value': 15000},
  ];

  final expenseCategories = [
    {'name': 'Rent', 'value': 10000},
    {'name': 'Utilities', 'value': 3000},
    {'name': 'Misc', 'value': 7000},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stat Cards Row
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              StatCard(
                title: "Total Invoices",
                value: "₹1,20,000",
                subtitle: "this month",
                icon: Icons.receipt_long,
              ),
              StatCard(
                title: "Stock Available",
                value: "230 Items",
                icon: Icons.inventory_2,
              ),
              StatCard(
                title: "Profit This Month",
                value: "₹35,000",
                icon: Icons.trending_up,
              ),
              StatCard(
                title: "Total Expenses",
                value: "₹15,000",
                icon: Icons.credit_card,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Monthly Sales - Full Width
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Monthly Sales",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChartWidget(data: salesData),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Expense Category - Full Width, below Monthly Sales
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Expense Category",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChartWidget(data: expenseCategories),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Latest Activities
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Latest Activities",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: InvoiceTable(),
            ),
          ),
        ],
      ),
    );
  }
}
