import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesReport extends StatefulWidget {
  const SalesReport({Key? key}) : super(key: key);

  @override
  State<SalesReport> createState() => _SalesReportState();
}

class _SalesReportState extends State<SalesReport> {
  int selectedMonthIndex = DateTime.now().month - 1;
  final List<String> months = List.generate(
    12,
    (i) => DateFormat('MMM').format(DateTime(2025, i + 1)),
  );

  List<Map<String, dynamic>> monthlySales = [];
  List<Map<String, dynamic>> productRevenue = [];
  List<Map<String, dynamic>> invoiceDetails = [];

  bool isLoading = true;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');
    await _fetchSalesDataForMonth(selectedMonthIndex + 1);
  }
  Future<void> _fetchSalesDataForMonth(int month) async {
    setState(() => isLoading = true);

    final startDate = DateTime(2025, month, 1);
    final endDate = DateTime(2025, month + 1, 1);

    final response = await http.get(
      Uri.parse(
        'http://10.0.2.2:3000/api/reports/sales?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}',
      ),
      headers: {'Authorization': 'Bearer $_authToken'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      double totalRevenue = 0;
      productRevenue.clear();
      invoiceDetails.clear();

      for (var invoice in data) {
        totalRevenue += (invoice['totalRevenue'] as num).toDouble();
        invoiceDetails.add(invoice);

        for (var product in invoice['productDetails']) {
          final idx = productRevenue.indexWhere(
              (p) => p['name'] == product['productName']);
          if (idx >= 0) {
            productRevenue[idx]['value'] +=
                (product['revenue'] as num).toDouble();
          } else {
            productRevenue.add({
              'name': product['productName'],
              'value': (product['revenue'] as num).toDouble(),
            });
          }
        }
      }

      monthlySales = [
        {'month': months[month - 1], 'sales': totalRevenue},
      ];
    }

    setState(() => isLoading = false);
  }

  void previousMonth() {
    if (selectedMonthIndex > 0) {
      selectedMonthIndex--;
      _fetchSalesDataForMonth(selectedMonthIndex + 1);
    }
  }

  void nextMonth() {
    if (selectedMonthIndex < 11) {
      selectedMonthIndex++;
      _fetchSalesDataForMonth(selectedMonthIndex + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text("Sales Report")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: previousMonth,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        months[selectedMonthIndex],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: nextMonth,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMonthlySalesCard(formatter),
                  const SizedBox(height: 16),
                  _buildProductRevenueCard(formatter),
                  const SizedBox(height: 16),
                  _buildInvoiceDetails(formatter),
                ],
              ),
            ),
    );
  }
 Widget _buildMonthlySalesCard(NumberFormat formatter) {
  final double maxY = (monthlySales[0]['sales'] as num).toDouble();
  final double yStep = (maxY / 4).ceilToDouble();

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Monthly Sales Overview",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                barGroups: monthlySales.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final sales = (entry.value['sales'] as num).toDouble();

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: sales,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.teal,
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            monthlySales[value.toInt()]['month'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: yStep,
                      getTitlesWidget: (value, _) {
                        String label;
                        if (value >= 100000) {
                          label = '₹${(value / 100000).toStringAsFixed(1)}L';
                        } else if (value >= 1000) {
                          label = '₹${(value / 1000).toStringAsFixed(1)}K';
                        } else {
                          label = '₹${value.toStringAsFixed(0)}';
                        }
                        return Text(label, style: const TextStyle(fontSize: 12));
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
                maxY: maxY + yStep,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildProductRevenueCard(NumberFormat formatter) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Product-wise Revenue",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.5),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFEFF3F6)),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Product Name",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Revenue",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...productRevenue.map(
                  (product) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(product['name']),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(formatter.format(product['value'])),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildInvoiceDetails(NumberFormat formatter) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Invoice Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(2),
              },
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFEFF3F6)),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text("Invoice #", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text("Tax", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ...invoiceDetails.map(
                  (invoice) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(invoice['invoiceNumber']),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(DateFormat('dd MMM yyyy').format(DateTime.parse(invoice['invoiceDate']))),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(invoice['totalQuantity'].toString()),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(formatter.format(invoice['totalTax'])),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(formatter.format(invoice['grandTotal'])),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}