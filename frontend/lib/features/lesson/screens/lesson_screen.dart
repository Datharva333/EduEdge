import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/mock_service.dart';
import '../../../services/api_service.dart';

class LessonScreen extends StatelessWidget {
  final String lessonId;
  const LessonScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final lesson = MockService.lessons.firstWhere(
      (l) => l['id'] == lessonId,
      orElse: () => MockService.lessons.first,
    );
    return Scaffold(
      appBar: AppBar(title: Text(lesson['subject'])),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            lesson['title'],
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            lesson['content'],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Summarize with AI'),
            onPressed: () => context.push('/ai/${lesson['id']}'),
          ),
        ],
      ),
    );
  }
}
