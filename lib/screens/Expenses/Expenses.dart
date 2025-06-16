import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String selectedMonth = "";
  List<Map<String, dynamic>> _expenseList = [];
  List<Map<String, dynamic>> _expenseTrends = [];
  bool _isLoading = false;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');
    await fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/expenses'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'];
        _expenseList = data.map((e) {
          final date = DateTime.parse(e['date']);
          return {
            'date': "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}",
            'category': e['category'],
            'amount': e['amount'],
            'note': e['description'] ?? '',
          };
        }).toList();

        final Map<String, double> trends = {};
        for (var e in _expenseList) {
          final parts = e['date'].split("/");
          final monthKey = "${parts[1]}/${parts[2]}";
          trends[monthKey] =
              (trends[monthKey] ?? 0) + (e['amount'] as num).toDouble();
        }

        _expenseTrends = trends.entries.map((e) {
          return {'month': e.key, 'value': e.value};
        }).toList();

        final months =
            _expenseTrends.map((e) => e['month'] as String).toSet().toList();
        if (months.isNotEmpty && !months.contains(selectedMonth)) {
          selectedMonth = months.first;
        }
      } else {
        print('Failed to fetch expenses: ${response.body}');
      }
    } catch (e) {
      print('Error fetching expenses: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _createExpense(Map<String, dynamic> newExpense) async {
    final url = Uri.parse('http://10.0.2.2:3000/api/expenses');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(newExpense),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added successfully')),
        );
        await fetchExpenses();
      } else {
        print("❌ Failed: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add expense: ${response.body}')),
        );
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
  }

  void _showAddExpenseDialog() {
    final _categoryController = TextEditingController();
    final _amountController = TextEditingController();
    final _noteController = TextEditingController();
    final _paymentMethodController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _paymentMethodController,
                decoration: const InputDecoration(
                  labelText: 'Payment Method (cash/card/upi/etc)',
                ),
              ),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final category = _categoryController.text.trim();
              final amount = double.tryParse(_amountController.text) ?? 0;
              final paymentMethod =
                  _paymentMethodController.text.trim().toLowerCase();
              final note = _noteController.text.trim();

              if (category.isEmpty || amount <= 0 || paymentMethod.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                  ),
                );
                return;
              }

              final newExpense = {
                "category": category,
                "amount": amount,
                "paymentMethod": paymentMethod,
                "description": note,
              };

              _createExpense(newExpense);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  int _calculateTotal() =>
      _expenseList.fold(0, (sum, e) => sum + (e['amount'] as int));

  @override
  Widget build(BuildContext context) {
    final months =
        _expenseTrends.map((e) => e['month'] as String).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Overview'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: months.contains(selectedMonth) ? selectedMonth : null,
              hint: const Text('Select Month'),
              underline: const SizedBox(),
              onChanged: (val) =>
                  setState(() => selectedMonth = val ?? selectedMonth),
              items: months.map((month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  if (_expenseList.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildLatestExpenseCard(_expenseList.first),
                    ),

                  // Chart
                  if (_expenseTrends.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, _) {
                                    final idx = value.toInt();
                                    if (idx < 0 ||
                                        idx >= _expenseTrends.length) {
                                      return const SizedBox();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        _expenseTrends[idx]['month'],
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  },
                                  interval: 1,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 100,
                                ),
                              ),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
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
                                spots: List.generate(_expenseTrends.length,
                                    (i) {
                                  return FlSpot(
                                    i.toDouble(),
                                    (_expenseTrends[i]['value'] as num)
                                        .toDouble(),
                                  );
                                }),
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

                  const SizedBox(height: 8),

                  // Scrollable DataTable
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                Colors.grey.shade200,
                              ),
                              columns: const [
                                DataColumn(label: Text("Date")),
                                DataColumn(label: Text("Category")),
                                DataColumn(label: Text("Amount")),
                                DataColumn(label: Text("Note")),
                              ],
                              rows: _expenseList.map((item) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(item['date'])),
                                    DataCell(Text(item['category'])),
                                    DataCell(Text("₹${item['amount']}")),
                                    DataCell(
                                      Text(item['note'].toString().isEmpty
                                          ? '—'
                                          : item['note']),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add Expense"),
      ),
    );
  }

  Widget _buildLatestExpenseCard(Map<String, dynamic> expense) {
    return Container(
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
                expense['date'],
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "₹${expense['amount']}",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            expense['category'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            expense['note'].isEmpty ? "No notes" : expense['note'],
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
