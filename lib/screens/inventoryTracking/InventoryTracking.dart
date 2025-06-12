import 'package:flutter/material.dart';

class InventoryItem {
  String name;
  String category;
  int stock;
  int price;

  InventoryItem({
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
  });
}

class InventoryTrackingScreen extends StatefulWidget {
  const InventoryTrackingScreen({super.key});

  @override
  State<InventoryTrackingScreen> createState() =>
      _InventoryTrackingScreenState();
}

class _InventoryTrackingScreenState extends State<InventoryTrackingScreen> {
  final List<InventoryItem> _items = [
    InventoryItem(
      name: 'Mobile Cover',
      category: 'Accessories',
      stock: 5,
      price: 150,
    ),
    InventoryItem(
      name: 'USB Cable',
      category: 'Electronics',
      stock: 15,
      price: 100,
    ),
    InventoryItem(
      name: 'Laptop Bag',
      category: 'Accessories',
      stock: 25,
      price: 120,
    ),
    InventoryItem(
      name: 'Smart Phone',
      category: 'Electronics',
      stock: 30,
      price: 12000,
    ),
  ];

  String _search = '';
  String _sortOption = '';

  InventoryItem? _editingItem;
  int? _editingIndex;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();

  void _openItemDialog({InventoryItem? item, int? index}) {
    _editingItem = item;
    _editingIndex = index;
    _nameController.text = item?.name ?? '';
    _categoryController.text = item?.category ?? '';
    _stockController.text = item?.stock.toString() ?? '';
    _priceController.text = item?.price.toString() ?? '';

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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
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
            onPressed: _saveItem,
            child: Text(item == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _saveItem() {
    if (_formKey.currentState?.validate() ?? false) {
      final item = InventoryItem(
        name: _nameController.text,
        category: _categoryController.text,
        stock: int.parse(_stockController.text),
        price: int.parse(_priceController.text),
      );

      setState(() {
        if (_editingItem != null && _editingIndex != null) {
          _items[_editingIndex!] = item;
        } else {
          _items.add(item);
        }
      });

      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  List<InventoryItem> _filteredItems() {
    List<InventoryItem> filtered = _items
        .where(
          (item) => item.name.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList();

    switch (_sortOption) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'stock':
        filtered.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case 'price':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
    }
    return filtered;
  }

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
            Align(
              alignment: Alignment.centerLeft,
              child: DropdownButton<String>(
                value: _sortOption.isEmpty ? null : _sortOption,
                hint: const Text("Sort By"),
                onChanged: (value) => setState(() => _sortOption = value ?? ''),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Product Name')),
                  DropdownMenuItem(value: 'stock', child: Text('Stock')),
                  DropdownMenuItem(value: 'price', child: Text('Price')),
                ],
              ),
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
                          subtitle: Text('${item.category} • ₹${item.price}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _stockBadge(item.stock),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _openItemDialog(item: item, index: i),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteItem(i),
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
