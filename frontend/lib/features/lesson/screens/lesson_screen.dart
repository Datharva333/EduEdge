import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../models/lesson.dart';
import '../providers/lesson_provider.dart';

class LessonScreen extends StatefulWidget {
  final String lessonId;

  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  Lesson? _lesson;
  bool _loading = true;
  String? _errorMessage;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    final provider = context.read<LessonProvider>();
    final cached = provider.findById(widget.lessonId);

    if (cached != null) {
      setState(() {
        _lesson = cached;
        _loading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final lesson = await provider.loadLesson(widget.lessonId);
      if (!mounted) return;
      setState(() {
        _lesson = lesson;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_lesson?.subject ?? 'Lesson')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _LessonError(message: _errorMessage!, onRetry: _loadLesson)
              : _buildLesson(context, scheme, _lesson!),
    );
  }

  Widget _buildLesson(
    BuildContext context,
    ColorScheme scheme,
    Lesson lesson,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          lesson.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              lesson.subject,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          lesson.content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
        ),
        const SizedBox(height: 32),
        Text(
          'AI Tools',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
              onTap: () => context.push('/aihub/${lesson.id}'),
            ),
            _ToolCard(
              icon: Icons.chat,
              label: 'Ask AI',
              color: Colors.deepPurple,
              onTap: () => context.push('/chat/${lesson.id}'),
            ),
            _ToolCard(
              icon: Icons.quiz,
              label: 'Quiz',
              color: Colors.teal,
              onTap: () => context.push('/quiz/${lesson.id}'),
            ),
            _ToolCard(
              icon: Icons.account_tree,
              label: 'Mind Map',
              color: Colors.purple,
              onTap: () => context.push('/mindmap/${lesson.id}'),
            ),
            _ToolCard(
              icon: Icons.style,
              label: 'Flashcards',
              color: Colors.orange,
              onTap: () => context.push('/flashcards/${lesson.id}'),
            ),
          ],
        ),
      ],
    );
  }
}

class _LessonError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LessonError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 12),
            const Text(
              'Could not load lesson',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
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
