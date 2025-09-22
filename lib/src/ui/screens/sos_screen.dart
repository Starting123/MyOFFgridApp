import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SOSScreen extends ConsumerWidget {
  const SOSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement SOS details and emergency features
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Details'),
      ),
      body: const Center(
        child: Text('SOS Screen - Coming Soon'),
      ),
    );
  }
}