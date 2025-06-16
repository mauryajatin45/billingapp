import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InventoryItem {
  String id;
  String name;
  String category;
  int currentStock;
  int price;
  int gstRate;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.price,
    required this.gstRate,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['_id'],
    name: json['name'],
    category: json['category'],
    currentStock: json['currentStock'],
    price: json['price'],
    gstRate: json['GSTRate'],
  );

  Map<String, dynamic> toJson(String userId) => {
    'userId': userId,
    'name': name,
    'category': category,
    'currentStock': currentStock,
    'price': price,
    'GSTRate': gstRate,
  };
}

class InventoryTrackingScreen extends StatefulWidget {
  const InventoryTrackingScreen({super.key});

  @override
  State<InventoryTrackingScreen> createState() =>
      _InventoryTrackingScreenState();
}

class _InventoryTrackingScreenState extends State<InventoryTrackingScreen> {
  final String apiUrl = 'http://10.0.2.2:3000/api/inventory/products';
  List<InventoryItem> _items = [];
  String _search = '';
  String _sortOption = '';
  String _selectedCategory = 'All';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();
  final _gstRateController = TextEditingController();

  InventoryItem? _editingItem;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchItems() async {
  try {
    final res = await http.get(
      Uri.parse(apiUrl),
      headers: await _getHeaders(),
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List<dynamic> data = decoded['data']; // ✅ Correct field from response
      if (data == null) {
        print("Fetch error: data is null");
        return;
      }

      setState(() {
        _items = data.map((e) => InventoryItem.fromJson(e)).toList();
      });
    } else {
      print("Error loading items: ${res.body}");
    }
  } catch (e) {
    print('Fetch error: $e');
  }
}


  Future<void> _addItem() async {
    if (_formKey.currentState?.validate() != true) return;

    final userId = await _getUserId();
    final token = await _getToken();
    if (userId == null || token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }

    final newItem = {
      'userId': userId,
      'name': _nameController.text,
      'category': _categoryController.text,
      'price': int.parse(_priceController.text),
      'GSTRate': int.parse(_gstRateController.text),
      'currentStock': int.parse(_stockController.text),
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: await _getHeaders(),
        body: jsonEncode(newItem),
      );

      if (response.statusCode == 201) {
        Navigator.of(context, rootNavigator: true).pop();
        await _fetchItems();
      } else {
        print('Error adding item: ${response.body}');
      }
    } catch (e) {
      print('Add error: $e');
    }
  }

  Future<void> _updateItem(InventoryItem item) async {
    if (!_formKey.currentState!.validate()) return;

    final userId = await _getUserId();
    if (userId == null) return;

    final updatedItem = InventoryItem(
      id: item.id,
      name: _nameController.text,
      category: _categoryController.text,
      currentStock: int.parse(_stockController.text),
      price: int.parse(_priceController.text),
      gstRate: int.parse(_gstRateController.text),
    );

    try {
      final res = await http.put(
        Uri.parse('$apiUrl/${item.id}'),
        headers: await _getHeaders(),
        body: jsonEncode(updatedItem.toJson(userId)),
      );
      if (res.statusCode == 200) {
        Navigator.of(context, rootNavigator: true).pop();
        await _fetchItems();
      } else {
        print('Error updating item: ${res.body}');
      }
    } catch (e) {
      print('Update error: $e');
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$apiUrl/$id'),
        headers: await _getHeaders(),
      );
      if (res.statusCode == 200) {
        await _fetchItems();
      } else {
        print('Delete error: ${res.body}');
      }
    } catch (e) {
      print('Delete exception: $e');
    }
  }

  void _openItemDialog({InventoryItem? item}) {
    _editingItem = item;
    _nameController.text = item?.name ?? '';
    _categoryController.text = item?.category ?? '';
    _stockController.text = item?.currentStock.toString() ?? '';
    _priceController.text = item?.price.toString() ?? '';
    _gstRateController.text = item?.gstRate.toString() ?? '18';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Add Item' : 'Edit Item'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_nameController, 'Product Name'),
                _buildTextField(_categoryController, 'Category'),
                _buildTextField(_stockController, 'Stock', isNumber: true),
                _buildTextField(_priceController, 'Price', isNumber: true),
                _buildTextField(
                  _gstRateController,
                  'GST Rate (0-28)',
                  isNumber: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: item == null ? _addItem : () => _updateItem(item),
            child: Text(item == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

  List<InventoryItem> _filteredItems() {
    var filtered = _items
        .where(
          (i) =>
              i.name.toLowerCase().contains(_search.toLowerCase()) &&
              (_selectedCategory == 'All' || i.category == _selectedCategory),
        )
        .toList();

    switch (_sortOption) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'stock':
        filtered.sort((a, b) => a.currentStock.compareTo(b.currentStock));
        break;
      case 'price':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
    }
    return filtered;
  }

  List<String> get _allCategories => [
    'All',
    ..._items.map((e) => e.category).toSet(),
  ];

  Widget _stockBadge(int stock) {
    if (stock <= 10) {
      return Chip(
        label: Text('$stock - Low'),
        backgroundColor: Colors.red.shade200,
      );
    } else if (stock <= 20) {
      return Chip(
        label: Text('$stock - Medium'),
        backgroundColor: Colors.orange.shade200,
      );
    } else {
      return Chip(
        label: Text('$stock - High'),
        backgroundColor: Colors.green.shade200,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems();
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Tracking')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openItemDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search products...',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                DropdownButton<String>(
                  value: _sortOption.isEmpty ? null : _sortOption,
                  hint: const Text("Sort By"),
                  onChanged: (value) =>
                      setState(() => _sortOption = value ?? ''),
                  items: const [
                    DropdownMenuItem(
                      value: 'name',
                      child: Text('Product Name'),
                    ),
                    DropdownMenuItem(value: 'stock', child: Text('Stock')),
                    DropdownMenuItem(value: 'price', child: Text('Price')),
                  ],
                ),
                const SizedBox(width: 20),
                DropdownButton<String>(
                  value: _selectedCategory,
                  onChanged: (val) =>
                      setState(() => _selectedCategory = val ?? 'All'),
                  items: _allCategories
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No items found.'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.category} • ₹${item.price} • GST: ${item.gstRate}%',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _stockBadge(item.currentStock),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _openItemDialog(item: item),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteItem(item.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
