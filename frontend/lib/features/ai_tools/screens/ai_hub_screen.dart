import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../services/mock_service.dart';

class AiHubScreen extends StatefulWidget {
  final String? lessonId;
  const AiHubScreen({super.key, this.lessonId});

  @override
  State<AiHubScreen> createState() => _AiHubScreenState();
}

class _AiHubScreenState extends State<AiHubScreen> {
  String? _summary;
  bool _loadingSummary = false;
  bool _backendOnline = false;
  bool _checkingStatus = true;
  late String _selectedLessonId;
  double? _responseTime;

  @override
  void initState() {
    super.initState();
    _selectedLessonId = widget.lessonId ?? '1';
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    setState(() => _checkingStatus = true);
    final online = await ApiService.isBackendUp();
    if (mounted) {
      setState(() {
        _backendOnline = online;
        _checkingStatus = false;
      });
    }
  }

  Future<void> _summarize() async {
    setState(() {
      _loadingSummary = true;
      _summary = null;
      _responseTime = null;
    });
    final stopwatch = Stopwatch()..start();
    final result = await ApiService.summarize(_selectedLessonId);
    stopwatch.stop();
    if (mounted) {
      setState(() {
        _summary = result ?? 'Could not get summary. Is the backend running?';
        _loadingSummary = false;
        _responseTime = stopwatch.elapsedMilliseconds / 1000;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lessons = MockService.lessons;
    final selectedLesson = lessons.firstWhere(
      (l) => l['id'] == _selectedLessonId,
      orElse: () => lessons.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkBackend,
            tooltip: 'Refresh status',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _checkingStatus
                    ? Colors.grey.shade50
                    : _backendOnline
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _checkingStatus
                      ? Colors.grey.shade200
                      : _backendOnline
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  _checkingStatus
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _backendOnline
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: _backendOnline ? Colors.green : Colors.red,
                          size: 18,
                        ),
                  const SizedBox(width: 10),
                  Text(
                    _checkingStatus
                        ? 'Checking backend...'
                        : _backendOnline
                        ? 'Backend connected'
                        : 'Backend offline',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _checkingStatus
                          ? Colors.grey
                          : _backendOnline
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'AI Engine',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lesson selector
            Text(
              'Select Lesson',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLessonId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: lessons
                  .map(
                    (l) => DropdownMenuItem(
                      value: l['id'] as String,
                      child: Row(
                        children: [
                          Text(l['icon'], style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${l['title']} (Class ${l['class']})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedLessonId = val;
                    _summary = null;
                    _responseTime = null;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // AI tools grid
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
              childAspectRatio: 2.0,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _HubButton(
                  icon: Icons.auto_awesome,
                  label: 'Summarize',
                  color: scheme.primary,
                  loading: _loadingSummary,
                  onTap: _summarize,
                ),
                _HubButton(
                  icon: Icons.quiz,
                  label: 'Quiz',
                  color: Colors.teal,
                  onTap: () => context.push('/quiz/$_selectedLessonId'),
                ),
                _HubButton(
                  icon: Icons.account_tree,
                  label: 'Mind Map',
                  color: Colors.purple,
                  onTap: () => context.push('/mindmap/$_selectedLessonId'),
                ),
                _HubButton(
                  icon: Icons.style,
                  label: 'Flashcards',
                  color: Colors.orange,
                  onTap: () => context.push('/flashcards/$_selectedLessonId'),
                ),
                _HubButton(
                  icon: Icons.chat,
                  label: 'Ask AI',
                  color: Colors.deepPurple,
                  onTap: () => context.push('/chat/$_selectedLessonId'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary output
            if (_loadingSummary)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Generating summary...',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            if (_summary != null && !_loadingSummary) ...[
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'AI Summary',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_responseTime != null)
                    Text(
                      '${_responseTime!.toStringAsFixed(1)}s',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _summary!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Summary copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.copy,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _summary!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 16),
              // Quick actions after summary
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.quiz, size: 16),
                      label: const Text('Test yourself'),
                      onPressed: () => context.push('/quiz/$_selectedLessonId'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.style, size: 16),
                      label: const Text('Flashcards'),
                      onPressed: () =>
                          context.push('/flashcards/$_selectedLessonId'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HubButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  const _HubButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              loading && label == 'Summarize'
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
