import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';

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
  List<Map<String, dynamic>> _lessons = [];
  bool _loadingLessons = true;

  @override
  void initState() {
    super.initState();
    _selectedLessonId = widget.lessonId ?? '2';
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkBackend();
    await _loadLessons();
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

  Future<void> _loadLessons() async {
    if (mounted) {
      setState(() => _loadingLessons = true);
    }

    final lessons = await ApiService.getLessons();

    if (!mounted) return;

    final normalizedLessons = lessons.map((lesson) {
      final item = Map<String, dynamic>.from(lesson);
      item['id'] = item['id'].toString();

      // Temporary presentation mapping:
      // backend lesson 2 points to maths/test_math_sample.json,
      // whose actual content is Quadratic Equations.
      if (item['id'] == '2') {
        item['title'] = 'Quadratic Equations';
        item['subject'] = 'Mathematics';
        item['icon'] = '📐';
      }

      return item;
    }).toList();

    setState(() {
      _lessons = normalizedLessons;
      _loadingLessons = false;

      if (_lessons.isNotEmpty) {
        final ids = _lessons.map((lesson) => lesson['id'].toString()).toSet();

        if (!ids.contains(_selectedLessonId)) {
          _selectedLessonId = ids.contains('2')
              ? '2'
              : _lessons.first['id'].toString();
        }
      }
    });
  }

  Future<void> _refresh() async {
    await _checkBackend();
    await _loadLessons();
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
        _summary =
            result ??
            'Could not generate summary. Confirm the backend (port 8000) '
                'and AI engine (port 8001) are both running.';
        _loadingSummary = false;
        _responseTime = stopwatch.elapsedMilliseconds / 1000;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
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
            if (_loadingLessons)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              )
            else if (_lessons.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  'No lessons received from the backend. '
                  'Start the backend and seed the demo database, then refresh.',
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedLessonId,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _lessons
                    .map(
                      (lesson) => DropdownMenuItem<String>(
                        value: lesson['id'].toString(),
                        child: Text(
                          '${lesson['icon'] ?? '📘'} ${lesson['title'] ?? 'Lesson'}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
              childAspectRatio: 2.2,
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
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('Ask AI'),
                      onPressed: () => context.push('/chat/$_selectedLessonId'),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              loading && label == 'Summarize'
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
