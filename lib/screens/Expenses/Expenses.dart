import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String selectedMonth = "April 2024";

  final List<Map<String, dynamic>> expenseTrends = [
    {"month": "Jan", "value": 0},
    {"month": "Feb", "value": 300},
    {"month": "Mar", "value": 400},
    {"month": "Apr", "value": 900},
  ];

  final List<Map<String, dynamic>> expenseList = [
    {
      "date": "05/04/2024",
      "category": "Staff Salary",
      "amount": 6000,
      "note": "April Salary"
    },
    {
      "date": "03/04/2024",
      "category": "Utilities",
      "amount": 800,
      "note": "Electricity bill"
    },
    {
      "date": "02/04/2024",
      "category": "Office Supplies",
      "amount": 150,
      "note": ""
    },
  ];

  int _calculateTotal() {
    return expenseList.fold(0, (sum, item) => sum + (item['amount'] as int));
  }

  @override
  Widget build(BuildContext context) {
    final latestExpense = expenseList.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Overview'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: selectedMonth,
              underline: const SizedBox(),
              onChanged: (val) => setState(() {
                if (val != null) selectedMonth = val;
              }),
              items: const [
                DropdownMenuItem(
                  value: "March 2024",
                  child: Text("March 2024"),
                ),
                DropdownMenuItem(
                  value: "April 2024",
                  child: Text("April 2024"),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1) Latest Expense at top
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LATEST EXPENSE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          latestExpense['date'],
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "\$${latestExpense['amount']}",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latestExpense['category'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latestExpense['note'].isEmpty
                          ? "No notes"
                          : latestExpense['note'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2) Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= expenseTrends.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                expenseTrends[idx]['month'],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 200,
                        ),
                      ),
                      topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(color: Colors.black12),
                        left: BorderSide(color: Colors.black12),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        spots: [
                          for (int i = 0; i < expenseTrends.length; i++)
                            FlSpot(
                              i.toDouble(),
                              (expenseTrends[i]['value'] as num).toDouble(),
                            ),
                        ],
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3) Expense History header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EXPENSE HISTORY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Total: \$${_calculateTotal()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 4) Expense table
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowHeight: 0, // hide default headings
                    border: TableBorder(
                      top: const BorderSide(color: Colors.black12, width: 1),
                      bottom: const BorderSide(color: Colors.black12, width: 1),
                      left: const BorderSide(color: Colors.black12, width: 1),
                      right: const BorderSide(color: Colors.black12, width: 1),
                      horizontalInside:
                          const BorderSide(color: Colors.black12, width: 1),
                      verticalInside:
                          const BorderSide(color: Colors.black12, width: 1),
                    ),
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text("Date")),
                      DataColumn(label: Text("Category")),
                      DataColumn(label: Text("Amount")),
                      DataColumn(label: Text("Note")),
                    ],
                    rows: expenseList.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item['date'])),
                        DataCell(Text(item['category'])),
                        DataCell(Text(
                          "\$${item['amount']}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        )),
                        DataCell(Text(
                          item['note'].isEmpty ? "—" : item['note'],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Fixed FAB bottom-right
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text("Add Expense"),
      ),
    );
  }
}
