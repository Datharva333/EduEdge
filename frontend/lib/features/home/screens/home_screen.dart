import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../lesson/models/lesson.dart';
import '../../lesson/providers/lesson_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSubject = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadLessons();
    });
  }

  List<Lesson> _filteredLessons(LessonProvider provider) {
    if (_selectedSubject == 'All') return provider.lessons;
    return provider.lessons
        .where((lesson) => lesson.subject == _selectedSubject)
        .toList(growable: false);
  }

  Future<void> _refresh() async {
    await context.read<LessonProvider>().loadLessons(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userName;
    final lessons = context.watch<LessonProvider>();
    final scheme = Theme.of(context).colorScheme;

    if (_selectedSubject != 'All' &&
        !lessons.subjects.contains(_selectedSubject)) {
      _selectedSubject = 'All';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, $user 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => context.push('/progress'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(context, lessons, scheme),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LessonProvider provider,
    ColorScheme scheme,
  ) {
    if (provider.loading && !provider.hasLoaded) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (provider.errorMessage != null && provider.lessons.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 16),
          Text(
            'Could not load lessons',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            provider.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    final filteredLessons = _filteredLessons(provider);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.auto_awesome,
                label: 'AI Hub',
                color: scheme.primary,
                onTap: () => context.push('/aihub'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: provider.backendOnline
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                label: provider.backendOnline ? 'Connected' : 'Offline',
                color: provider.backendOnline ? Colors.teal : Colors.orange,
                onTap: _refresh,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Subjects',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _SubjectChip(
                label: 'All',
                selected: _selectedSubject == 'All',
                onTap: () => setState(() => _selectedSubject = 'All'),
              ),
              ...provider.subjects.map(
                (subject) => _SubjectChip(
                  label: subject,
                  selected: _selectedSubject == subject,
                  onTap: () => setState(() => _selectedSubject = subject),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${filteredLessons.length} Lessons',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        if (filteredLessons.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'No lessons available for this subject.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          ...filteredLessons.map((lesson) => _LessonCard(lesson: lesson)),
      ],
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SubjectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
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
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;

  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          child: Text(lesson.icon, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(lesson.subject),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => context.push('/lesson/${lesson.id}'),
      ),
    );
  }
}
