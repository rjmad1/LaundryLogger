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
              // Navigate to household members screen
              Navigator.of(context).pushNamed('/household');
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('PIN Protection'),
            subtitle: const Text('Secure your data'),
            onTap: () {
              // Navigate to PIN/security settings
              Navigator.of(context).pushNamed('/settings/pin');
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Export or import data'),
            onTap: () {
              // Navigate to Backup & Restore settings
              Navigator.of(context).pushNamed('/settings/backup');
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Data'),
            subtitle: const Text('CSV or PDF export'),
            onTap: () {
              // Show export options (CSV / Backup)
              showModalBottomSheet<void>(
                context: context,
                builder: (_) {
                  return SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.file_upload),
                          title: const Text('Export CSV'),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushNamed('/settings/export_csv');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.backup),
                          title: const Text('Create Local Backup'),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushNamed('/settings/backup');
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
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
