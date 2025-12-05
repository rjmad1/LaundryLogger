import 'package:flutter/material.dart';

/// Items management page.
class ItemsPage extends StatelessWidget {
  /// Creates the items page.
  const ItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laundry Items'),
      ),
      body: const Center(
        child: Text('Items Page - Coming Soon'),
      ),
    );
  }
}
