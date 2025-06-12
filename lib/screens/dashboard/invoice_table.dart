// lib/screens/dashboard/invoice_table.dart
import 'package:flutter/material.dart';

class InvoiceTable extends StatelessWidget {
  final List<Map<String, String>> rows = [
    {'date': '10/06/2025', 'type': 'Invoice', 'description': 'Sharma Traders', 'amount': '₹885'},
    {'date': '09/06/2025', 'type': 'Stock Alert', 'description': 'USB Cable low stock', 'amount': '—'},
    {'date': '06/06/2025', 'type': 'Expense', 'description': 'Electricity Bill', 'amount': '₹1500'},
  ];

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Amount')),
      ],
      rows: rows
          .map(
            (row) => DataRow(
              cells: [
                DataCell(Text(row['date']!)),
                DataCell(Text(row['type']!)),
                DataCell(Text(row['description']!)),
                DataCell(Text(row['amount']!)),
              ],
            ),
          )
          .toList(),
    );
  }
}
