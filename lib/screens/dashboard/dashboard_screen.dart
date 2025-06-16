// lib/screens/dashboard/dashboard_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:billingapp/screens/dashboard/stat_card.dart';
import 'package:billingapp/screens/dashboard/invoice_table.dart';
import 'package:billingapp/screens/dashboard/charts/bar_chart_widget.dart';
import 'package:billingapp/screens/dashboard/charts/pie_chart_widget.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double totalBilling = 0;
  double totalExpenses = 0;
  int stockCount = 0;
  double profit = 0;

  List<Map<String, dynamic>> salesData = [];
  List<Map<String, dynamic>> expenseCategories = [];

  bool isLoading = true;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadAndFetchData();
  }

  Future<void> _loadAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');

    await Future.wait([
      _fetchBilling(),
      _fetchExpenses(),
      _fetchInventory(),
    ]);

    setState(() {
      profit = totalBilling - totalExpenses;
      salesData = [
        {'name': 'Billing', 'value': totalBilling},
        {'name': 'Expense', 'value': totalExpenses},
      ];
      isLoading = false;
    });
  }

  Future<void> _fetchBilling() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/billing/expenses'),
      headers: {'Authorization': 'Bearer $_authToken'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      totalBilling = 0;
      for (var invoice in data) {
        totalBilling += (invoice['grandTotal'] as num).toDouble();
      }
    }
  }

  Future<void> _fetchExpenses() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/expenses'),
      headers: {'Authorization': 'Bearer $_authToken'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      totalExpenses = 0;
      expenseCategories.clear();
      for (var item in data) {
        double amount = (item['amount'] as num).toDouble();
        totalExpenses += amount;
        final index = expenseCategories.indexWhere((e) => e['name'] == item['category']);
        if (index >= 0) {
          expenseCategories[index]['value'] += amount;
        } else {
          expenseCategories.add({'name': item['category'], 'value': amount});
        }
      }
    }
  }

  Future<void> _fetchInventory() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/inventory/products'),
      headers: {'Authorization': 'Bearer $_authToken'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      stockCount = data.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    StatCard(
                      title: "Total Billing",
                      value: "₹${totalBilling.toStringAsFixed(0)}",
                      subtitle: "this month",
                      icon: Icons.receipt_long,
                    ),
                    StatCard(
                      title: "Stock Available",
                      value: "$stockCount Items",
                      icon: Icons.inventory_2,
                    ),
                    StatCard(
                      title: "Profit This Month",
                      value: "₹${profit.toStringAsFixed(0)}",
                      icon: Icons.trending_up,
                    ),
                    StatCard(
                      title: "Total Expenses",
                      value: "₹${totalExpenses.toStringAsFixed(0)}",
                      icon: Icons.credit_card,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Latest Activities",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                const Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: InvoiceTable(),
                  ),
                ),
              ],
            ),
          );
  }
}
