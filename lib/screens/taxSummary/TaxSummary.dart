import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class TaxSummary extends StatefulWidget {
  const TaxSummary({Key? key}) : super(key: key);

  @override
  State<TaxSummary> createState() => _TaxSummaryState();
}

class _TaxSummaryState extends State<TaxSummary> {
  final List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul"];
  int selectedMonthIndex = 6;

  final List<Map<String, dynamic>> taxData = [
    {"month": "Jan", "tax": 1200},
    {"month": "Feb", "tax": 1500},
    {"month": "Mar", "tax": 1700},
    {"month": "Apr", "tax": 900},
    {"month": "May", "tax": 1100},
    {"month": "Jun", "tax": 1600},
    {"month": "Jul", "tax": 1800},
  ];

  final List<Map<String, dynamic>> taxCategories = [
    {"type": "CGST", "amount": 3500},
    {"type": "SGST", "amount": 3500},
    {"type": "IGST", "amount": 2000},
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
    final displayedTaxData = taxData.sublist(0, selectedMonthIndex + 1);
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final totalTaxPaid = taxData.fold<int>(
      0,
      (sum, item) => sum + (item['tax'] as int),
    );
    final highestMonth = taxData.reduce((a, b) => a['tax'] > b['tax'] ? a : b);
    final lowestMonth = taxData.reduce((a, b) => a['tax'] < b['tax'] ? a : b);

    final previousTax = selectedMonthIndex > 0 ? taxData[selectedMonthIndex - 1]['tax'] as int : 0;
    final currentTax = taxData[selectedMonthIndex]['tax'] as int;

    // Calculate maxY for y-axis (round up to nearest 500 for nice intervals)
    double maxY = taxData
        .map((e) => e['tax'] as int)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    maxY = (maxY / 500).ceil() * 500;

    // Calculate y-axis interval (divide maxY into 5 steps)
    double yInterval = maxY / 5;

    // Calculate total amount once to avoid repeated calculation inside map
    final double totalCategoryAmount = taxCategories.fold<double>(
      0,
      (sum, element) => sum + (element['amount'] as num).toDouble(),
    );

    // Calculate tax difference and decide icon/color
    final int taxDifference = currentTax - previousTax;
    IconData differenceIcon;
    Color differenceColor;

    if (taxDifference > 0) {
      differenceIcon = Icons.arrow_upward;
      differenceColor = Colors.green;
    } else if (taxDifference < 0) {
      differenceIcon = Icons.arrow_downward;
      differenceColor = Colors.red;
    } else {
      differenceIcon = Icons.remove;
      differenceColor = Colors.grey; // neutral color for no change
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tax Summary",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Month Selector + difference indicator
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
                onPressed: selectedMonthIndex < months.length - 1 ? nextMonth : null,
                icon: const Icon(Icons.chevron_right),
              ),
              const SizedBox(width: 12),
              Icon(
                differenceIcon,
                color: differenceColor,
              ),
              const SizedBox(width: 4),
              Text(
                taxDifference != 0
                    ? '${taxDifference.abs()} difference'
                    : 'No difference',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Line Chart
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Monthly Tax Paid",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: LineChart(
                      LineChartData(
                        maxY: maxY,
                        minY: 0,
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: yInterval,
                          verticalInterval: 1,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.withOpacity(0.3),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: yInterval,
                              reservedSize: 50,
                              getTitlesWidget: (value, _) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    formatter.format(value),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                int index = value.toInt();
                                if (index >= 0 && index < displayedTaxData.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      displayedTaxData[index]['month'],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              interval: 1,
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
                            spots: displayedTaxData
                                .asMap()
                                .entries
                                .map(
                                  (entry) => FlSpot(
                                    entry.key.toDouble(),
                                    (entry.value['tax'] as num).toDouble(),
                                  ),
                                )
                                .toList(),
                            isCurved: true,
                            color: Colors.teal,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
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

          // Tax Category Breakdown with progress bars
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tax Category Breakdown",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: taxCategories.map((item) {
                      double percentage =
                          (item['amount'] as num).toDouble() / totalCategoryAmount * 100;

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['type'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "${formatter.format(item['amount'])} (${percentage.toStringAsFixed(1)}%)",
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[300],
                            color: Colors.deepOrangeAccent,
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Summary Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Summary",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text("Total Tax Paid: ${formatter.format(totalTaxPaid)}"),
                  Text("Highest Tax Month: ${highestMonth['month']} (${formatter.format(highestMonth['tax'])})"),
                  Text("Lowest Tax Month: ${lowestMonth['month']} (${formatter.format(lowestMonth['tax'])})"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
