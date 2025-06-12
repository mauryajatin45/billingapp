// lib/screens/dashboard/charts/pie_chart_widget.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  PieChartWidget({Key? key, required this.data}) : super(key: key);

  final List<Color> colors = [
    Colors.blue.shade700,
    Colors.green.shade600,
    Colors.cyan.shade400,
  ];

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: data.asMap().entries.map((entry) {
          final idx = entry.key;
          final name = entry.value['name'] as String;
          final value = entry.value['value'] as int;
          return PieChartSectionData(
            color: colors[idx % colors.length],
            value: value.toDouble(),
            title: '$name\n$value',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titlePositionPercentageOffset: 0.6,
          );
        }).toList(),
      ),
    );
  }
}
