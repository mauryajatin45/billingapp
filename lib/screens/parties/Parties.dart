import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterText = '';

  final List<Map<String, String>> _allParties = [
    {
      'name': 'Sharma Traders',
      'contact': '9876543210',
      'gstin': '24ABCDE12334F1Z5',
      'address': 'Gujarat',
    },
    {
      'name': 'Kiran Enterprises',
      'contact': '9988776655',
      'gstin': '27QLMNB98765P2A3',
      'address': 'Maharashtra',
    },
    {
      'name': 'Garg Distributors',
      'contact': '9123456780',
      'gstin': '29YRTP90087K1ZT',
      'address': 'Karnataka',
    },
    {
      'name': 'Patel & Co.',
      'contact': '9900887766',
      'gstin': '23AWRL4562J8X9',
      'address': 'Madhya Pradesh',
    },
  ];

  List<Map<String, String>> get _filteredParties {
    final query = _searchController.text.toLowerCase();
    return _allParties.where((p) {
      final matchesName = p['name']!.toLowerCase().contains(query);
      final matchesFilter = _filterText.isEmpty || p['address'] == _filterText;
      return matchesName && matchesFilter;
    }).toList();
  }

  List<BarChartGroupData> get _chartData {
    return _filteredParties.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;
      final value = p['contact']!.length.toDouble();
      
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            fromY: 0,
            color: Colors.blue,
            width: 22,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredParties;
    final states = _allParties.map((p) => p['address']!).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search + Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search parties',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButton<String>(
                      value: _filterText.isEmpty ? null : _filterText,
                      hint: const Text('Filter'),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.filter_alt),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('All States'),
                        ),
                        ...states.map(
                          (addr) =>
                              DropdownMenuItem(value: addr, child: Text(addr)),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _filterText = val ?? ''),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Combined scroll area for table + chart
            filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No parties found',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : Expanded(
                    child: Column(
                      children: [
                        // Table
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                headingRowHeight: 50,
                                dataRowHeight: 50,
                                headingRowColor:
                                    MaterialStateProperty.resolveWith(
                                  (_) => Colors.blue.shade50,
                                ),
                                dataRowColor:
                                    MaterialStateProperty.resolveWith((states) {
                                  return states.contains(MaterialState.selected)
                                      ? Colors.blue.shade100
                                      : Colors.white;
                                }),
                                dividerThickness: 1,
                                horizontalMargin: 16,
                                columnSpacing: 32,
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Party',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Contact',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'GSTIN',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Address',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: filtered.map((p) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          p['name']!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(p['contact']!)),
                                      DataCell(
                                        Text(
                                          p['gstin']!,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(p['address']!)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Chart with fixed height
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: BarChart(
                              BarChartData(
                                barGroups: _chartData,
                                alignment: BarChartAlignment.spaceAround,
                                groupsSpace: 20,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey.shade200,
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final idx = value.toInt();
                                        if (idx < 0 || idx >= filtered.length) {
                                          return const SizedBox();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            filtered[idx]['name']!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      },
                                      reservedSize: 40,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return Text(value.toInt().toString());
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}