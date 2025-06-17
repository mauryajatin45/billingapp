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

      // Create a map of products by ID for quick lookup
      final productMap = { for (var p in inventoryData) p['_id'] : p };

      Map<String, Map<String, double>> monthMap = {};

      // Helper function to initialize month entries safely
      void initMonth(String month) {
        monthMap.putIfAbsent(month, () => {
          "revenue": 0.0,
          "expense": 0.0,
          "cogs": 0.0
        });
      }

      // Process invoices - calculate revenue and COGS
      for (var inv in invoiceData) {
        String month = DateFormat('MMM').format(DateTime.parse(inv['date']));
        initMonth(month);
        
        // Calculate revenue (subtotal without taxes, shipping, etc.)
        double revenue = (inv['subtotal'] as num?)?.toDouble() ?? 0.0;
        monthMap[month]!['revenue'] = monthMap[month]!['revenue']! + revenue;
        
        // Calculate COGS (Cost of Goods Sold)
        double cogs = 0.0;
        for (var item in inv['items']) {
          String? productId = item['productId']?.toString();
          int quantity = item['quantity'] as int? ?? 0;
          
          // Get purchase price from product map
          if (productId != null && productMap.containsKey(productId)) {
            double purchasePrice = (productMap[productId]!['price'] as num?)?.toDouble() ?? 0.0;
            cogs += purchasePrice * quantity;
          }
        }
        monthMap[month]!['cogs'] = monthMap[month]!['cogs']! + cogs;
      }

      // Process expenses
      for (var exp in expenseData) {
        String month = DateFormat('MMM').format(DateTime.parse(exp['date']));
        initMonth(month);
        double amount = (exp['amount'] as num?)?.toDouble() ?? 0.0;
        monthMap[month]!['expense'] = monthMap[month]!['expense']! + amount;
      }

      // Convert to list and sort by month
      List<Map<String, dynamic>> monthlyData = monthMap.entries.map((e) {
        return {
          "month": e.key,
          "revenue": e.value['revenue']!,
          "cogs": e.value['cogs']!,
          "expense": e.value['expense']!,
        };
      }).toList();

      // Sort by month in calendar order
      monthlyData.sort((a, b) {
        try {
          final monthA = DateFormat('MMM').parse(a['month']);
          final monthB = DateFormat('MMM').parse(b['month']);
          return monthA.month.compareTo(monthB.month);
        } catch (e) {
          return 0;
        }
      });

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

  // Safe spot generation with null handling
  List<FlSpot> _buildSpots(List<Map<String, dynamic>> data, String key) {
    if (data.isEmpty) return [];
    return List.generate(
      data.length, 
      (i) => FlSpot(
        i.toDouble(), 
        (data[i][key] as num?)?.toDouble() ?? 0.0
      )
    );
  }

  // Calculate max Y value based on revenue/expense only
  double _getMaxY() {
    if (_data.isEmpty) return 100;
    
    double maxValue = _data.fold(0.0, (max, item) {
      final revenue = (item['revenue'] as num?)?.toDouble() ?? 0.0;
      final expense = (item['expense'] as num?)?.toDouble() ?? 0.0;
      final currentMax = revenue > expense ? revenue : expense;
      return currentMax > max ? currentMax : max;
    });

    return (maxValue * 1.5).ceilToDouble();
  }

  // Calculate max value for COGS chart
  double _getMaxYForCogs() {
    if (_data.isEmpty) return 100;
    
    double maxCogs = _data.fold(0.0, (max, item) {
      final cogs = (item['cogs'] as num?)?.toDouble() ?? 0.0;
      return cogs > max ? cogs : max;
    });

    return (maxCogs * 1.5).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    // Safe calculations with null fallback
    final double totalRevenue = _data.fold(0.0, (sum, item) => 
        sum + ((item['revenue'] as num?)?.toDouble() ?? 0.0));
    final double totalCogs = _data.fold(0.0, (sum, item) => 
        sum + ((item['cogs'] as num?)?.toDouble() ?? 0.0));
    final double totalExpense = _data.fold(0.0, (sum, item) => 
        sum + ((item['expense'] as num?)?.toDouble() ?? 0.0));
    
    final double grossProfit = totalRevenue - totalCogs;
    final double netProfit = grossProfit - totalExpense;
    
    final double grossMargin = totalRevenue != 0 ? (grossProfit / totalRevenue * 100) : 0;
    final double netMargin = totalRevenue != 0 ? (netProfit / totalRevenue * 100) : 0;

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
                          _infoCard(
                            'Revenue', 
                            '₹${totalRevenue.toStringAsFixed(2)}', 
                            cardWidth: cardWidth
                          ),
                          _infoCard(
                            'COGS', 
                            '₹${totalCogs.toStringAsFixed(2)}', 
                            cardWidth: cardWidth
                          ),
                          _infoCard(
                            'Expenses', 
                            '₹${totalExpense.toStringAsFixed(2)}', 
                            cardWidth: cardWidth
                          ),
                          _infoCard(
                            'Net Profit', 
                            '₹${netProfit.toStringAsFixed(2)}', 
                            secondLine: '${netMargin.toStringAsFixed(1)}% margin', 
                            cardWidth: cardWidth
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Revenue & Expenses',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                                if (index < 0 || index >= _data.length) {
                                  return const SizedBox.shrink();
                                }
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
                  const SizedBox(height: 32),
                  const Text(
                    'Gross Profit (Revenue - COGS)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxYForCogs(),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final revenue = (_data[groupIndex]['revenue'] as num?)?.toDouble() ?? 0.0;
                              final cogs = (_data[groupIndex]['cogs'] as num?)?.toDouble() ?? 0.0;
                              
                              return BarTooltipItem(
                                'Gross Profit: ₹${rod.toY.toStringAsFixed(2)}\n'
                                'Revenue: ₹${revenue.toStringAsFixed(2)}\n'
                                'COGS: ₹${cogs.toStringAsFixed(2)}',
                                const TextStyle(color: Colors.white),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index < 0 || index >= _data.length) {
                                  return const SizedBox.shrink();
                                }
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
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                        barGroups: _data.asMap().entries.map((e) {
                          final i = e.key;
                          final item = e.value;
                          final revenue = (item['revenue'] as num?)?.toDouble() ?? 0.0;
                          final cogs = (item['cogs'] as num?)?.toDouble() ?? 0.0;
                          final grossProfit = revenue - cogs;
                          
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: grossProfit,
                                color: grossProfit >= 0 ? Colors.green : Colors.red,
                                width: 22,
                                borderRadius: BorderRadius.zero,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'COGS (Cost of Goods Sold)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: BarChart(
                      BarChartData(
                        maxY: _getMaxYForCogs(),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                'COGS: ₹${rod.toY.toStringAsFixed(2)}\n'
                                'Products Cost',
                                const TextStyle(color: Colors.white),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                int index = value.toInt();
                                if (index < 0 || index >= _data.length) {
                                  return const SizedBox.shrink();
                                }
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
                        barGroups: _data.asMap().entries.map((e) {
                          final i = e.key;
                          final item = e.value;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: (item['cogs'] as num?)?.toDouble() ?? 0.0,
                                color: Colors.blue,
                                width: 16,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoCard(String label, String value, {String? secondLine, required double cardWidth}) {
    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(
              color: Colors.grey, 
              fontSize: 14,
              fontWeight: FontWeight.w500
            )),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: Colors.blue
            )),
            if (secondLine != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(secondLine, style: const TextStyle(
                  fontSize: 12, 
                  color: Colors.green,
                  fontWeight: FontWeight.w500
                )),
              ),
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
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      spots: _buildSpots(data, key),
    );
  }
}