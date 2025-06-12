import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class GstInvoice extends StatefulWidget {
  @override
  _GstInvoiceState createState() => _GstInvoiceState();
}

class _GstInvoiceState extends State<GstInvoice> {
  bool showModal = false;

  Map<String, dynamic> invoiceData = {
    'name': 'John Smith',
    'address': '123 Elm St, Springfield',
    'email': 'john.smith@email.com',
    'invoiceNo': 'INV-001',
    'date': '2024-04-24',
    'description': 'Product A',
    'qty': 1,
    'rate': 1000,
  };

  // Controllers for form fields
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController emailController;
  late TextEditingController invoiceNoController;
  late TextEditingController dateController;
  late TextEditingController descriptionController;
  late TextEditingController qtyController;
  late TextEditingController rateController;

  @override
  void initState() {
    super.initState();
    _resetFormControllers();
  }

  void _resetFormControllers() {
    nameController = TextEditingController(text: invoiceData['name']);
    addressController = TextEditingController(text: invoiceData['address']);
    emailController = TextEditingController(text: invoiceData['email']);
    invoiceNoController = TextEditingController(text: invoiceData['invoiceNo']);
    dateController = TextEditingController(text: invoiceData['date']);
    descriptionController = TextEditingController(text: invoiceData['description']);
    qtyController = TextEditingController(text: invoiceData['qty'].toString());
    rateController = TextEditingController(text: invoiceData['rate'].toString());
  }

  void _openModal() {
    _resetFormControllers();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('New Invoice'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Name', nameController),
              _buildTextField('Address', addressController),
              _buildTextField('Email', emailController, keyboardType: TextInputType.emailAddress),
              _buildTextField('Invoice Number', invoiceNoController),
              _buildTextField('Date (YYYY-MM-DD)', dateController),
              _buildTextField('Description', descriptionController),
              _buildTextField('Quantity', qtyController, keyboardType: TextInputType.number),
              _buildTextField('Rate (₹)', rateController, keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Close')),
          ElevatedButton(onPressed: _saveForm, child: Text('Save')),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

void _saveForm() {
  setState(() {
    invoiceData = {
      'name': nameController.text,
      'address': addressController.text,
      'email': emailController.text,
      'invoiceNo': invoiceNoController.text,
      'date': dateController.text,
      'description': descriptionController.text,
      'qty': int.tryParse(qtyController.text) ?? 1,
      'rate': double.tryParse(rateController.text) ?? 0,
    };
  });

  // Safely close dialog or pop screen
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop(); // Or use rootNavigator if inside dialog
  } else {
    // If nothing to pop, redirect
    context.go('/'); // or some safe fallback
  }
}


  double get total => (invoiceData['qty'] * invoiceData['rate']).toDouble();
  double get cgst => total * 0.09;
  double get sgst => total * 0.09;
  double get grandTotal => total + cgst + sgst;

  void _downloadPDF() {
    // Flutter does not have direct html2canvas + jsPDF equivalent.
    // You can use packages like 'pdf' and 'printing' to generate PDFs.
    // Here we just show a snackbar as a placeholder.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download PDF functionality to be implemented')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GST Billing & Invoicing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _openModal,
              child: Text('+ New Invoice'),
            ),
            SizedBox(height: 16),
            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Billed To:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(invoiceData['name']),
                        Text(invoiceData['address']),
                        Text(invoiceData['email']),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invoice Number:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(invoiceData['invoiceNo']),
                        SizedBox(height: 8),
                        Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(invoiceData['date']),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            DataTable(
              columns: [
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Rate')),
                DataColumn(label: Text('Amount')),
              ],
              rows: [
                DataRow(cells: [
                  DataCell(Text(invoiceData['description'])),
                  DataCell(Text(invoiceData['qty'].toString())),
                  DataCell(Text('₹${invoiceData['rate'].toStringAsFixed(2)}')),
                  DataCell(Text('₹${total.toStringAsFixed(2)}')),
                ]),
              ],
            ),
            Spacer(),
            Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total: ₹${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('CGST @9%: ₹${cgst.toStringAsFixed(2)}'),
                  Text('SGST @9%: ₹${sgst.toStringAsFixed(2)}'),
                  SizedBox(height: 8),
                  Text('Grand Total: ₹${grandTotal.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _downloadPDF,
              icon: Icon(Icons.download),
              label: Text('Download'),
            ),
          ],
        ),
      ),
    );
  }
}
