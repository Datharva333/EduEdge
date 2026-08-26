import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../services/mock_service.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  bool _offline = false;
  String _selectedSubject = 'All';

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    final online = await ApiService.isBackendUp();
    setState(() {
      _offline = !online;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredLessons {
    if (_selectedSubject == 'All') return MockService.lessons;
    return MockService.getLessonsBySubject(_selectedSubject);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userName;
    final scheme = Theme.of(context).colorScheme;

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_offline)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.offline_bolt,
                          color: Colors.orange,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Offline mode - showing cached lessons',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
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
                        icon: Icons.offline_bolt,
                        label: _offline ? 'Offline' : 'Online',
                        color: _offline ? Colors.orange : Colors.teal,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _offline
                                    ? 'Offline mode - showing cached lessons'
                                    : 'You are online',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Subjects',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                      ...MockService.subjects.map(
                        (s) => _SubjectChip(
                          label: '${s['icon']} ${s['name']}',
                          selected: _selectedSubject == s['name'],
                          onTap: () =>
                              setState(() => _selectedSubject = s['name']),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_filteredLessons.length} Lessons',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ..._filteredLessons.map((l) => _LessonCard(lesson: l)),
              ],
            ),
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
        leading: CircleAvatar(
          child: Text(lesson['icon'], style: const TextStyle(fontSize: 18)),
        ),
        title: Text(
          lesson['title'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${lesson['subject']} • Class ${lesson['class']}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => context.push('/lesson/${lesson['id']}'),
      ),
    );
  }
}
