import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/mock_service.dart';

class LessonScreen extends StatelessWidget {
  final String lessonId;
  const LessonScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final lesson = MockService.lessons.firstWhere(
      (l) => l['id'] == lessonId,
      orElse: () => MockService.lessons.first,
    );
    final scheme = Theme.of(context).colorScheme;

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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Class ${lesson['class']} • ${lesson['subject']}',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            lesson['content'],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 32),
          Text(
            'AI Tools',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            childAspectRatio: 1.6,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ToolCard(
                icon: Icons.auto_awesome,
                label: 'AI Hub',
                color: scheme.primary,
                onTap: () => context.push('/aihub/${lesson['id']}'),
              ),
              _ToolCard(
                icon: Icons.chat,
                label: 'Ask AI',
                color: Colors.deepPurple,
                onTap: () => context.push('/chat/${lesson['id']}'),
              ),
              _ToolCard(
                icon: Icons.quiz,
                label: 'Quiz',
                color: Colors.teal,
                onTap: () => context.push('/quiz/${lesson['id']}'),
              ),
              _ToolCard(
                icon: Icons.account_tree,
                label: 'Mind Map',
                color: Colors.purple,
                onTap: () => context.push('/mindmap/${lesson['id']}'),
              ),
              _ToolCard(
                icon: Icons.style,
                label: 'Flashcards',
                color: Colors.orange,
                onTap: () => context.push('/flashcards/${lesson['id']}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
