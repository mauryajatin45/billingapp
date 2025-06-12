import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesReport extends StatefulWidget {
  const SalesReport({Key? key}) : super(key: key);

  @override
  State<SalesReport> createState() => _SalesReportState();
}

class _SalesReportState extends State<SalesReport> {
  final List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul"];

  int selectedMonthIndex = 6; // July

  final List<Map<String, dynamic>> monthlySales = [
    {"month": "Jan", "sales": 24000},
    {"month": "Feb", "sales": 18000},
    {"month": "Mar", "sales": 22000},
    {"month": "Apr", "sales": 27800},
    {"month": "May", "sales": 18900},
    {"month": "Jun", "sales": 23900},
    {"month": "Jul", "sales": 25000},
  ];

  final List<Map<String, dynamic>> productRevenue = [
    {"name": "Product A", "value": 40000},
    {"name": "Product B", "value": 30000},
    {"name": "Product C", "value": 20000},
    {"name": "Product D", "value": 10000},
  ];

  final List<Color> colors = [
    Color(0xFFFF6384),
    Color(0xFF36A2EB),
    Color(0xFFFFCD56),
    Color(0xFF4BC0C0),
  ];

  void previousMonth() {
    if (selectedMonthIndex > 0) {
      setState(() {
        selectedMonthIndex--;
      });
    }
  }

  void nextMonth() {
    if (selectedMonthIndex < months.length - 1) {
      setState(() {
        selectedMonthIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedSales = monthlySales.sublist(0, selectedMonthIndex + 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sales Report",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: selectedMonthIndex > 0 ? previousMonth : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                months[selectedMonthIndex],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: selectedMonthIndex < months.length - 1
                    ? nextMonth
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),

          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildMonthlySalesCard(displayedSales)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildProductRevenueCard()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildMonthlySalesCard(displayedSales),
                    const SizedBox(height: 16),
                    _buildProductRevenueCard(),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 24),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Summary",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text("Total Revenue: ₹1,20,000"),
                  Text("Top Selling Product: Product A"),
                  Text("Average Monthly Sales: ₹21,000"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySalesCard(List<Map<String, dynamic>> salesData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Monthly Sales Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              width: double.infinity,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (salesData
                          .map((e) => e['sales'] as int)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${value.toInt().toString().replaceAllMapped(RegExp(r"(?=(\d{3})+(?!\d))"), (match) => ",")}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.left,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < salesData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(salesData[index]['month']),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: salesData.asMap().entries.map((entry) {
                    int idx = entry.key;
                    int sales = entry.value['sales'] as int;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: sales.toDouble(),
                          color: Colors.red,
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

  Widget _buildProductRevenueCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Product-wise Revenue",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              width: double.infinity,
              child: PieChart(
                PieChartData(
                  sections: productRevenue.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var data = entry.value;
                    final value = data['value'] as int;
                    final name = data['name'] as String;
                    final color = colors[idx % colors.length];
                    return PieChartSectionData(
                      color: color,
                      value: value.toDouble(),
                      title: name,
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                  pieTouchData: PieTouchData(enabled: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
