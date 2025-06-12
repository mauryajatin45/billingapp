// reports_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _dateRange = 'Date Range';

  final _items = <_ReportItem>[
    _ReportItem(
      icon: FeatherIcons.barChart2,
      title: 'Sales Report',
      description: 'View sales data by time period.',
      route: '/sales-report',
    ),
    _ReportItem(
      icon: FeatherIcons.archive,
      title: 'Inventory Report',
      description: 'Check current stock levels.',
      route: '/inventory',
    ),
    _ReportItem(
      icon: FeatherIcons.fileText,
      title: 'Tax Summary',
      description: 'Generate tax related details.',
      route: '/tax-summary',
    ),
    _ReportItem(
      icon: FeatherIcons.pieChart,
      title: 'Expense Report',
      description: 'Analyze business expenditures.',
      route: '/expenses',
    ),
  ];

  void _selectDateRange(String value) {
    setState(() {
      _dateRange = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              tooltip: 'Select date range',
              onSelected: _selectDateRange,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
                PopupMenuItem(value: 'Last 30 Days', child: Text('Last 30 Days')),
                PopupMenuItem(value: 'This Year', child: Text('This Year')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    Text(_dateRange, style: const TextStyle(color: Colors.black87)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 2 columns if width >= 600
          final crossAxisCount = constraints.maxWidth >= 600 ? 2 : 1;
          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              itemCount: _items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3 / 2,
              ),
              itemBuilder: (_, idx) {
                final item = _items[idx];
                return InkWell(
                  onTap: () => context.go(item.route),
                  borderRadius: BorderRadius.circular(12),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 36, color: Colors.grey[700]),
                          const SizedBox(height: 12),
                          Text(item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(item.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReportItem {
  final IconData icon;
  final String title;
  final String description;
  final String route;
  const _ReportItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });
}
