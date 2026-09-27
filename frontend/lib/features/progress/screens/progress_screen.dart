import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../lesson/providers/lesson_provider.dart';
import '../../../services/local_storage_service.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userName;
    final lessonProvider = context.watch<LessonProvider>();
    final lessons = lessonProvider.lessons;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: FutureBuilder<Map<String, Map<String, dynamic>>>(
        // Reads real quiz completion/scores from disk for every lesson
        // currently loaded. Re-runs on every rebuild (e.g. navigating
        // back to this tab), which is what makes the score screen ->
        // progress screen loop actually show up-to-date data.
        future: LocalStorageService.getAllProgress(
          lessons.map((l) => l.id).toList(),
        ),
        builder: (context, snapshot) {
          final progress = snapshot.data ?? {};
          final quizzesCompleted = progress.values
              .where((p) => p['completed'] == true)
              .length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $user!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep learning every day',
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Stats',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Lessons',
                      value: '${lessons.length}',
                      icon: Icons.book_rounded,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Quizzes',
                      value: '$quizzesCompleted',
                      icon: Icons.quiz_rounded,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _StatCard(
                      label: 'Streak',
                      value: '1',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Available Lessons',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (lessons.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    lessonProvider.loading
                        ? 'Loading lessons...'
                        : 'No lessons are currently loaded.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...lessons.map((lesson) {
                  final lessonProgress = progress[lesson.id];
                  final completed = lessonProgress?['completed'] == true;
                  final bestScore = lessonProgress?['bestScore'];
                  final total = lessonProgress?['total'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Text(
                          lesson.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                bestScore != null && total != null
                                    ? '${lesson.subject} · Best: $bestScore/$total'
                                    : lesson.subject,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          completed
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: completed
                              ? Colors.green
                              : Colors.grey.shade400,
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}