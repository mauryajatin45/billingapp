import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  String _duration = 'Monthly';

  final List<Map<String, dynamic>> _data = [
    {"month": "May", "revenue": 3000, "cost": 1000, "expense": 1200},
    {"month": "Feb", "revenue": 7000, "cost": 2000, "expense": 2500},
    {"month": "Mar", "revenue": 15000, "cost": 4000, "expense": 5000},
    {"month": "Apr", "revenue": 13000, "cost": 3500, "expense": 4500},
    {"month": "Jun", "revenue": 14000, "cost": 5000, "expense": 6000},
    {"month": "Jul", "revenue": 20000, "cost": 8000, "expense": 9000},
    {"month": "Aug", "revenue": 24000, "cost": 10000, "expense": 11000},
    {"month": "Sep", "revenue": 27000, "cost": 13000, "expense": 14000},
  ];

  @override
  Widget build(BuildContext context) {
    final int totalRevenue = _data.fold(
      0,
      (sum, item) => sum + (item['revenue'] as int),
    );
    final int totalCost = _data.fold(
      0,
      (sum, item) => sum + (item['cost'] as int),
    );
    final int totalExpense = _data.fold(
      0,
      (sum, item) => sum + (item['expense'] as int),
    );

    final double margin = totalRevenue != 0
        ? ((totalRevenue - totalExpense) / totalRevenue * 100)
        : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Profit & Loss')),
      body: SingleChildScrollView(
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
                    DropdownMenuItem(
                      value: 'Quarterly',
                      child: Text('Quarterly'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _duration = val!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth =
                    (constraints.maxWidth - 12) / 2 -
                    6; // 12px total spacing, 6px per gap

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _infoCard(
                      'Revenue',
                      '\$${totalRevenue.toString()}',
                      cardWidth,
                    ),
                    _infoCard('Cost', '\$${totalCost.toString()}', cardWidth),
                    _infoCard(
                      'Expense',
                      '\$${totalExpense.toString()}',
                      cardWidth,
                    ),
                    _infoCard(
                      'Auto-calculated',
                      '${margin.toStringAsFixed(1)}%',
                      cardWidth,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
            const Text(
              'Revenue, Cost & Expense',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
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
                          return Text(
                            _data[index]['month'],
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize:
                            48, // 🛠️ Fix: Add space for Y-axis numbers
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    _buildLine(_data, 'revenue', Colors.blue),
                    _buildLine(_data, 'cost', Colors.lightBlue),
                    _buildLine(_data, 'expense', Colors.blue.shade200),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    // Export to PDF logic
                  },
                  child: const Text('Export to PDF'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    // Export to Excel logic
                  },
                  child: const Text('Export to Excel'),
                ),
              ],
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
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLine(
    List<Map<String, dynamic>> data,
    String key,
    Color color,
  ) {
    return LineChartBarData(
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: FlDotData(show: false),
      spots: [
        for (int i = 0; i < data.length; i++)
          FlSpot(i.toDouble(), (data[i][key] as num).toDouble()),
      ],
    );
  }
}
