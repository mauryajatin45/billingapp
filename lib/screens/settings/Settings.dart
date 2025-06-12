import 'package:flutter/material.dart';

void main() => runApp(const SettingsApp());

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Settings',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const SettingsPage(),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  String _selectedSection = 'user';
  bool _editMode = false;
  bool _showDeleteModal = false;

  Map<String, Map<String, String>> _formData = {
    'user': {'name': 'John Doe', 'email': 'john@example.com'},
    'preferences': {'language': 'English', 'timeZone': 'IST'},
    'billing': {'plan': 'Premium', 'nextBilling': 'July 1, 2025'},
    'notifications': {'emailAlerts': 'Enabled', 'smsNotifications': 'Disabled'},
    'security': {'passwordLastChanged': '60 days ago', 'twoFA': 'Enabled'},
    'integrations': {'googleDrive': 'Connected', 'slack': 'Not Connected'},
    'appearance': {'theme': 'Light', 'fontSize': 'Medium'},
    'account': {'status': 'Active'},
  };

  final Map<String, String> _sectionTitles = {
    'user': 'User Settings',
    'preferences': 'Preferences',
    'billing': 'Billing',
    'notifications': 'Notifications',
    'security': 'Security',
    'integrations': 'Integrations',
    'appearance': 'Appearance',
    'account': 'Account Management',
  };

  void _handleInputChange(String section, String field, String value) {
    setState(() {
      _formData[section]?[field] = value;
    });
  }

  void _handleSave() {
    setState(() => _editMode = false);
    // Save to backend here
  }

  void _handleDelete() {
    setState(() => _showDeleteModal = false);
    // Handle account deletion here
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action is irreversible.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _handleDelete();
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _formData.keys.map((section) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                section == 'user'
                    ? 'Profile'
                    : section[0].toUpperCase() + section.substring(1),
              ),
              selected: _selectedSection == section,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedSection = section;
                    _editMode = false;
                  });
                }
              },
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: _selectedSection == section
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (!_editMode)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => setState(() => _editMode = true),
            ),
        ],
      ),
    );
  }

  Widget _buildEditMode(String section) {
    final sectionData = _formData[section]!;
    final title = _sectionTitles[section]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _editMode = false),
                      child: const Text('CANCEL'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _handleSave,
                      child: const Text('SAVE'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sectionData.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key.split(RegExp(r'(?=[A-Z])')).join(' '),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: entry.value,
                      onChanged: (value) =>
                          _handleInputChange(section, entry.key, value),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent(String section) {
    final sectionData = _formData[section]!;
    final title = _sectionTitles[section]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(title),
            ...sectionData.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        entry.key.split(RegExp(r'(?=[A-Z])')).join(' ') + ':',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color?.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (section == 'account')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed:
                      _showDeleteConfirmationDialog, // Calling the function directly on press
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete Account'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSection() {
    if (_editMode) {
      return _buildEditMode(_selectedSection);
    }
    return _buildSectionContent(_selectedSection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSectionButtons(),
            const SizedBox(height: 16),
            Expanded(child: ListView(children: [_buildCurrentSection()])),
          ],
        ),
      ),
    );
  }
}
