import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../services/mock_service.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userName;
    final lessons = MockService.lessons;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, $user 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => context.push('/progress'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.auto_awesome,
                  label: 'AI Tools',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => context.push('/ai'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  icon: Icons.offline_bolt,
                  label: 'Offline',
                  color: Colors.teal,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Your Lessons',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...lessons.map((l) => _LessonCard(lesson: l)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Map<String, dynamic> lesson;
  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(child: Text(lesson['icon'])),
        title: Text(
          lesson['title'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(lesson['subject']),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => context.push('/lesson/${lesson['id']}'),
      ),
    );
  }
}
