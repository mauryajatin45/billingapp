import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GstInvoicePage extends StatefulWidget {
  @override
  State<GstInvoicePage> createState() => _GstInvoicePageState();
}

class _GstInvoicePageState extends State<GstInvoicePage> {
  List<dynamic> products = [];
  List<dynamic> invoices = [];
  List<dynamic> parties = [];
  String? selectedProductId;
  String? selectedPartyId;
  int quantity = 1;
  double discount = 0;
  String? token;
  String? userId;

  final String baseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _loadCredentialsAndFetch();
  }

  Future<void> _loadCredentialsAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('authToken');
    userId = prefs.getString('userId');

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not authenticated')));
      return;
    }

    await fetchProducts();
    await fetchParties();
    await fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/billing/invoices'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() => invoices = data['data']);
      }
    } catch (e) {
      print('Error fetching invoices: $e');
    }
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/inventory/products'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          products = List.from(data['data']).where((p) => p['userId'] == userId).toList();
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> fetchParties() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/parties'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          parties = List.from(data['data']).where((p) => p['userId'] == userId).toList();
        });
      }
    } catch (e) {
      print('Error fetching parties: $e');
    }
  }

  Future<void> createInvoice() async {
    if (selectedProductId == null || selectedPartyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select product and party')));
      return;
    }

    final product = products.firstWhere((p) => p['_id'] == selectedProductId);
    final items = [
      {
        'productId': selectedProductId,
        'quantity': quantity,
        'price': product['price'],
        'discount': discount,
      },
    ];

    final body = jsonEncode({
      'partyId': selectedPartyId,
      'items': items,
      'paymentMethod': 'cash',
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/billing/invoices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        await fetchInvoices();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice created')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${data['error']['message']}')),
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget invoiceCard(invoice) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text('Invoice No: ${invoice['invoiceNumber']}'),
        subtitle: Text('Total: ₹${invoice['grandTotal']}'),
        trailing: IconButton(
          icon: Icon(Icons.picture_as_pdf),
          onPressed: () {
            final pdfUrl = '$baseUrl/api/billing/invoice/${invoice['_id']}/pdf';
            // TODO: open with url_launcher
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GST Invoice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField(
              value: selectedProductId,
              items: products.map((p) => DropdownMenuItem(value: p['_id'], child: Text(p['name']))).toList(),
              onChanged: (val) => setState(() => selectedProductId = val as String),
              hint: Text('Select Product'),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField(
              value: selectedPartyId,
              items: parties.map((p) => DropdownMenuItem(value: p['_id'], child: Text(p['name']))).toList(),
              onChanged: (val) => setState(() => selectedPartyId = val as String),
              hint: Text('Select Party'),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              onChanged: (val) => quantity = int.tryParse(val) ?? 1,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Discount %'),
              keyboardType: TextInputType.number,
              onChanged: (val) => discount = double.tryParse(val) ?? 0,
            ),
            SizedBox(height: 12),
            ElevatedButton(onPressed: createInvoice, child: Text('Create Invoice')),
            Divider(height: 30),
            Text('Invoices:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: invoices.isEmpty
                  ? Center(child: Text('No invoices'))
                  : ListView(children: invoices.map(invoiceCard).toList()),
            ),
          ],
        ),
      ),
    );
  }
}
