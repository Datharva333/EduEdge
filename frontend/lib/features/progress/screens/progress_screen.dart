import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: const Center(
        child: Text(
          'Progress tracking coming Week 3 📊',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
