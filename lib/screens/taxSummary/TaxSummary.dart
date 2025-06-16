import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaxSummaryScreen extends StatefulWidget {
  const TaxSummaryScreen({super.key});

  @override
  State<TaxSummaryScreen> createState() => _TaxSummaryScreenState();
}

class _TaxSummaryScreenState extends State<TaxSummaryScreen> {
  List<Map<String, dynamic>> taxData = [];
  int selectedMonthIndex = 0;
  bool isLoading = true;
  String? _authToken;

  double get totalTax =>
      taxData.fold(0.0, (sum, e) => sum + (e['tax'] as double));

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');
    await _fetchTaxData();
  }

  Future<void> _fetchTaxData() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/billing/invoices'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        final List invoices = jsonDecode(response.body)['data'];

        final Map<String, double> monthlyTax = {};
        for (var invoice in invoices) {
          if (invoice['totalTax'] != null && invoice['date'] != null) {
            final date = DateTime.parse(invoice['date']);
            final month = DateFormat('MMM').format(date);
            monthlyTax[month] =
                (monthlyTax[month] ?? 0.0) +
                (invoice['totalTax'] as num).toDouble();
          }
        }

        final sortedMonths = monthlyTax.keys.toList()
          ..sort(
            (a, b) => DateFormat(
              'MMM',
            ).parse(a).month.compareTo(DateFormat('MMM').parse(b).month),
          );

        taxData = sortedMonths
            .map((m) => {'month': m, 'tax': monthlyTax[m]!})
            .toList();

        selectedMonthIndex = taxData.length - 1;
      } else {
        print("\u274c Error: ${response.body}");
      }
    } catch (e) {
      print("\u274c Exception: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final displayedData = taxData.take(selectedMonthIndex + 1).toList();

    final current = taxData.isNotEmpty
        ? taxData[selectedMonthIndex]['tax'] as double
        : 0;
    final previous = selectedMonthIndex > 0
        ? taxData[selectedMonthIndex - 1]['tax'] as double
        : 0;
    final diff = current - previous;

    final IconData diffIcon = diff > 0
        ? Icons.arrow_upward
        : diff < 0
        ? Icons.arrow_downward
        : Icons.remove;
    final Color diffColor = diff > 0
        ? Colors.green
        : diff < 0
        ? Colors.red
        : Colors.grey;

    double maxY = taxData.isNotEmpty
        ? taxData.map((e) => e['tax'] as double).reduce((a, b) => a > b ? a : b)
        : 1000;
    maxY = (maxY / 500).ceil() * 500;
    double interval = maxY / 5;

    final cgst = totalTax / 2;
    final sgst = totalTax / 2;

    return Scaffold(
      appBar: AppBar(title: const Text("Tax Summary")),
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
                        onPressed: selectedMonthIndex > 0
                            ? () => setState(() => selectedMonthIndex--)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        taxData[selectedMonthIndex]['month'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: selectedMonthIndex < taxData.length - 1
                            ? () => setState(() => selectedMonthIndex++)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                      const SizedBox(width: 12),
                      Icon(diffIcon, color: diffColor),
                      const SizedBox(width: 4),
                      Text(
                        diff == 0
                            ? 'No Change'
                            : '${diff.abs().round()} difference',
                        style: TextStyle(color: diffColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Monthly Tax Paid",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 250,
                            child: LineChart(
                              LineChartData(
                                minY: 0,
                                maxY: maxY,
                                gridData: FlGridData(
                                  show: true,
                                  horizontalInterval: interval,
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: interval,
                                      reservedSize: 50,
                                      getTitlesWidget: (value, _) => Text(
                                        formatter.format(value),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, _) {
                                        final idx = value.toInt();
                                        if (idx >= 0 &&
                                            idx < displayedData.length) {
                                          return Text(
                                            displayedData[idx]['month'],
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.grey),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: displayedData
                                        .asMap()
                                        .entries
                                        .map(
                                          (e) => FlSpot(
                                            e.key.toDouble(),
                                            (e.value['tax'] as double),
                                          ),
                                        )
                                        .toList(),
                                    isCurved: true,
                                    color: Colors.teal,
                                    barWidth: 3,
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.teal.withOpacity(0.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Tax Category Breakdown",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ...[
                            {"type": "CGST", "amount": cgst},
                            {"type": "SGST", "amount": sgst},
                          ].map((item) {
                            double percent =
                                (item['amount'] as double) / totalTax * 100;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['type'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "${formatter.format(item['amount'])} (${percent.toStringAsFixed(1)}%)",
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percent / 100,
                                  color: Colors.orange,
                                  backgroundColor: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          }).toList(),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Summary",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text("Total Tax Paid: ${formatter.format(totalTax)}"),
                          if (taxData.isNotEmpty) ...[
                            Text(
                              "Highest Month: ${(taxData.cast<Map<String, dynamic>>().reduce((a, b) => (a['tax'] as double) > (b['tax'] as double) ? a : b))['month']}",
                            ),

                            Text(
                              "Lowest Month: ${(taxData.cast<Map<String, dynamic>>().reduce((a, b) => (a['tax'] as double) < (b['tax'] as double) ? a : b))['month']}",
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
