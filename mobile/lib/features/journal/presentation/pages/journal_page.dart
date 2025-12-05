import 'package:flutter/material.dart';

/// Laundry journal page.
class JournalPage extends StatelessWidget {
  /// Creates the journal page.
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laundry Journal'),
      ),
      body: const Center(
        child: Text('Journal Page - Coming Soon'),
      ),
    );
  }
}
