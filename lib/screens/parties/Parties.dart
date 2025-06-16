import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterText = '';
  List<Map<String, dynamic>> _parties = [];
  bool _isLoading = false;

  final String apiUrl = 'http://10.0.2.2:3000/api/parties';

  String? _currentUserId;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) => fetchParties());
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');
    _authToken = prefs.getString('authToken');
  }

  Future<void> fetchParties() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          setState(
            () => _parties = List<Map<String, dynamic>>.from(decoded['data']),
          );
        } else {
          print('Unexpected response format: $decoded');
        }
      } else {
        print('Failed to load parties: ${res.body}');
      }
    } catch (e) {
      print('Error fetching parties: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> addParty(Map<String, dynamic> party) async {
    // Ensure userId and token are loaded
    if (_currentUserId == null || _authToken == null) {
      await _loadUserData(); // Try to load again
    }

    // If still missing, show error and exit
    if (_currentUserId == null || _authToken == null) {
      print('User ID or token still missing after reload');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: You are not logged in. Please login again.'),
        ),
      );
      return;
    }

    // Construct the new party object
    final newParty = {...party, 'userId': _currentUserId};

    try {
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(newParty),
      );

      if (res.statusCode == 201) {
        print("✅ Party added successfully");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Party added successfully')),
        );
        fetchParties(); // Refresh party list
      } else {
        print('❌ Failed to add party: ${res.statusCode} ${res.body}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
      }
    } catch (e) {
      print('❌ Error adding party: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  List<Map<String, dynamic>> get _filteredParties {
    final query = _searchController.text.toLowerCase();
    return _parties.where((p) {
      final matchesName = p['name'].toString().toLowerCase().contains(query);
      final matchesFilter =
          _filterText.isEmpty || p['billingAddress']['state'] == _filterText;
      return matchesName && matchesFilter;
    }).toList();
  }

  List<BarChartGroupData> get _chartData {
    return _filteredParties.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;
      final value =
          double.tryParse(p['contact']?['mobile']?.length.toString() ?? '0') ??
          0;

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

  void _showAddPartyDialog() {
    final _nameController = TextEditingController();
    final _mobileController = TextEditingController();
    final _emailController = TextEditingController();
    final _stateController = TextEditingController();
    final _gstinController = TextEditingController();
    final _typeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Party'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Mobile'),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _gstinController,
                decoration: const InputDecoration(labelText: 'GSTIN'),
              ),
              TextField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'State'),
              ),
              TextField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Type (customer/supplier/both)',
                ),
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
              final newParty = {
                'name': _nameController.text,
                'type': _typeController.text,
                'contact': {
                  'mobile': _mobileController.text,
                  'email': _emailController.text,
                },
                'billingAddress': {'state': _stateController.text},
                'GSTIN': _gstinController.text,
              };
              addParty(newParty);
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredParties;
    final states = _parties
        .map((p) => p['billingAddress']?['state'] ?? '')
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Parties'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
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
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
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
                              Expanded(
                                flex: 2,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(
                                          label: Text(
                                            'Party',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        DataColumn(label: Text('Mobile')),
                                        DataColumn(label: Text('Email')),
                                        DataColumn(label: Text('GSTIN')),
                                        DataColumn(label: Text('State')),
                                      ],
                                      rows: filtered.map((p) {
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(p['name'] ?? '')),
                                            DataCell(
                                              Text(
                                                p['contact']?['mobile'] ?? '',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                p['contact']?['email'] ?? '',
                                              ),
                                            ),
                                            DataCell(Text(p['GSTIN'] ?? '')),
                                            DataCell(
                                              Text(
                                                p['billingAddress']?['state'] ??
                                                    '',
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                flex: 3,
                                child: BarChart(
                                  BarChartData(
                                    barGroups: _chartData,
                                    alignment: BarChartAlignment.spaceAround,
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final idx = value.toInt();
                                            if (idx < 0 ||
                                                idx >= filtered.length)
                                              return const SizedBox();
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Text(
                                                filtered[idx]['name'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
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
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPartyDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Party'),
      ),
    );
  }
}
