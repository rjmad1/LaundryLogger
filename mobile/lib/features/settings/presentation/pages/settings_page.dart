import 'package:flutter/material.dart';

/// Settings page.
class SettingsPage extends StatelessWidget {
  /// Creates the settings page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Household Members'),
            subtitle: const Text('Manage family members'),
            onTap: () {
              // TODO: Navigate to household members
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('PIN Protection'),
            subtitle: const Text('Secure your data'),
            onTap: () {
              // TODO: Navigate to PIN settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Export or import data'),
            onTap: () {
              // TODO: Navigate to backup settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Data'),
            subtitle: const Text('CSV or PDF export'),
            onTap: () {
              // TODO: Show export options
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Version 0.1.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Laundry Logger',
                applicationVersion: '0.1.0',
                applicationLegalese: '© 2025 Laundry Logger',
              );
            },
          ),
        ],
      ),
    );
  }
}
