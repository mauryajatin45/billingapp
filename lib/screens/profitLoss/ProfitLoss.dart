import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  String _duration = 'Monthly';
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String _authToken = '';

  @override
  void initState() {
    super.initState();
    loadTokenAndFetch();
  }

  Future<void> loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken') ?? '';
    await fetchProfitLossData();
  }

  Future<void> fetchProfitLossData() async {
    try {
      final headers = {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      };

      final invoiceRes = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/billing/invoices'),
        headers: headers,
      );
      final inventoryRes = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/inventory/products'),
        headers: headers,
      );
      final expenseRes = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/expenses'),
        headers: headers,
      );

      final invoiceData = jsonDecode(invoiceRes.body)['data'] ?? [];
      final inventoryData = jsonDecode(inventoryRes.body)['data'] ?? [];
      final expenseData = jsonDecode(expenseRes.body)['data'] ?? [];

      Map<String, Map<String, double>> monthMap = {};

      // Process invoices with proper type conversion
      for (var inv in invoiceData) {
        String month = DateFormat('MMM').format(DateTime.parse(inv['date']));
        double amount = (inv['grandTotal'] as num?)?.toDouble() ?? 0.0;
        monthMap.putIfAbsent(month, () => {"revenue": 0.0, "expense": 0.0, "cost": 0.0});
        monthMap[month]!['revenue'] = (monthMap[month]!['revenue']! + amount);
      }

      // Process expenses with proper type conversion
      for (var exp in expenseData) {
        String month = DateFormat('MMM').format(DateTime.parse(exp['date']));
        double amount = (exp['amount'] as num?)?.toDouble() ?? 0.0;
        monthMap.putIfAbsent(month, () => {"revenue": 0.0, "expense": 0.0, "cost": 0.0});
        monthMap[month]!['expense'] = (monthMap[month]!['expense']! + amount);
      }

      // Process inventory costs
      for (var item in inventoryData) {
        String month = DateFormat('MMM').format(DateTime.now());
        double cost = ((item['price'] as num?)?.toDouble() ?? 0.0) * 
                     ((item['currentStock'] as num?)?.toDouble() ?? 0.0);
        monthMap.putIfAbsent(month, () => {"revenue": 0.0, "expense": 0.0, "cost": 0.0});
        monthMap[month]!['cost'] = (monthMap[month]!['cost']! + cost);
      }

      // Convert to list and sort by month
      List<Map<String, dynamic>> monthlyData = monthMap.entries.map((e) {
        return {
          "month": e.key,
          "revenue": e.value['revenue']!,
          "cost": e.value['cost']!,
          "expense": e.value['expense']!,
        };
      }).toList();

      monthlyData.sort((a, b) =>
          DateFormat('MMM').parse(a['month']).month.compareTo(DateFormat('MMM').parse(b['month']).month));

      setState(() {
        _data = monthlyData;
        _isLoading = false;
      });

      print("📊 Final chart data: $_data");
    } catch (e) {
      print('❌ Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  // Handle single data points by duplicating them
  List<FlSpot> _buildSpots(List<Map<String, dynamic>> data, String key) {
    if (data.isEmpty) return [];
    if (data.length == 1) {
      return [
        FlSpot(0, data[0][key] as double),
        FlSpot(1, data[0][key] as double),
      ];
    }
    return List.generate(data.length, 
        (i) => FlSpot(i.toDouble(), data[i][key] as double));
  }

  // Calculate max Y value based on revenue/expense only
  double _getMaxY() {
    if (_data.isEmpty) return 100;
    
    double maxValue = _data.fold(0.0, (max, item) {
      final currentMax = [
        item['revenue'] ?? 0.0,
        item['expense'] ?? 0.0,
      ].reduce((a, b) => a > b ? a : b);
      return currentMax > max ? currentMax : max;
    });

    return (maxValue * 1.5).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final double totalRevenue = _data.fold(0.0, (sum, item) => sum + (item['revenue'] as double));
    final double totalCost = _data.fold(0.0, (sum, item) => sum + (item['cost'] as double));
    final double totalExpense = _data.fold(0.0, (sum, item) => sum + (item['expense'] as double));

    final double margin = totalRevenue != 0
        ? ((totalRevenue - totalExpense) / totalRevenue * 100)
        : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Profit & Loss')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profit & Loss',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: _duration,
                        items: const [
                          DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'Quarterly', child: Text('Quarterly')),
                        ],
                        onChanged: (val) => setState(() => _duration = val!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double cardWidth = (constraints.maxWidth - 12) / 2 - 6;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _infoCard('Revenue', '₹${totalRevenue.toStringAsFixed(2)}', cardWidth),
                          _infoCard('Cost', '₹${totalCost.toStringAsFixed(2)}', cardWidth),
                          _infoCard('Expense', '₹${totalExpense.toStringAsFixed(2)}', cardWidth),
                          _infoCard('Margin', '${margin.toStringAsFixed(1)}%', cardWidth),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Revenue, Cost & Expense',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Note: Cost shown represents inventory value, not COGS',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: _getMaxY(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, _) {
                                int index = value.toInt();
                                if (index < 0 || index >= _data.length)
                                  return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _data[index]['month'],
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 48,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '₹${value.toInt()}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (List<LineBarSpot> spots) {
                              return spots.map((spot) {
                                return LineTooltipItem(
                                  '${spot.barIndex == 0 ? 'Revenue' : 'Expense'}: ₹${spot.y.toStringAsFixed(2)}',
                                  const TextStyle(color: Colors.white),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        lineBarsData: [
                          _buildLine(_data, 'revenue', Colors.green),
                          _buildLine(_data, 'expense', Colors.orange),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    child: BarChart(
                      BarChartData(
                        barGroups: _data.asMap().entries.map((e) {
                          final i = e.key;
                          final item = e.value;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: (item['cost'] ?? 0.0),
                                color: Colors.redAccent,
                                width: 16,
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                int index = value.toInt();
                                if (index < 0 || index >= _data.length)
                                  return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _data[index]['month'],
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 48,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '₹${(value/1000).toStringAsFixed(0)}K',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: true),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoCard(String label, String value, double cardWidth) {
    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLine(List<Map<String, dynamic>> data, String key, Color color) {
    return LineChartBarData(
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(show: true),
      spots: _buildSpots(data, key),
    );
  }
}