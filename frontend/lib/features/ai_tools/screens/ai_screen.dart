import 'package:flutter/material.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Tools')),
      body: const Center(
        child: Text(
          'AI features coming Week 2 🚀',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
